package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.controllers.dto.MobileMoneyPaymentRequest;
import com.techinnov.kassouwata_back.entitites.CategoriePaiement;
import com.techinnov.kassouwata_back.entitites.Commande;
import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;
import com.techinnov.kassouwata_back.entitites.MoyenPaiement;
import com.techinnov.kassouwata_back.entitites.ProduitCommande;
import com.techinnov.kassouwata_back.entitites.Tontine;
import com.techinnov.kassouwata_back.entitites.TontinePeriodeVersement;
import com.techinnov.kassouwata_back.entitites.Transaction;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.DemandeAdhesionStatus;
import com.techinnov.kassouwata_back.enums.StatutTransaction;
import com.techinnov.kassouwata_back.enums.TypeOperationPaiement;
import com.techinnov.kassouwata_back.repositories.CommandeRepository;
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.MoyenPaiementRepository;
import com.techinnov.kassouwata_back.repositories.TontinePeriodeVersementRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;
import com.techinnov.kassouwata_back.repositories.TransactionRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Effectue une transaction Mobile Money et l'enregistre dans la table "transaction".
 *
 * Déroulement :
 *  1. vérifications : demande, utilisateur connecté, objet payé (commande ou tontine),
 *     montant restant / période de cotisation, paiement déjà en cours ;
 *  2. enregistrement de la transaction avec le statut EN_ATTENTE ;
 *  3. envoi à l'agrégateur (/b2c_standard) ;
 *  4. mise à jour : réponse de l'agrégateur stockée, statut ECHOUEE en cas de refus.
 * Le résultat final (REUSSIE / ECHOUEE) est obtenu ensuite par /check-transaction-status,
 * à la demande ou automatiquement, et appliqué par PaiementFinalisationService.
 */
@Service
public class TransactionPaiementService {

    private static final Logger log = LoggerFactory.getLogger(TransactionPaiementService.class);

    /** Un paiement EN_ATTENTE plus récent que ce délai bloque un nouveau paiement du même objet. */
    private static final Duration PAIEMENT_EN_COURS = Duration.ofMinutes(10);

    private final PaymentService paymentService;
    private final PaiementFinalisationService finalisationService;
    private final TransactionRepository transactionRepository;
    private final CommandeRepository commandeRepository;
    private final TontineRepository tontineRepository;
    private final TontinePeriodeVersementRepository periodeRepository;
    private final TontineVersementRepository tontineVersementRepository;
    private final DemandeAdhesionRepository demandeAdhesionRepository;
    private final UserRepository userRepository;
    private final MoyenPaiementRepository moyenPaiementRepository;

    public TransactionPaiementService(PaymentService paymentService,
                                      PaiementFinalisationService finalisationService,
                                      TransactionRepository transactionRepository,
                                      CommandeRepository commandeRepository,
                                      TontineRepository tontineRepository,
                                      TontinePeriodeVersementRepository periodeRepository,
                                      TontineVersementRepository tontineVersementRepository,
                                      DemandeAdhesionRepository demandeAdhesionRepository,
                                      UserRepository userRepository,
                                      MoyenPaiementRepository moyenPaiementRepository) {
        this.paymentService = paymentService;
        this.finalisationService = finalisationService;
        this.transactionRepository = transactionRepository;
        this.commandeRepository = commandeRepository;
        this.tontineRepository = tontineRepository;
        this.periodeRepository = periodeRepository;
        this.tontineVersementRepository = tontineVersementRepository;
        this.demandeAdhesionRepository = demandeAdhesionRepository;
        this.userRepository = userRepository;
        this.moyenPaiementRepository = moyenPaiementRepository;
    }

