import { Personne } from "./personne.model";
import { Profile } from "./profile.model";

export interface User {
  idUser: number;
  telephone: string;
  password: string;
  profile: Profile;
  personne: Personne;
  status: 'ACTIVE' | 'SUSPENDED' | 'KYC_PENDING' | 'BLOCKED' | 'CLOSED';
  created_at?: string;
}
