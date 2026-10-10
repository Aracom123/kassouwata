package com.techinnov.kassouwata_back.controllers.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Corps de /b2c_standard pour une SOCIÉTÉ DE TRANSFERT D'ARGENT (MyNita, Amana...).
 */
public record B2cTransfertPayload(
        @JsonProperty("mobile_money") String mobileMoney,
        @JsonProperty("api_key") String apiKey,
        @JsonProperty("montant_a_payer") String montantAPayer,
        @JsonProperty("numero_telephone_payeur") String numeroTelephonePayeur,
        @JsonProperty("pays_payeur") String paysPayeur,
        @JsonProperty("reference_externe") String referenceExterne
) {}
