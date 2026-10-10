package com.techinnov.kassouwata_back.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

/**
 * Fournisseurs de paiement.
 *
 * - codeAgregateur : valeur du champ "mobile_money" envoyée à l'agrégateur.
 *   null = fournisseur pas encore ouvert chez l'agrégateur.
 * - categorie : détermine le corps de requête de /b2c_standard.
 *
 * Les noms des constantes ne doivent pas changer : ils sont stockés en base
 * (TontineVersement.fournisseur, Transaction.moyenPaiement).
 */
public enum FournisseurPaiement {

    NITA("nita_transfert", Categorie.SOCIETE_TRANSFERT),
    AMANA("amana_transfert", Categorie.SOCIETE_TRANSFERT),
    AIRTEL_MONEY("airtel_money", Categorie.OPERATEUR_TELECOM),
    MOOV_MONEY(null, Categorie.OPERATEUR_TELECOM),   // code à renseigner à l'ouverture
    VISA(null, Categorie.CARTE),
    MASTERCARD(null, Categorie.CARTE);

    public enum Categorie {
        /** Corps avec "nom_prenom_payeur", numéro local (96XXXXXX). */
        OPERATEUR_TELECOM,
        /** Corps avec "pays_payeur", numéro international (+227XXXXXXXX). */
        SOCIETE_TRANSFERT,
        CARTE
    }

    private final String codeAgregateur;
    private final Categorie categorie;

    FournisseurPaiement(String codeAgregateur, Categorie categorie) {
        this.codeAgregateur = codeAgregateur;
        this.categorie = categorie;
    }

    public String getCodeAgregateur() {
        return codeAgregateur;
    }

    public Categorie getCategorie() {
        return categorie;
    }

    /** Fournisseur Mobile Money utilisable chez l'agrégateur. */
    public boolean isMobileMoneyActif() {
        return codeAgregateur != null && categorie != Categorie.CARTE;
    }

    /**
     * Accepte le nom ("AIRTEL_MONEY") ou le code agrégateur ("airtel_money").
     * La sérialisation JSON reste le nom de la constante.
     */
    @JsonCreator
    public static FournisseurPaiement from(String value) {
        if (value == null) return null;
        String v = value.trim();
        for (FournisseurPaiement f : values()) {
            if (f.name().equalsIgnoreCase(v) || v.equalsIgnoreCase(f.codeAgregateur)) return f;
        }
        throw new IllegalArgumentException("Fournisseur de paiement inconnu : " + value);
    }
}