    public Map<String, Object> effectuerTransaction(MobileMoneyPaymentRequest req) {
        // 1. Vérifications (aucune écriture en base si la demande est invalide)
        MoyenPaiement moyen = resoudreMoyenPaiement(req);
        String telephone = paymentService.validerEtNormaliser(req, moyen);
        boolean carte = CategoriePaiement.CARTE.equals(moyen.getCategorieCode());
        User utilisateur = utilisateurConnecte();
        Date ilYA10Min = Date.from(Instant.now().minus(PAIEMENT_EN_COURS));

        Transaction transaction = new Transaction();
        transaction.setUtilisateur(utilisateur);
        switch (req.typeOperation()) {
            case COMMANDE -> preparerPaiementCommande(req, utilisateur, ilYA10Min, transaction);
            case TONTINE -> preparerPaiementTontine(req, utilisateur, ilYA10Min, transaction);
        }

        // 2. Enregistrement EN_ATTENTE (jamais de numéro de carte complet ni de CVV)
        String reference = buildReference(req.typeOperation(), req.operationId());
        transaction.setReferenceExterne(reference);
        transaction.setTypeOperation(req.typeOperation().name());
        transaction.setDateTransaction(new Date());
        transaction.setModePaiement(moyen.getCategorieCode());   // MOBILE_MONEY | STA | CARTE
        transaction.setMoyenPaiement(moyen.getCode());           // AIRTEL_MONEY, NITA, VISA...
        transaction.setMontant(req.montant());
        transaction.setTelephonePayeur(telephone);
        transaction.setNomPayeur(req.nomPrenom() != null ? req.nomPrenom().trim() : null);
        if (carte) {
            transaction.setNumeroCarteMasque(MobileMoneyPaymentRequest.masquerCarte(req.numeroCarte()));
        }
        transaction.setStatut(StatutTransaction.EN_ATTENTE.name());
        transaction = transactionRepository.save(transaction);

        // 3. Envoi à l'agrégateur
        Map<String, Object> reponse;
        try {
            reponse = paymentService.envoyerB2c(req, moyen, telephone, reference);
        } catch (RuntimeException e) {
            transaction.setStatut(StatutTransaction.ECHOUEE.name());
            transaction.setReponseAgregateur(e.getMessage());
            transactionRepository.save(transaction);
            log.error("Transaction {} échouée : {}", reference, e.getMessage());
            throw e;
        }

        // 4. Mise à jour selon la réponse
        transaction.setReponseAgregateur(toJson(reponse));
        String lienAuthentification = null;
        boolean reussieImmediatement = false;

        if (reponse != null && Boolean.FALSE.equals(reponse.get("statut"))) {
            // Refus immédiat
            transaction.setStatut(StatutTransaction.ECHOUEE.name());
        } else if (carte && reponse != null) {
            // Carte : marque réelle renvoyée par KomiPay (VISA / MASTERCARD)
            if (reponse.get("dataTransaction") instanceof Map<?, ?> data && data.get("carte") != null) {
                transaction.setMoyenPaiement(data.get("carte").toString().toUpperCase());
            }
            String etat = reponse.get("etat") != null ? reponse.get("etat").toString().toUpperCase() : "";
            if ("SUCCESS".equals(etat)) {
                reussieImmediatement = true;            // pas de défi 3DS
            } else if (reponse.get("redirect_portail_auth") != null) {
                lienAuthentification = reponse.get("redirect_portail_auth").toString();   // défi 3DS
            }
        }
        // Mobile Money / STA : la transaction reste EN_ATTENTE (validation sur le téléphone du payeur)
        transaction = transactionRepository.save(transaction);

        if (reussieImmediatement) {
            // Même traitement qu'une confirmation par vérification de statut
            transaction = finalisationService.appliquerResultat(
                    transaction.getIdTransaction(), StatutTransaction.REUSSIE, toJson(reponse));
        }

        log.info("Transaction {} enregistrée (id {}), statut {}",
                reference, transaction.getIdTransaction(), transaction.getStatut());

        Map<String, Object> resultat = new LinkedHashMap<>();
        resultat.put("idTransaction", transaction.getIdTransaction());
        resultat.put("referenceExterne", reference);
        resultat.put("statut", transaction.getStatut());
        resultat.put("moyenPaiement", transaction.getMoyenPaiement());
        resultat.put("message", reponse != null ? reponse.get("message") : null);
        // Carte avec défi 3DS : l'application ouvre ce lien (WebView) puis vérifie le statut
        resultat.put("lienAuthentification", lienAuthentification);
        return resultat;
    }

