import { User } from "./user.model";

export interface Commande{
    idCommande: number;
    /**
     * Type de vente : 'PREPAYE' ou 'POSTPAYE'.
     * - PREPAYE  : une seule ligne produit par commande, paiement en tranches
     *              (nombre de tranches défini par Produit.nombreTranches).
     * - POSTPAYE : plusieurs produits autorisés par commande, paiement en une fois.
     */
    typeVente: 'PREPAYE' | 'POSTPAYE';
    moyenPaiement: string;
    montantTotal: number;
    adresseLivraison: string;
    dateCommande: Date;
    createdAt?: Date;
    client : User;
    created_at: Date
}