package com.techinnov.kassouwata_back.enums;

/**
 * Valeurs documentaires pour le champ typeVente de l'entité Commande.
 *
 * Ces constantes sont utilisées comme valeurs String dans Commande.typeVente :
 *
 *   PREPAYE  : une seule ligne produit par commande ; paiement en plusieurs tranches
 *              (nombre de tranches défini par Produit.nombreTranches).
 *
 *   POSTPAYE : plusieurs produits autorisés par commande ; paiement en une seule fois.
 *
 * Note : ce enum n'est pas utilisé directement en JPA — la colonne est de type VARCHAR.
 */
public enum ModePaiement {
    PREPAYE,
    POSTPAYE
}