    /**
     * Retrouve le moyen de paiement à partir du code envoyé par l'application.
     * Pour une carte, l'application peut envoyer "CARTE" : la marque est déduite du numéro.
     */
    private MoyenPaiement resoudreMoyenPaiement(MobileMoneyPaymentRequest req) {
        String code = req.moyenPaiement().trim().toUpperCase();
        if (CategoriePaiement.CARTE.equals(code) || "BANK_CARD".equals(code)) {
            String marque = PaymentService.detecterMarqueCarte(req.numeroCarte());
            if (marque == null) {
                throw new IllegalArgumentException("Seules les cartes Visa et MasterCard sont acceptées");
            }
            code = marque;
        }
        String codeFinal = code;
        MoyenPaiement moyen = moyenPaiementRepository.findByCode(codeFinal)
                .orElseThrow(() -> new IllegalArgumentException("Moyen de paiement inconnu : " + req.moyenPaiement()));
        // Carte : le numéro saisi doit correspondre à la marque choisie
        if (CategoriePaiement.CARTE.equals(moyen.getCategorieCode())) {
            String marque = PaymentService.detecterMarqueCarte(req.numeroCarte());
            if (marque != null && !marque.equals(moyen.getCode())) {
                moyen = moyenPaiementRepository.findByCode(marque).orElse(moyen);
            }
        }
        return moyen;
    }

    // ------------------------------------------------------------------
    // Règles de paiement d'une commande
    // ------------------------------------------------------------------

    private void preparerPaiementCommande(MobileMoneyPaymentRequest req, User utilisateur,
                                          Date ilYA10Min, Transaction transaction) {
        Commande commande = commandeRepository.findById(req.operationId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Commande introuvable : " + req.operationId()));

        if (commande.getClient() != null
                && !Objects.equals(commande.getClient().getIdUser(), utilisateur.getIdUser())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Cette commande n'appartient pas à l'utilisateur connecté");
        }
        if ("ANNULEE".equals(commande.getStatut())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cette commande est annulée");
        }
        if (transactionRepository.existsByCommande_IdCommandeAndStatutAndDateTransactionAfter(
                commande.getIdCommande(), StatutTransaction.EN_ATTENTE.name(), ilYA10Min)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Un paiement est déjà en cours pour cette commande. Validez-le sur votre téléphone ou réessayez dans quelques minutes.");
        }

        double reste = resteAPayer(commande);
        if (reste <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cette commande est déjà entièrement payée");
        }
        if (req.montant() > reste) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le montant (" + req.montant() + " FCFA) dépasse le reste à payer (" + Math.round(reste) + " FCFA)");
        }
        transaction.setCommande(commande);
    }

    private double resteAPayer(Commande commande) {
        double total = commande.getMontantTotal() != null ? commande.getMontantTotal() : 0;
        return total - transactionRepository.sumMontantPayeByCommande(commande.getIdCommande());
    }

    /**
     * Situation de paiement d'une commande : total, payé, reste,
     * statut (NON_PAYEE / PARTIELLEMENT_PAYEE / PAYEE) et tranche conseillée (PREPAYE).
     */
    public Map<String, Object> resumePaiementCommande(Long idCommande) {
        Commande commande = commandeRepository.findById(idCommande)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Commande introuvable : " + idCommande));

        double total = commande.getMontantTotal() != null ? commande.getMontantTotal() : 0;
        double paye = transactionRepository.sumMontantPayeByCommande(idCommande);
        double reste = Math.max(0, total - paye);
        String statutPaiement = paye <= 0 ? "NON_PAYEE" : (reste <= 0 ? "PAYEE" : "PARTIELLEMENT_PAYEE");

        Map<String, Object> resume = new LinkedHashMap<>();
        resume.put("idCommande", idCommande);
        resume.put("typeVente", commande.getTypeVente());
        resume.put("montantTotal", total);
        resume.put("montantPaye", paye);
        resume.put("resteAPayer", reste);
        resume.put("statutPaiement", statutPaiement);

        // PREPAYE : une seule ligne, nombre de tranches défini sur le produit
        if ("PREPAYE".equals(commande.getTypeVente()) && commande.getLignes() != null
                && !commande.getLignes().isEmpty()) {
            ProduitCommande ligne = commande.getLignes().get(0);
            Integer nbTranches = ligne.getProduit() != null ? ligne.getProduit().getNombreTranches() : null;
            if (nbTranches != null && nbTranches > 0) {
                resume.put("nombreTranches", nbTranches);
                resume.put("montantTranche", Math.min(reste, Math.ceil(total / nbTranches)));
            }
        }
        return resume;
    }

