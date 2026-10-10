import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import { CommandeService, StatutCommande } from '../../shared/services/commande.service';
import { BadgeComponent } from '../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../shared/components/ui/button/button.component';
import { InputFieldComponent } from '../../shared/components/form/input/input-field.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-commandes',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterLink,
    BadgeComponent,
    AlertComponent,
    ModalComponent,
    ButtonComponent,
    InputFieldComponent,
  ],
  templateUrl: './commande.component.html',
  styleUrl: './commande.component.css',
})
export class CommandeComponent implements OnInit, OnDestroy {
  // ─── Pagination côté client ───────────────────────────────────
  page = 0;
  size = 20;
  totalPages = 0;
  totalElements = 0;

  // ─── Données ──────────────────────────────────────────────────
  /** Liste complète reçue du backend (List<Commande>) */
  allCommandes: any[] = [];
  /** Tranche affichée selon la page courante */
  commandes: any[] = [];
  isLoading = false;

  // ─── Statistiques rapides ──────────────────────────────────────
  commandesEnAttente = 0;
  commandesEnLivraison = 0;
  commandesLivrees = 0;
  commandesAnnulees = 0;

  // ─── Filtres & Recherche ──────────────────────────────────────
  searchTerm = '';
  selectedStatut = '';
  selectedTypeVente = '';
  dateDebut = '';
  dateFin = '';
  private searchSubject = new Subject<string>();
  private destroy$ = new Subject<void>();

  readonly statuts = [
    { value: '', label: 'Tous les statuts' },
    { value: 'EN_ATTENTE', label: 'En attente' },
    { value: 'CONFIRMEE', label: 'Confirmée' },
    { value: 'EN_LIVRAISON', label: 'En livraison' },
    { value: 'LIVREE', label: 'Livrée' },
    { value: 'ANNULEE', label: 'Annulée' },
  ];

  readonly typesVente = [
    { value: '', label: 'Tous les types' },
    { value: 'PREPAYE', label: 'Prépayé' },
    { value: 'POSTPAYE', label: 'Postpayé' },
  ];

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // ─── Modal mise à jour ────────────────────────────────────────
  isUpdateModalOpen = false;
  commandeToUpdate: any = null;
  updateForm!: FormGroup;
  isUpdating = false;

  // ─── Modal suppression ────────────────────────────────────────
  isDeleteModalOpen = false;
  commandeToDelete: any = null;
  isDeleting = false;

  // ─── Modal changement de statut rapide ────────────────────────
  isStatutRapideModalOpen = false;
  commandeStatutRapide: any = null;
  targetStatutRapide: StatutCommande | null = null;

  constructor(
    private commandeService: CommandeService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initUpdateForm();
    this.loadCommandes();

    this.searchSubject.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.page = 0;
      this.applyFiltersAndPaginate();
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ─── Chargement ───────────────────────────────────────────────
  loadCommandes(): void {
    this.isLoading = true;
    // On récupère toujours la liste complète ; tous les filtres sont appliqués côté client
    this.commandeService.getAllCommandes().subscribe({
      next: (data: any[]) => {
        this.allCommandes = Array.isArray(data) ? data : [];

        // ── Stats rapides sur l'ensemble (avant tout filtre) ───
        this.commandesEnAttente   = this.allCommandes.filter(c => c.statut === 'EN_ATTENTE').length;
        this.commandesEnLivraison = this.allCommandes.filter(c => c.statut === 'EN_LIVRAISON').length;
        this.commandesLivrees     = this.allCommandes.filter(c => c.statut === 'LIVREE').length;
        this.commandesAnnulees    = this.allCommandes.filter(c => c.statut === 'ANNULEE').length;

        // ── Filtrage côté client ──────────────────────────────
        this.applyFiltersAndPaginate();
        this.isLoading = false;
      },
      error: err => {
        console.error(err);
        this.isLoading = false;
        this.showNotification('Erreur lors du chargement des commandes', 'error');
      }
    });
  }

  /** Applique tous les filtres actifs sur allCommandes puis calcule la page courante. */
  private applyFiltersAndPaginate(): void {
    let filtered = [...this.allCommandes];

    // Filtre statut
    if (this.selectedStatut) {
      filtered = filtered.filter(c => c.statut === this.selectedStatut);
    }

    // Filtre type de vente
    if (this.selectedTypeVente) {
      filtered = filtered.filter(c => c.typeVente === this.selectedTypeVente);
    }

    // Filtre texte : nom/prénom client, téléphone, id
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(c => {
        const client = c.client;
        return (
          String(c.idCommande).includes(term) ||
          (client?.nom?.toLowerCase().includes(term)) ||
          (client?.prenom?.toLowerCase().includes(term)) ||
          (client?.telephone?.toLowerCase().includes(term)) ||
          (client?.email?.toLowerCase().includes(term))
        );
      });
    }

    // Filtre date début
    if (this.dateDebut) {
      const debut = new Date(this.dateDebut);
      filtered = filtered.filter(c => new Date(c.created_at) >= debut);
    }

    // Filtre date fin
    if (this.dateFin) {
      const fin = new Date(this.dateFin);
      fin.setHours(23, 59, 59);
      filtered = filtered.filter(c => new Date(c.created_at) <= fin);
    }

    // ── Pagination ────────────────────────────────────────
    this.totalElements = filtered.length;
    this.totalPages = Math.ceil(this.totalElements / this.size) || 1;
    if (this.page >= this.totalPages) this.page = 0;
    this.commandes = filtered.slice(this.page * this.size, (this.page + 1) * this.size);
  }

