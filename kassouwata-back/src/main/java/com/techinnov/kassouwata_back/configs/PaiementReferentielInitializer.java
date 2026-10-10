package com.techinnov.kassouwata_back.configs;

import com.techinnov.kassouwata_back.entitites.CategoriePaiement;
import com.techinnov.kassouwata_back.entitites.MoyenPaiement;
import com.techinnov.kassouwata_back.repositories.CategoriePaiementRepository;
import com.techinnov.kassouwata_back.repositories.MoyenPaiementRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Crée au démarrage les catégories et moyens de paiement manquants.
 * Ne modifie jamais une ligne existante : les changements faits dans le
 * back-office (libellé, logo, activation, code KomiPay) sont conservés.
 */
@Component
public class PaiementReferentielInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(PaiementReferentielInitializer.class);

    private final CategoriePaiementRepository categorieRepository;
    private final MoyenPaiementRepository moyenRepository;

    public PaiementReferentielInitializer(CategoriePaiementRepository categorieRepository,
                                          MoyenPaiementRepository moyenRepository) {
        this.categorieRepository = categorieRepository;
        this.moyenRepository = moyenRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        CategoriePaiement mobile = categorie(CategoriePaiement.MOBILE_MONEY, "Mobile Money",
                "Paiement par opérateur télécom", 1);
        CategoriePaiement sta = categorie(CategoriePaiement.STA, "Société de transfert d'argent",
                "Paiement par MyNita, Amana...", 2);
        CategoriePaiement carte = categorie(CategoriePaiement.CARTE, "Carte de paiement",
                "Visa, MasterCard", 3);

        // code, libellé, code KomiPay ("mobile_money"), catégorie, ordre, actif
        moyen("AIRTEL_MONEY", "Airtel Money", "airtel_money", mobile, 1, true);
        moyen("MOOV_MONEY", "Moov Money", null, mobile, 2, false);     // code KomiPay à renseigner
        moyen("ZAMANI_CASH", "Zamani Cash", null, mobile, 3, false);   // code KomiPay à renseigner
        moyen("NITA", "MyNita", "nita_transfert", sta, 1, true);
        moyen("AMANA", "Amana", "amana_transfert", sta, 2, true);
        moyen("VISA", "Visa", "bank_card", carte, 1, true);
        moyen("MASTERCARD", "MasterCard", "bank_card", carte, 2, true);
    }

    private CategoriePaiement categorie(String code, String libelle, String description, int ordre) {
        return categorieRepository.findByCode(code).orElseGet(() -> {
            CategoriePaiement c = new CategoriePaiement();
            c.setCode(code);
            c.setLibelle(libelle);
            c.setDescription(description);
            c.setOrdre(ordre);
            c.setActif(true);
            log.info("Catégorie de paiement créée : {}", code);
            return categorieRepository.save(c);
        });
    }

    private void moyen(String code, String libelle, String codeAgregateur,
                       CategoriePaiement categorie, int ordre, boolean actif) {
        if (moyenRepository.findByCode(code).isPresent()) return;
        MoyenPaiement m = new MoyenPaiement();
        m.setCode(code);
        m.setLibelle(libelle);
        m.setCodeAgregateur(codeAgregateur);
        m.setCategorie(categorie);
        m.setOrdre(ordre);
        m.setActif(actif);
        moyenRepository.save(m);
        log.info("Moyen de paiement créé : {}", code);
    }
}
