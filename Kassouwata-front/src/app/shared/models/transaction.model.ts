import { User } from "./user.model";

export interface Transaction{
    idTransaction: number;
    typeTransaction?: string; 
    dateTransaction: Date;
    createdAt?: Date;
    montant : number;
    client : User;
}