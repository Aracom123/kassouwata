package com.techinnov.kassouwata_back.enums;

/**
 * Valeurs du champ Transaction.statut (stocké en VARCHAR, comme modePaiement).
 *
 *   EN_ATTENTE : transaction enregistrée et envoyée à l'agrégateur,
 *                en attente de la validation par le payeur sur son téléphone.
 *   REUSSIE    : paiement confirmé.
 *   ECHOUEE    : paiement refusé ou erreur de l'agrégateur.
 */
public enum StatutTransaction {
    EN_ATTENTE,
    REUSSIE,
    ECHOUEE
}
