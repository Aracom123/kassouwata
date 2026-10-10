import { User } from "./user.model";

export interface Boutique {
  idBoutique: number;
  libelle: string;
  adresse: string;
  description: string;
  createdAt?: string;
  commission?: number;

  status: 'ACTIVE' | 'SUSPENDED' | 'PENDING' | 'CLOSED';

  vendeur?: User;
}
