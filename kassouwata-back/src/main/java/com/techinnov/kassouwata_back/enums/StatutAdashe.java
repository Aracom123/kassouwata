package com.techinnov.kassouwata_back.enums;

/**
 * Cycle de vie d'un Adashé Produit :
 * EN_ATTENTE_VENDEUR → ACTIF (le vendeur accepte, les périodes sont générées)
 *                    → REFUSE (le vendeur refuse) ;
 * ACTIF → OBJECTIF_ATTEINT (les cotisations couvrent le prix du produit).
 * Un Adashé classique est toujours ACTIF.
 */
public enum StatutAdashe {
    EN_ATTENTE_VENDEUR,
    ACTIF,
    REFUSE,
    OBJECTIF_ATTEINT
}
