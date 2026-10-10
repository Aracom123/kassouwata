package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.entitites.Commande;
import com.techinnov.kassouwata_back.entitites.ProduitCommande;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.entitites.TontineVersement;
import com.techinnov.kassouwata_back.entitites.Transaction;
import com.techinnov.kassouwata_back.enums.FournisseurPaiement;
import com.techinnov.kassouwata_back.enums.StatutTransaction;
import com.techinnov.kassouwata_back.enums.TypeOperationPaiement;
import com.techinnov.kassouwata_back.enums.TypePaiement;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;
import com.techinnov.kassouwata_back.repositories.TransactionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.HashSet;
import java.util.Set;

/**
 * Applique le résultat d'une vérification de paiement, dans une seule transaction base de données :
 *  - changement de statut de la transaction (EN_ATTENTE -> REUSSIE / ECHOUEE) ;
 *  - si REUSSIE et TONTINE  : création du TontineVersement du membre pour la période ;
 *  - si REUSSIE et COMMANDE : SMS au(x) vendeur(s). Le montant payé de la commande est
 *    calculé à partir des transactions, il n'y a rien d'autre à mettre à jour.
 *
 * Le changement de statut est atomique (UPDATE ... WHERE statut = 'EN_ATTENTE') :
 * si deux vérifications arrivent en même temps, une seule applique le paiement.
 */
@Service
public class PaiementFinalisationService {

    private static final Logger log = LoggerFactory.getLogger(PaiementFinalisationService.class);

    private final TransactionRepository transactionRepository;
    private final TontineVersementRepository tontineVersementRepository;
    private final SmsService smsService;

    public PaiementFinalisationService(TransactionRepository transactionRepository,
                                       TontineVersementRepository tontineVersementRepository,
                                       SmsService smsService) {
        this.transactionRepository = transactionRepository;
        this.tontineVersementRepository = tontineVersementRepository;
        this.smsService = smsService;
    }

    /**
     * @param nouveauStatut REUSSIE, ECHOUEE, ou null si l'agrégateur n'a pas encore de résultat
     * @return la transaction à jour
     */
    @Transactional
    public Transaction appliquerResultat(Long idTransaction, StatutTransaction nouveauStatut, String reponseJson) {
        boolean statutChange = nouveauStatut != null
                && transactionRepository.changerStatutSiEnAttente(idTransaction, nouveauStatut.name()) == 1;

        Transaction transaction = transactionRepository.findById(idTransaction).orElseThrow();
        transaction.setReponseVerification(reponseJson);
        transaction.setDateVerification(new Date());
        transaction = transactionRepository.save(transaction);

        if (statutChange) {
            log.info("Transaction {} : {}", transaction.getReferenceExterne(), nouveauStatut);
            if (nouveauStatut == StatutTransaction.REUSSIE) {
                appliquerPaiementReussi(transaction);
            }
        }
        return transaction;
    }

    private void appliquerPaiementReussi(Transaction transaction) {
        String type = transaction.getTypeOperation();
        if (TypeOperationPaiement.TONTINE.name().equals(type)) {
            creerVersementTontine(transaction);
        } else if (TypeOperationPaiement.COMMANDE.name().equals(type)) {
            notifierVendeurs(transaction);
        }
    }

    /** Crée la cotisation du membre pour la période payée. */
    private void creerVersementTontine(Transaction transaction) {
        if (transaction.getUtilisateur() == null || transaction.getTontinePeriodeVersement() == null) {
            log.warn("Transaction {} : membre ou période manquant, versement de tontine non créé",
                    transaction.getReferenceExterne());
            return;
        }
        if (tontineVersementRepository.existsByMembre_IdUserAndTontinePeriodeVersement_IdTontinePeriodeVersement(
                transaction.getUtilisateur().getIdUser(),
                transaction.getTontinePeriodeVersement().getIdTontinePeriodeVersement())) {
            log.warn("Transaction {} : le membre a déjà un versement pour cette période, pas de doublon créé",
                    transaction.getReferenceExterne());
            return;
        }

        TontineVersement versement = new TontineVersement();
        versement.setDateVersement(new Date());
        versement.setMontant(transaction.getMontant());
        versement.setTelephone(transaction.getUtilisateur().getTelephone());
        boolean carte = "CARTE".equals(transaction.getModePaiement());
        versement.setTypePaiement(carte ? TypePaiement.CARTE_PAIEMENT : TypePaiement.MOBILE_MONEY);
        versement.setFournisseur(fournisseurConnu(transaction.getMoyenPaiement()));
        if (carte) {
            versement.setNumeroCarte(transaction.getNumeroCarteMasque());   // jamais le numéro complet
            versement.setNomPorteur(transaction.getNomPayeur());
        } else {
            versement.setNumeroCompte(transaction.getTelephonePayeur());
        }
        versement.setMembre(transaction.getUtilisateur());
        versement.setTontinePeriodeVersement(transaction.getTontinePeriodeVersement());
        tontineVersementRepository.save(versement);

        log.info("Versement de tontine créé pour la transaction {}", transaction.getReferenceExterne());
    }

    /**
     * TontineVersement.fournisseur est un enum avec une contrainte en base :
     * un moyen de paiement ajouté depuis le back-office (ex. ZAMANI_CASH) n'y figure pas forcément.
     */
    private static FournisseurPaiement fournisseurConnu(String code) {
        try {
            return code != null ? FournisseurPaiement.valueOf(code) : null;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /** SMS à chaque vendeur concerné (même logique que CommandeController.notifierVendeurs). */
    private void notifierVendeurs(Transaction transaction) {
        try {
            Commande commande = transaction.getCommande();
            if (commande == null || commande.getLignes() == null) return;

            Set<String> telephones = new HashSet<>();
            for (ProduitCommande ligne : commande.getLignes()) {
                if (ligne.getProduit() == null) continue;
                Boutique boutique = ligne.getProduit().getBoutique();
                if (boutique == null || boutique.getVendeur() == null) continue;
                String telephone = boutique.getVendeur().getTelephone();
                if (telephone == null || telephone.isBlank() || !telephones.add(telephone)) continue;

                Sms sms = new Sms();
                sms.setReceiver(telephone);
                sms.setMessage("Paiement de " + Math.round(transaction.getMontant()) + " FCFA recu pour la commande #"
                        + commande.getIdCommande() + ". Connectez-vous a Kassouwata pour la traiter.");
                smsService.send(sms);
            }
        } catch (Exception e) {
            // Un échec d'envoi de SMS ne doit pas annuler l'enregistrement du paiement
            log.warn("Notification SMS vendeur impossible pour {} : {}",
                    transaction.getReferenceExterne(), e.getMessage());
        }
    }
}
