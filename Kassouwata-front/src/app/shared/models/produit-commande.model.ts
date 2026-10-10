import { Commande } from "./commande.model";
import { Produit } from "./produit.model";

export interface ProduitCommande{
    idProduitCommande: number;
    quantite: number ;
    produit : Produit;
    commande: Commande;
    createdAt?: Date;
}