package com.techinnov.kassouwata_back.controllers.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Corps de /b2c_standard pour un paiement par CARTE BANCAIRE (Visa, MasterCard).
 * cvv_number contient le CVV chiffré renvoyé par /crypt-cvv.
 * Les champs javaEnabled... challengeWindowSize servent à l'authentification 3DS.
 */
public record B2cCartePayload(
        @JsonProperty("mobile_money") String mobileMoney,
        @JsonProperty("api_key") String apiKey,
        @JsonProperty("nom_prenom_payeur") String nomPrenomPayeur,
        @JsonProperty("numero_carte_bancaire") String numeroCarteBancaire,
        @JsonProperty("date_expiration") String dateExpiration,
        @JsonProperty("cvv_number") String cvvNumber,
        @JsonProperty("montant_a_payer") String montantAPayer,
        @JsonProperty("reference_externe") String referenceExterne,
        @JsonProperty("javaEnabled") boolean javaEnabled,
        @JsonProperty("javascriptEnabled") boolean javascriptEnabled,
        @JsonProperty("screenHeight") String screenHeight,
        @JsonProperty("screenWidth") String screenWidth,
        @JsonProperty("TZ") String tz,
        @JsonProperty("challengeWindowSize") String challengeWindowSize
) {
    @Override
    public String toString() {
        return "B2cCartePayload[reference=" + referenceExterne + ", montant=" + montantAPayer + "]";
    }
}
