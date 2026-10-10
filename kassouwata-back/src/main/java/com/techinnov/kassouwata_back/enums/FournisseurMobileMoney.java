package com.techinnov.kassouwata_back.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * Fournisseurs Mobile Money actifs chez l'agrégateur.
 * "code" est la valeur attendue dans le champ "mobile_money" de /b2c_standard.
 *
 * Zamani Cash et Moov Money ne sont pas encore actifs : les ajouter ici
 * (avec leur code) quand l'agrégateur les ouvrira.
 */
public enum FournisseurMobileMoney {

    AIRTEL_MONEY("airtel_money", Categorie.OPERATEUR_TELECOM),
    MY_NITA("nita_transfert", Categorie.SOCIETE_TRANSFERT),
    AMANA("amana_transfert", Categorie.SOCIETE_TRANSFERT);

    public enum Categorie {
        /** Corps de requête avec "nom_prenom_payeur", numéro local (96XXXXXX). */
        OPERATEUR_TELECOM,
        /** Corps de requête avec "pays_payeur", numéro international (+227XXXXXXXX). */
        SOCIETE_TRANSFERT
    }

    private final String code;
    private final Categorie categorie;

    FournisseurMobileMoney(String code, Categorie categorie) {
        this.code = code;
        this.categorie = categorie;
    }

    @JsonValue
    public String getCode() {
        return code;
    }

    public Categorie getCategorie() {
        return categorie;
    }

    /** Accepte le code ("airtel_money") ou le nom ("AIRTEL_MONEY") envoyé par les applications. */
    @JsonCreator
    public static FournisseurMobileMoney from(String value) {
        if (value == null) return null;
        String v = value.trim();
        for (FournisseurMobileMoney f : values()) {
            if (f.code.equalsIgnoreCase(v) || f.name().equalsIgnoreCase(v)) return f;
        }
        throw new IllegalArgumentException("Fournisseur Mobile Money inconnu : " + value
                + " (valeurs possibles : airtel_money, nita_transfert, amana_transfert)");
    }
}