    // ------------------------------------------------------------------
    // Règles de cotisation à une tontine
    // ------------------------------------------------------------------

    private void preparerPaiementTontine(MobileMoneyPaymentRequest req, User utilisateur,
                                         Date ilYA10Min, Transaction transaction) {
        Tontine tontine = tontineRepository.findById(req.operationId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Adashé introuvable : " + req.operationId()));

        if (tontine.statutEffectif() != com.techinnov.kassouwata_back.enums.StatutAdashe.ACTIF) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    tontine.statutEffectif() == com.techinnov.kassouwata_back.enums.StatutAdashe.EN_ATTENTE_VENDEUR
                            ? "Cet Adashé attend la validation du vendeur : les cotisations commenceront ensuite."
                            : "Cet Adashé n'accepte plus de cotisations.");
        }
        if (!estMembre(tontine, utilisateur)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas membre de cet Adashé");
        }

        TontinePeriodeVersement periode = periodeAPayer(tontine, req.periodeVersementId());

        if (tontineVersementRepository.existsByMembre_IdUserAndTontinePeriodeVersement_IdTontinePeriodeVersement(
                utilisateur.getIdUser(), periode.getIdTontinePeriodeVersement())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Vous avez déjà cotisé pour la période « " + periode.getLibelle() + " »");
        }
        if (transactionRepository
                .existsByTontinePeriodeVersement_IdTontinePeriodeVersementAndUtilisateur_IdUserAndStatutAndDateTransactionAfter(
                        periode.getIdTontinePeriodeVersement(), utilisateur.getIdUser(),
                        StatutTransaction.EN_ATTENTE.name(), ilYA10Min)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Une cotisation est déjà en cours pour cette période. Validez-la sur votre téléphone ou réessayez dans quelques minutes.");
        }

