import { Boutique } from "./boutique.model";
import { Categorie } from "./categorie.model";
import { User } from "./user.model";

export interface Produit {
  idProduit: number;
  libelle: string;
  description?: string;
  prixUnitaire: number;
  quantite: number;
  imagePrincipale: string;
  photos?: string;
  status : boolean;
  /**
   * Nombre de tranches pour le paiement prépayé.
   * Null ou absent = paiement en tranches non disponible pour ce produit.
   */
  nombreTranches?: number;
  createdAt?: string;
  boutique: Boutique;
  categorie: Categorie;
}
