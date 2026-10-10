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
}