        transaction.setTontine(tontine);
        transaction.setTontinePeriodeVersement(periode);
    }

    /** Membre = propriétaire de la tontine, ou demande d'adhésion ACCEPTEE avec son numéro. */
    private boolean estMembre(Tontine tontine, User utilisateur) {
        if (tontine.getTontineOwner() != null
                && Objects.equals(tontine.getTontineOwner().getIdUser(), utilisateur.getIdUser())) {
            return true;
        }
        for (DemandeAdhesion demande : demandeAdhesionRepository.findByTontineId(tontine.getIdTontine())) {
            if (demande.getStatut() == DemandeAdhesionStatus.ACCEPTEE
                    && ((demande.getMembre() != null
                            && Objects.equals(demande.getMembre().getIdUser(), utilisateur.getIdUser()))
                        || Objects.equals(demande.getTelephone(), utilisateur.getTelephone()))) {
                return true;
            }
        }
        return false;
    }

    /** Période demandée (doit appartenir à la tontine), sinon la période en cours. */
    private TontinePeriodeVersement periodeAPayer(Tontine tontine, Long periodeVersementId) {
        List<TontinePeriodeVersement> periodes = periodeRepository.findByTontineId(tontine.getIdTontine());

        if (periodeVersementId != null) {
            return periodes.stream()
                    .filter(p -> p.getIdTontinePeriodeVersement().equals(periodeVersementId))
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                            "La période " + periodeVersementId + " n'appartient pas à cet Adashé"));
        }

        Date maintenant = new Date();
        return periodes.stream()
                .filter(p -> p.getDateDebut() != null && p.getDateFin() != null
                        && !maintenant.before(p.getDateDebut()) && !maintenant.after(p.getDateFin()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Aucune période de cotisation en cours pour cet Adashé : précisez periodeVersementId"));
    }

    // ------------------------------------------------------------------
    // Utilisateur connecté
    // ------------------------------------------------------------------

    /** L'identifiant de connexion est le numéro de téléphone (cf. UserDetailService). */
    private User utilisateurConnecte() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth instanceof AnonymousAuthenticationToken || auth.getName() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non connecté");
        }
        return userRepository.findByTelephone(auth.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Utilisateur connecté introuvable"));
    }

    // ------------------------------------------------------------------
    // Vérification du statut
    // ------------------------------------------------------------------

    /**
     * Vérifie le statut d'une transaction auprès de l'agrégateur et met à jour la base.
     * Une transaction déjà REUSSIE ou ECHOUEE n'est pas revérifiée (statut définitif).
     */
    public Map<String, Object> verifierTransaction(String referenceExterne) {
        Transaction transaction = transactionRepository.findByReferenceExterne(referenceExterne)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Transaction introuvable : " + referenceExterne));

        if (StatutTransaction.EN_ATTENTE.name().equals(transaction.getStatut())) {
            transaction = mettreAJourStatut(transaction);
        }

        Map<String, Object> resultat = new LinkedHashMap<>();
        resultat.put("idTransaction", transaction.getIdTransaction());
        resultat.put("referenceExterne", transaction.getReferenceExterne());
        resultat.put("statut", transaction.getStatut());
        resultat.put("montant", transaction.getMontant());
        resultat.put("typeOperation", transaction.getTypeOperation());
        resultat.put("dateVerification", transaction.getDateVerification());
        return resultat;
    }

    /**
     * Vérification automatique toutes les minutes des transactions EN_ATTENTE
     * de moins de 24 h (et de plus de 30 s, pour laisser le temps au payeur de valider).
     * Les transactions plus anciennes restent EN_ATTENTE et peuvent être vérifiées à la demande.
     */
    @Scheduled(fixedDelayString = "${payment.verification.intervalle-ms:60000}",
               initialDelayString = "${payment.verification.delai-initial-ms:60000}")
    public void verifierTransactionsEnAttente() {
        Instant maintenant = Instant.now();
        List<Transaction> enAttente = transactionRepository.findByStatutAndDateTransactionBetween(
                StatutTransaction.EN_ATTENTE.name(),
                Date.from(maintenant.minus(Duration.ofHours(24))),
                Date.from(maintenant.minus(Duration.ofSeconds(30))));

        if (enAttente.isEmpty()) return;
        log.info("Vérification automatique de {} transaction(s) en attente", enAttente.size());

        for (Transaction transaction : enAttente) {
            try {
                mettreAJourStatut(transaction);
            } catch (Exception e) {
                // Une erreur sur une transaction ne bloque pas les suivantes
                log.warn("Vérification de {} impossible : {}", transaction.getReferenceExterne(), e.getMessage());
            }
        }
    }

    private Transaction mettreAJourStatut(Transaction transaction) {
        PaymentService.VerificationStatut verification =
                paymentService.verifierStatut(transaction.getReferenceExterne());
        return finalisationService.appliquerResultat(
                transaction.getIdTransaction(), verification.statut(), toJson(verification.reponse()));
    }

    /** CMD-125-1728230400 : type + id de l'objet payé + horodatage (unique à chaque tentative). */
    private static String buildReference(TypeOperationPaiement type, Long operationId) {
        return type.getPrefixe() + "-" + operationId + "-" + Instant.now().getEpochSecond();
    }

    // ------------------------------------------------------------------
    // Conversion simple Map -> JSON pour stocker la réponse de l'agrégateur
    // ------------------------------------------------------------------

    static String toJson(Object value) {
        StringBuilder sb = new StringBuilder();
        writeJson(value, sb);
        return sb.toString();
    }

    private static void writeJson(Object value, StringBuilder sb) {
        if (value == null) {
            sb.append("null");
        } else if (value instanceof Map<?, ?> map) {
            sb.append('{');
            boolean first = true;
            for (Map.Entry<?, ?> e : map.entrySet()) {
                if (!first) sb.append(',');
                first = false;
                writeString(String.valueOf(e.getKey()), sb);
                sb.append(':');
                writeJson(e.getValue(), sb);
            }
            sb.append('}');
        } else if (value instanceof List<?> list) {
            sb.append('[');
            for (int i = 0; i < list.size(); i++) {
                if (i > 0) sb.append(',');
                writeJson(list.get(i), sb);
            }
            sb.append(']');
        } else if (value instanceof Number || value instanceof Boolean) {
            sb.append(value);
        } else {
            writeString(value.toString(), sb);
        }
    }

    private static void writeString(String s, StringBuilder sb) {
        sb.append('"');
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
                }
            }
        }
        sb.append('"');
    }
}
