import { User } from "./user.model";

export interface Tontine{
    idTontine: number;
    libelle: string;
    description?: string;
    montant: number;
    dateDebut: Date;
    dateFin: Date;
    periodicite: string;
    createdAt?: Date;
    tontineOwner : User;
    /** CLASSIQUE (null = ancienne tontine) ou PRODUIT (achat groupé) */
    typeAdashe?: 'CLASSIQUE' | 'PRODUIT' | null;
    /** EN_ATTENTE_VENDEUR, ACTIF, REFUSE, OBJECTIF_ATTEINT (null = ACTIF) */
    statutAdashe?: string | null;
    produit?: any;
    nombreMembres?: number;
    nombrePeriodes?: number;
    montantCible?: number;
    ouverte?: boolean;
    motifRefus?: string;
}