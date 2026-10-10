import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import {
  FiltresPaiement,
  FOURNISSEURS_PAIEMENT,
  PaiementService,
  STATUTS_PAIEMENT,
  TransactionPaiement,
  classeStatutPaiement,
  libelleFournisseur,
  libelleStatutPaiement,
} from '../../shared/services/paiement.service';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-paiements',
  imports: [CommonModule, RouterLink, AlertComponent, ModalComponent],
  templateUrl: './paiement.component.html',
  styleUrl: './paiement.component.css',
})
export class PaiementComponent implements OnInit, OnDestroy {
  // ─── Pagination (côté serveur) ────────────────────────────────
  page = 0;
  size = 20;
  totalPages = 0;
  totalElements = 0;

  // ─── Données ──────────────────────────────────────────────────
  transactions: TransactionPaiement[] = [];
  stats: any = null;
  isLoading = false;
  isLoadingStats = false;

  // ─── Filtres ──────────────────────────────────────────────────
  filtres: FiltresPaiement = {};
  private searchSubject = new Subject<string>();
  private destroy$ = new Subject<void>();

  readonly statuts = STATUTS_PAIEMENT;
  readonly fournisseurs = FOURNISSEURS_PAIEMENT;
  readonly typesOperation = [
    { value: 'COMMANDE', label: 'Commande' },
    { value: 'TONTINE', label: 'Tontine' },
  ];

  // ─── Vérification de statut ──────────────────────────────────
  /** Références en cours de vérification (désactive le bouton). */
  enVerification = new Set<string>();

  // ─── Modal détail ─────────────────────────────────────────────
  isDetailOpen = false;
  detail: TransactionPaiement | null = null;
  isLoadingDetail = false;

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  constructor(
    private paiementService: PaiementService,
    private route: ActivatedRoute,
    private router: Router,
  ) {}

  ngOnInit(): void {
    // Filtres passés dans l'URL : /paiements?commandeId=12 ou ?tontineId=3 ou ?statut=EN_ATTENTE
    this.route.queryParamMap.pipe(takeUntil(this.destroy$)).subscribe(params => {
      const commandeId = params.get('commandeId');
      const tontineId = params.get('tontineId');
      const statut = params.get('statut');
      this.filtres = {
        ...this.filtres,
        commandeId: commandeId ? Number(commandeId) : null,
        tontineId: tontineId ? Number(tontineId) : null,
        statut: statut ?? this.filtres.statut,
      };
      this.page = 0;
      this.loadTransactions();
    });

    this.searchSubject.pipe(debounceTime(400), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe(() => {
        this.page = 0;
        this.loadTransactions();
      });

    this.loadStats();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ─── Chargement ───────────────────────────────────────────────
  loadTransactions(): void {
    this.isLoading = true;
    this.paiementService.getTransactions(this.page, this.size, this.filtres).subscribe({
      next: data => {
        this.transactions = data?.content ?? [];
        this.totalElements = data?.totalElements ?? 0;
        this.totalPages = data?.totalPages || 1;
        this.isLoading = false;
      },
      error: err => {
        this.isLoading = false;
        this.transactions = [];
        this.notify(err?.status === 403
          ? 'Accès réservé aux administrateurs'
          : 'Erreur lors du chargement des paiements', 'error');
      },
    });
  }

  loadStats(): void {
    this.isLoadingStats = true;
    this.paiementService.getStatistiques().subscribe({
      next: data => {
        this.stats = data;
        this.isLoadingStats = false;
      },
      error: () => (this.isLoadingStats = false),
    });
  }

  rafraichir(): void {
    this.loadTransactions();
    this.loadStats();
  }

  // ─── Filtres ──────────────────────────────────────────────────
  onSearch(term: string): void {
    this.filtres.recherche = term;
    this.searchSubject.next(term);
  }

  setFiltre(cle: keyof FiltresPaiement, valeur: string): void {
    (this.filtres as any)[cle] = valeur || undefined;
    this.page = 0;
    this.loadTransactions();
  }

  /** Clic sur un indicateur : filtre par statut (re-cliquer retire le filtre). */
  toggleStatut(statut: string): void {
    this.setFiltre('statut', this.filtres.statut === statut ? '' : statut);
  }

  /** Retire le filtre commande/tontine venant de l'URL. */
  retirerFiltreObjet(): void {
    this.router.navigate([], { queryParams: {} });
  }

  clearFilters(): void {
    this.filtres = {};
    this.page = 0;
    if (this.route.snapshot.queryParamMap.keys.length) {
      this.retirerFiltreObjet();
    } else {
      this.loadTransactions();
    }
  }

  get hasActiveFilters(): boolean {
    return Object.values(this.filtres).some(v => v !== undefined && v !== null && v !== '');
  }

  // ─── Pagination ───────────────────────────────────────────────
  goToPage(p: number): void {
    if (p < 0 || p >= this.totalPages) return;
    this.page = p;
    this.loadTransactions();
  }

  get pages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }

  // ─── Actions ──────────────────────────────────────────────────
  verifier(t: TransactionPaiement): void {
    if (!t.referenceExterne || this.enVerification.has(t.referenceExterne)) return;
    const ref = t.referenceExterne;
    this.enVerification.add(ref);
    this.paiementService.verifierStatut(ref).subscribe({
      next: res => {
        this.enVerification.delete(ref);
        const statut = res?.statut;
        if (statut === 'REUSSIE') this.notify(`Paiement ${ref} confirmé`, 'success');
        else if (statut === 'ECHOUEE') this.notify(`Paiement ${ref} en échec`, 'warning');
        else this.notify(`Paiement ${ref} toujours en attente de validation`, 'info');
        this.rafraichir();
        if (this.detail?.referenceExterne === ref) this.ouvrirDetail(t);
      },
      error: err => {
        this.enVerification.delete(ref);
        this.notify(err?.error?.error || 'Vérification impossible pour le moment', 'error');
      },
    });
  }

  ouvrirDetail(t: TransactionPaiement): void {
    this.isDetailOpen = true;
    this.isLoadingDetail = true;
    this.detail = t;
    this.paiementService.getTransaction(t.idTransaction).subscribe({
      next: d => {
        this.detail = d;
        this.isLoadingDetail = false;
      },
      error: () => {
        this.isLoadingDetail = false;
        this.notify('Erreur lors du chargement du détail', 'error');
      },
    });
  }

  fermerDetail(): void {
    this.isDetailOpen = false;
    this.detail = null;
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  encode(id: any): string {
    return btoa(String(id));
  }

  libelleStatut = libelleStatutPaiement;
  libelleFournisseur = libelleFournisseur;
  classeStatut = classeStatutPaiement;

  stat(statut: string, champ: 'nombre' | 'montant'): number {
    return this.stats?.parStatut?.[statut]?.[champ] ?? 0;
  }

  /** Part d'un fournisseur dans les encaissements (barre de progression). */
  part(montant: number): number {
    const total = this.stats?.montantEncaisse || 0;
    return total > 0 ? Math.round((montant / total) * 100) : 0;
  }

  /** Affiche un JSON stocké en texte de façon lisible. */
  formatJson(texte?: string | null): string {
    if (!texte) return '—';
    try {
      return JSON.stringify(JSON.parse(texte), null, 2);
    } catch {
      return texte;
    }
  }

  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