  // ─── Recherche & Filtres ──────────────────────────────────────
  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
  }

  onStatutChange(statut: string): void {
    // Toggle : re-cliquer sur le même statut remet à "Tous"
    this.selectedStatut = this.selectedStatut === statut ? '' : statut;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onTypeVenteChange(type: string): void {
    this.selectedTypeVente = type;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onDateDebutChange(date: string): void {
    this.dateDebut = date;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onDateFinChange(date: string): void {
    this.dateFin = date;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatut = '';
    this.selectedTypeVente = '';
    this.dateDebut = '';
    this.dateFin = '';
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  get hasActiveFilters(): boolean {
    return !!(this.searchTerm || this.selectedStatut || this.selectedTypeVente || this.dateDebut || this.dateFin);
  }

  // ─── Pagination ───────────────────────────────────────────────
  goToPage(p: number): void {
    if (p < 0 || p >= this.totalPages) return;
    this.page = p;
    this.loadCommandes();
  }

  get pages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }

  // ─── Modal mise à jour ────────────────────────────────────────
  initUpdateForm(): void {
    this.updateForm = this.fb.group({
      statut: ['', Validators.required],
      adresseLivraison: [''],
      moyenPaiement: [''],
      typeVente: [''],
    });
  }

  openUpdateModal(commande: any): void {
    this.commandeToUpdate = commande;
    this.updateForm.patchValue({
      statut: commande.statut,
      adresseLivraison: commande.adresseLivraison ?? '',
      moyenPaiement: commande.moyenPaiement ?? '',
      typeVente: commande.typeVente ?? '',
    });
    this.isUpdateModalOpen = true;
  }

  closeUpdateModal(): void {
    this.isUpdateModalOpen = false;
    this.commandeToUpdate = null;
    this.isUpdating = false;
  }

  onUpdateCommande(): void {
    if (this.updateForm.invalid || !this.commandeToUpdate) return;
    this.isUpdating = true;
    this.commandeService.updateCommande(this.commandeToUpdate.idCommande, this.updateForm.value).subscribe({
      next: () => {
        this.closeUpdateModal();
        this.loadCommandes();
        this.showNotification('Commande mise à jour avec succès', 'success');
      },
      error: () => {
        this.isUpdating = false;
        this.showNotification('Erreur lors de la mise à jour', 'error');
      }
    });
  }

  // ─── Changement de statut rapide ──────────────────────────────
  openStatutRapideModal(commande: any, statut: StatutCommande): void {
    this.commandeStatutRapide = commande;
    this.targetStatutRapide = statut;
    this.isStatutRapideModalOpen = true;
  }

  closeStatutRapideModal(): void {
    this.isStatutRapideModalOpen = false;
    this.commandeStatutRapide = null;
    this.targetStatutRapide = null;
  }

  confirmerStatutRapide(): void {
    if (!this.commandeStatutRapide || !this.targetStatutRapide) return;
    const id = this.commandeStatutRapide.idCommande;
    let obs$;
    switch (this.targetStatutRapide) {
      case 'CONFIRMEE':
        obs$ = this.commandeService.confirmerCommande(id);
        break;
      case 'EN_LIVRAISON':
        obs$ = this.commandeService.mettreEnLivraison(id);
        break;
      case 'LIVREE':
        obs$ = this.commandeService.marquerLivree(id);
        break;
      case 'ANNULEE':
        obs$ = this.commandeService.annulerCommande(id);
        break;
      default:
        obs$ = this.commandeService.updateStatut(id, this.targetStatutRapide);
    }
    obs$.subscribe({
      next: () => {
        this.closeStatutRapideModal();
        this.loadCommandes();
        this.showNotification('Statut mis à jour avec succès', 'success');
      },
      error: () => this.showNotification('Erreur lors du changement de statut', 'error')
    });
  }

  getProchainStatut(commande: any): StatutCommande | null {
    const map: Record<string, StatutCommande> = {
      EN_ATTENTE: 'CONFIRMEE',
      CONFIRMEE: 'EN_LIVRAISON',
      EN_LIVRAISON: 'LIVREE',
    };
    return map[commande.statut] ?? null;
  }

  getProchainStatutLabel(commande: any): string {
    const map: Record<string, string> = {
      EN_ATTENTE: 'Confirmer',
      CONFIRMEE: 'Mettre en livraison',
      EN_LIVRAISON: 'Marquer livrée',
    };
    return map[commande.statut] ?? '';
  }

  // ─── Modal suppression ────────────────────────────────────────
  openDeleteModal(commande: any): void {
    this.commandeToDelete = commande;
    this.isDeleteModalOpen = true;
  }

  closeDeleteModal(): void {
    this.isDeleteModalOpen = false;
    this.commandeToDelete = null;
    this.isDeleting = false;
  }

  onDeleteCommande(): void {
    if (!this.commandeToDelete) return;
    this.isDeleting = true;
    this.commandeService.deleteCommande(this.commandeToDelete.idCommande).subscribe({
      next: () => {
        this.closeDeleteModal();
        this.loadCommandes();
        this.showNotification('Commande supprimée avec succès', 'success');
      },
      error: () => {
        this.isDeleting = false;
        this.showNotification('Erreur lors de la suppression', 'error');
      }
    });
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  encode(id: any): string {
    return btoa(String(id));
  }

  calculCommission(commande: any): number {
    return (commande.lignes ?? []).reduce((total: number, lp: any) => {
      return total + (lp.prixUnitaire * lp.quantite * (lp.produit?.boutique?.commission ?? 0)) / 100;
    }, 0);
  }

  getBadgeColor(status: string): 'success' | 'warning' | 'error' | 'primary' | 'light' {
    const map: Record<string, 'success' | 'warning' | 'error' | 'primary' | 'light'> = {
      LIVREE: 'success',
      CONFIRMEE: 'primary',
      EN_LIVRAISON: 'primary',
      ANNULEE: 'error',
      EN_ATTENTE: 'warning',
    };
    return map[status] ?? 'light';
  }

  getStatutLabel(status: string): string {
    const labels: Record<string, string> = {
      EN_ATTENTE: 'En attente',
      CONFIRMEE: 'Confirmée',
      EN_LIVRAISON: 'En livraison',
      LIVREE: 'Livrée',
      ANNULEE: 'Annulée',
    };
    return labels[status] ?? status;
  }

  getStatutIcon(status: string): string {
    const icons: Record<string, string> = {
      EN_ATTENTE: '⏳',
      CONFIRMEE: '✅',
      EN_LIVRAISON: '🚚',
      LIVREE: '📦',
      ANNULEE: '❌',
    };
    return icons[status] ?? '•';
  }

  canAnnuler(commande: any): boolean {
    return commande.statut === 'EN_ATTENTE' || commande.statut === 'CONFIRMEE';
  }

  // ─── Notification ─────────────────────────────────────────────
  showNotification(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
