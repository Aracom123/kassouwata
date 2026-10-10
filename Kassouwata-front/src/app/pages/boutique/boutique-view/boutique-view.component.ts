import { Component, OnInit } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { forkJoin } from 'rxjs';

import { environment } from '../../../../environments/environment';
import { BoutiqueService } from '../../../shared/services/boutique.service';
import { ProduitService } from '../../../shared/services/produit.service';
import { BadgeComponent } from '../../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../../shared/components/ui/button/button.component';
import { InputFieldComponent } from '../../../shared/components/form/input/input-field.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-boutique-view',
  imports: [
    CommonModule,
    DecimalPipe,
    RouterLink,
    ReactiveFormsModule,
    BadgeComponent,
    AlertComponent,
    ModalComponent,
    ButtonComponent,
    InputFieldComponent,
  ],
  templateUrl: './boutique-view.component.html',
  styleUrl: './boutique-view.component.css',
})
export class BoutiqueViewComponent implements OnInit {

  // ─── Données ──────────────────────────────────────────────
  boutiqueId!: number;
  boutique: any = null;
  produits: any[] = [];
  produitsFiltres: any[] = [];
  stats: any = null;
  isLoading = true;

  // ─── Filtres produits ─────────────────────────────────────
  searchTerm = '';
  filtreStatut = '';

  // ─── Modal édition boutique ───────────────────────────────
  isEditModalOpen = false;
  isSaving = false;
  editForm!: FormGroup;

  // ─── Modal changement statut boutique ────────────────────
  isStatutModalOpen = false;
  newStatut = '';
  readonly statusList = ['ACTIVE', 'PENDING', 'SUSPENDED', 'CLOSED'];

  // ─── Alertes ──────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  constructor(
    private route: ActivatedRoute,
    private boutiqueService: BoutiqueService,
    private produitService: ProduitService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.boutiqueId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadAll();
  }

  // ─── Chargement ───────────────────────────────────────────
  loadAll(): void {
    this.isLoading = true;
    forkJoin({
      boutique: this.boutiqueService.getBoutique(this.boutiqueId),
      produits: this.produitService.getProduitsByBoutiqueId(this.boutiqueId),
      stats:    this.boutiqueService.getStatsBoutique(this.boutiqueId),
    }).subscribe({
      next: ({ boutique, produits, stats }) => {
        this.boutique = boutique;
        this.produits = Array.isArray(produits) ? produits : [];
        this.stats    = stats;
        this.applyFilters();
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.notify('Erreur lors du chargement de la boutique', 'error');
      }
    });
  }

  // ─── Filtres produits ─────────────────────────────────────
  applyFilters(): void {
    let result = [...this.produits];
    if (this.searchTerm) {
      const t = this.searchTerm.toLowerCase();
      result = result.filter(p =>
        p.libelle?.toLowerCase().includes(t) ||
        p.description?.toLowerCase().includes(t)
      );
    }
    if (this.filtreStatut === 'publié') {
      result = result.filter(p => p.statut === true);
    } else if (this.filtreStatut === 'brouillon') {
      result = result.filter(p => p.statut !== true);
    }
    this.produitsFiltres = result;
  }

  onSearch(term: string): void {
    this.searchTerm = term;
    this.applyFilters();
  }

  onFiltreStatutChange(val: string): void {
    this.filtreStatut = val;
    this.applyFilters();
  }

  // ─── Modal édition boutique ───────────────────────────────
  openEditModal(): void {
    this.editForm = this.fb.group({
      libelle:     [this.boutique.libelle,     Validators.required],
      adresse:     [this.boutique.adresse,     Validators.required],
      description: [this.boutique.description, Validators.required],
      commission:  [this.boutique.commission,  [Validators.required, Validators.min(0), Validators.max(100)]],
      status:      [this.boutique.status,      Validators.required],
    });
    this.isEditModalOpen = true;
  }

  closeEditModal(): void {
    this.isEditModalOpen = false;
    this.isSaving = false;
  }

  onSaveBoutique(): void {
    if (this.editForm.invalid) return;
    this.isSaving = true;
    this.boutiqueService.updateBoutique(this.boutiqueId, this.editForm.value).subscribe({
      next: () => {
        this.closeEditModal();
        this.loadAll();
        this.notify('Boutique mise à jour avec succès', 'success');
      },
      error: () => {
        this.isSaving = false;
        this.notify('Erreur lors de la mise à jour', 'error');
      }
    });
  }

  // ─── Helpers UI ───────────────────────────────────────────
  getStatusBadge(status: string): 'success' | 'warning' | 'error' | 'primary' {
    const map: Record<string, any> = {
      ACTIVE: 'success', PENDING: 'warning', SUSPENDED: 'warning', CLOSED: 'error'
    };
    return map[status] ?? 'primary';
  }

  getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      ACTIVE: 'Active', PENDING: 'En attente', SUSPENDED: 'Suspendue', CLOSED: 'Fermée'
    };
    return map[status] ?? status;
  }

  getProduitBadge(statut: boolean): 'success' | 'warning' {
    return statut ? 'success' : 'warning';
  }

  get tauxLivraison(): number {
    return this.stats?.tauxLivraison ?? 0;
  }

  // ─── Images produits ──────────────────────────────────────
  getImageUrl(imagePrincipale: string): string {
    if (!imagePrincipale) return '';
    // Si l'URL est déjà absolue (http/https), on la retourne telle quelle
    if (imagePrincipale.startsWith('http')) return imagePrincipale;
    // Le backend sert les images via GET /images/{filename}
    const base = environment.backendBaseUrl.replace('/api', '');
    return `${base}/images/${imagePrincipale}`;
  }

  onImageError(event: Event): void {
    // En cas d'erreur de chargement, on masque l'image et affiche le fallback SVG
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    const parent = img.parentElement;
    if (parent) {
      parent.innerHTML = `
        <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5
               1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5
               0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5
               1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0
               1 1-.75 0 .375.375 0 0 1 .75 0Z" />
        </svg>`;
    }
  }

  // ─── Notification ─────────────────────────────────────────
  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType  = type;
    this.showAlert    = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
