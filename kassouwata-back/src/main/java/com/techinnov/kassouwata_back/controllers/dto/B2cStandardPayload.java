package com.techinnov.kassouwata_back.controllers.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Corps de /b2c_standard pour un OPÉRATEUR TÉLÉCOM (Airtel Money...).
 */
public record B2cStandardPayload(
        @JsonProperty("mobile_money") String mobileMoney,
        @JsonProperty("api_key") String apiKey,
        @JsonProperty("montant_a_payer") String montantAPayer,
        @JsonProperty("numero_telephone_payeur") String numeroTelephonePayeur,
        @JsonProperty("nom_prenom_payeur") String nomPrenomPayeur,
        @JsonProperty("reference_externe") String referenceExterne
) {}
