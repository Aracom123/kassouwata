package com.techinnov.kassouwata_back.enums;

/**
 * Objet payé. Le préfixe sert à construire la "reference_externe" :
 * PREFIXE-{id de l'objet}-{horodatage}, ex. CMD-125-1728230400.
 * Ajouter ici les nouveaux types d'opérations payantes.
 */
public enum TypeOperationPaiement {

    COMMANDE("CMD"),
    TONTINE("TON");

    private final String prefixe;

    TypeOperationPaiement(String prefixe) {
        this.prefixe = prefixe;
    }

    public String getPrefixe() {
        return prefixe;
    }
}
