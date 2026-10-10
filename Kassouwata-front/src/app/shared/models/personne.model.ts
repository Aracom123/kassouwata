export interface Personne {
  idPersonne: number;
  prenom: string;
  nom?: string;
  email?: string;
  dateNaissance?: string;
  lieuNaissance?: string;
  adresse?: string;
  photo?: string;
  genre?: string;
  createdAt?: string;
}
