import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

/** EN_ATTENTE | REUSSIE | ECHOUEE, ou MANUELLE pour les anciennes transactions sans statut. */
export type StatutPaiement = 'EN_ATTENTE' | 'REUSSIE' | 'ECHOUEE' | 'MANUELLE';

export interface TransactionPaiement {
  idTransaction: number;
  referenceExterne?: string;
  dateTransaction: string;
  montant: number;
  statut: StatutPaiement;
  typeOperation?: 'COMMANDE' | 'TONTINE' | null;
  commandeId?: number | null;
  tontineId?: number | null;
  periodeVersementId?: number | null;
  modePaiement?: string;
  fournisseur?: string;
  telephonePayeur?: string;
  nomPayeur?: string;
  numeroCarteMasque?: string;
  dateVerification?: string;
  payeurTelephone?: string;
  payeurNom?: string;
  // Détail uniquement
  reponseAgregateur?: string;
  reponseVerification?: string;
  creePar?: string;
}

export interface FiltresPaiement {
  statut?: string;
  fournisseur?: string;
  typeOperation?: string;
  recherche?: string;
  commandeId?: number | null;
  tontineId?: number | null;
  dateDebut?: string;
  dateFin?: string;
}

export interface PagePaiements {
  content: TransactionPaiement[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export interface ResumePaiementCommande {
  idCommande: number;
  typeVente?: string;
  montantTotal: number;
  montantPaye: number;
  resteAPayer: number;
  statutPaiement: 'NON_PAYEE' | 'PARTIELLEMENT_PAYEE' | 'PAYEE';
  nombreTranches?: number;
  montantTranche?: number;
}

/** Moyen de paiement (table moyen_paiement). */
export interface MoyenPaiement {
  idMoyenPaiement: number;
  code: string;
  libelle: string;
  codeAgregateur?: string | null;
  logo?: string | null;
  /** À préfixer par l'URL de l'API : environment.backendBaseUrl + logoPath */
  logoPath?: string | null;
  ordre: number;
  actif: boolean;
  categorieCode: string;
}

export interface CategoriePaiement {
  idCategoriePaiement: number;
  code: string;
  libelle: string;
  description?: string;
  ordre: number;
  actif: boolean;
  moyens: MoyenPaiement[];
}

@Injectable({
  providedIn: 'root',
})
export class PaiementService {
  private readonly API_URL = environment.backendBaseUrl + '/payment';

  constructor(private http: HttpClient) {}

  /** Liste paginée des transactions (back-office, profil ADMIN). */
  getTransactions(page: number, size: number, filtres: FiltresPaiement = {}): Observable<PagePaiements> {
    let params = new HttpParams().set('page', page).set('size', size);
    Object.entries(filtres).forEach(([cle, valeur]) => {
      if (valeur !== undefined && valeur !== null && valeur !== '') {
        params = params.set(cle, String(valeur));
      }
    });
    return this.http.get<PagePaiements>(this.API_URL + '/admin/transactions', { params });
  }

  /** Détail d'une transaction avec les réponses brutes de l'agrégateur. */
  getTransaction(id: number): Observable<TransactionPaiement> {
    return this.http.get<TransactionPaiement>(this.API_URL + '/admin/transactions/' + id);
  }

  /** Indicateurs : montants par statut, par fournisseur, par type, taux de réussite. */
  getStatistiques(): Observable<any> {
    return this.http.get<any>(this.API_URL + '/admin/statistiques');
  }

  /** Interroge l'agrégateur et met à jour le statut d'une transaction EN_ATTENTE. */
  verifierStatut(referenceExterne: string): Observable<any> {
    return this.http.get<any>(this.API_URL + '/statut/' + encodeURIComponent(referenceExterne));
  }

  // ─── Référentiel des moyens de paiement ─────────────────────────

  /** Catégories et moyens, y compris inactifs (back-office). */
  getReferentiel(): Observable<CategoriePaiement[]> {
    return this.http.get<CategoriePaiement[]>(this.API_URL + '/admin/moyens');
  }

  creerMoyen(champs: Partial<MoyenPaiement>): Observable<MoyenPaiement> {
    return this.http.post<MoyenPaiement>(this.API_URL + '/admin/moyens', champs);
  }

  modifierMoyen(id: number, champs: Partial<MoyenPaiement>): Observable<MoyenPaiement> {
    return this.http.put<MoyenPaiement>(this.API_URL + '/admin/moyens/' + id, champs);
  }

  changerLogo(id: number, fichier: File): Observable<MoyenPaiement> {
    const form = new FormData();
    form.append('file', fichier);
    return this.http.post<MoyenPaiement>(this.API_URL + '/admin/moyens/' + id + '/logo', form);
  }

  modifierCategorie(id: number, champs: Partial<CategoriePaiement>): Observable<CategoriePaiement> {
    return this.http.put<CategoriePaiement>(this.API_URL + '/admin/categories/' + id, champs);
  }

  /** URL complète d'un logo. */
  urlLogo(logoPath?: string | null): string | null {
    return logoPath ? environment.backendBaseUrl + logoPath : null;
  }

  /** Total, payé, reste à payer et statut de paiement d'une commande. */
  getResumeCommande(idCommande: number): Observable<ResumePaiementCommande> {
    return this.http.get<ResumePaiementCommande>(this.API_URL + '/commande/' + idCommande + '/resume');
  }
}

// ─── Libellés et couleurs partagés par les écrans ────────────────────────────

export const STATUTS_PAIEMENT: { value: StatutPaiement; label: string }[] = [
  { value: 'REUSSIE', label: 'Réussie' },
  { value: 'EN_ATTENTE', label: 'En attente' },
  { value: 'ECHOUEE', label: 'Échouée' },
  { value: 'MANUELLE', label: 'Manuelle' },
];

export const FOURNISSEURS_PAIEMENT: { value: string; label: string }[] = [
  { value: 'AIRTEL_MONEY', label: 'Airtel Money' },
  { value: 'NITA', label: 'MyNita' },
  { value: 'AMANA', label: 'Amana' },
  { value: 'MOOV_MONEY', label: 'Moov Money' },
  { value: 'ZAMANI_CASH', label: 'Zamani Cash' },
  { value: 'VISA', label: 'Visa' },
  { value: 'MASTERCARD', label: 'Mastercard' },
];

export function libelleStatutPaiement(statut?: string | null): string {
  return STATUTS_PAIEMENT.find(s => s.value === statut)?.label ?? (statut || '—');
}

export function libelleFournisseur(code?: string | null): string {
  if (!code) return '—';
  return FOURNISSEURS_PAIEMENT.find(f => f.value === code)?.label ?? code;
}

/** Classes Tailwind du badge de statut (mêmes couleurs que le reste du back-office). */
export function classeStatutPaiement(statut?: string | null): string {
  switch (statut) {
    case 'REUSSIE':
      return 'bg-success-50 text-success-700 dark:bg-success-500/15 dark:text-success-500';
    case 'EN_ATTENTE':
      return 'bg-warning-50 text-warning-700 dark:bg-warning-500/15 dark:text-orange-400';
    case 'ECHOUEE':
      return 'bg-error-50 text-error-700 dark:bg-error-500/15 dark:text-error-500';
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-white/5 dark:text-white/80';
  }
}
