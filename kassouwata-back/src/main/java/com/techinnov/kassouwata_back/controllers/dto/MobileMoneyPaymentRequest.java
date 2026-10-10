package com.techinnov.kassouwata_back.controllers.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.techinnov.kassouwata_back.enums.TypeOperationPaiement;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * Demande de paiement envoyée par les applications (Mobile Money, STA ou carte).
 *
 * "moyenPaiement" = code d'un moyen de paiement (GET /api/payment/moyens) :
 *   AIRTEL_MONEY, NITA, AMANA, VISA, MASTERCARD... ou CARTE (le type de carte
 *   est alors déduit du numéro saisi).
 *
 * Mobile Money (opérateur) : numeroTelephone + nomPrenom
 * {
 *   "moyenPaiement": "AIRTEL_MONEY", "typeOperation": "COMMANDE", "operationId": 125,
 *   "montant": 5000, "numeroTelephone": "96000000", "nomPrenom": "Moussa Issa"
 * }
 *
 * Société de transfert (STA) : numeroTelephone + paysPayeur
 * {
 *   "moyenPaiement": "NITA", "typeOperation": "TONTINE", "operationId": 42,
 *   "montant": 5000, "numeroTelephone": "+22796000000", "paysPayeur": "Niger"
 * }
 *
 * Carte : nomPrenom + numeroCarte + dateExpiration (MM/AA) + cvv
 * {
 *   "moyenPaiement": "CARTE", "typeOperation": "COMMANDE", "operationId": 125, "montant": 25000,
 *   "nomPrenom": "Moussa Issa", "numeroCarte": "5555 5555 5555 4444",
 *   "dateExpiration": "12/27", "cvv": "123", "hauteurEcran": 960, "largeurEcran": 1536
 * }
 *
 * Les données de carte ne sont jamais enregistrées ni écrites dans les logs.
 */
public record MobileMoneyPaymentRequest(
        @NotBlank @JsonAlias("fournisseur") String moyenPaiement,
        @NotNull TypeOperationPaiement typeOperation,
        @NotNull @Positive Long operationId,
        @NotNull @Positive Long montant,
        String numeroTelephone,
        String nomPrenom,
        String paysPayeur,
        Long periodeVersementId,
        // Carte
        String numeroCarte,
        String dateExpiration,
        String cvv,
        Integer hauteurEcran,
        Integer largeurEcran
) {
    /** Ne jamais afficher le numéro de carte ni le CVV (logs, messages d'erreur). */
    @Override
    public String toString() {
        return "PaiementRequest[moyenPaiement=" + moyenPaiement + ", typeOperation=" + typeOperation
                + ", operationId=" + operationId + ", montant=" + montant
                + ", numeroTelephone=" + numeroTelephone
                + ", carte=" + (numeroCarte != null ? masquerCarte(numeroCarte) : null) + "]";
    }

    /** 5555555555554444 -> **** **** **** 4444 */
    public static String masquerCarte(String numero) {
        String chiffres = numero == null ? "" : numero.replaceAll("[^0-9]", "");
        if (chiffres.length() < 4) return "****";
        return "**** **** **** " + chiffres.substring(chiffres.length() - 4);
    }
}
