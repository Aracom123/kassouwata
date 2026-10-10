import { User } from "./user.model";

export interface TontineVersement{
    idVersement: number;
    typeVersement?: string; 
    dateVersement: Date;
    createdAt?: Date;
    montant : number;
    telephone : string;
    membre: User;
}