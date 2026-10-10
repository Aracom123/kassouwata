import { Component, OnInit } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';

import { environment } from '../../../environments/environment';
import { ProduitService } from '../../shared/services/produit.service';
import { BadgeComponent } from '../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-produits',
  imports: [
    CommonModule,
    DecimalPipe,
    RouterLink,
    FormsModule,
    AlertComponent,
  ],
  templateUrl: './produit.component.html',
  styleUrl: './produit.component.css',
})
export class ProduitComponent implements OnInit {

  // ─── Données ──────────────────────────────────────────────
  allProduits: any[] = [];
  produitsFiltres: any[] = [];
  isLoading = true;

  // ─── Filtres ──────────────────────────────────────────────
  searchTerm = '';
  filtreStatut = '';

  // ─── Pagination ───────────────────────────────────────────
  currentPage = 1;
  pageSize = 12;

  // ─── Alertes ──────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  private readonly backendBase = environment.backendBaseUrl.replace('/api', '');

  constructor(private produitService: ProduitService) {}

  ngOnInit(): void {
    this.loadProduits();
  }

  // ─── Chargement ───────────────────────────────────────────
  loadProduits(): void {
    this.isLoading = true;
    this.produitService.getAllProduits(0, 9999).subscribe({
      next: (data: any) => {
        // Le backend renvoie un tableau plat ou un objet paginé selon la version
        this.allProduits = Array.isArray(data) ? data : (data.content ?? []);
        this.applyFilters();
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.notify('Erreur lors du chargement des produits', 'error');
      }
    });
  }

  // ─── Filtres + pagination ─────────────────────────────────
  applyFilters(): void {
    let result = [...this.allProduits];

    if (this.searchTerm.trim()) {
      const t = this.searchTerm.toLowerCase();
      result = result.filter(p =>
        p.libelle?.toLowerCase().includes(t) ||
        p.description?.toLowerCase().includes(t) ||
        p.boutique?.libelle?.toLowerCase().includes(t) ||
        p.categorie?.libelle?.toLowerCase().includes(t)
      );
    }

    if (this.filtreStatut === 'publie') {
      result = result.filter(p => p.statut === true);
    } else if (this.filtreStatut === 'brouillon') {
      result = result.filter(p => p.statut !== true);
    } else if (this.filtreStatut === 'stock_faible') {
      result = result.filter(p => p.quantite <= 5);
    }

    this.produitsFiltres = result;
    this.currentPage = 1; // reset page à chaque filtre
  }

  // ─── Pagination ───────────────────────────────────────────
  get totalPages(): number {
    return Math.ceil(this.produitsFiltres.length / this.pageSize);
  }

  get paginatedProduits(): any[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.produitsFiltres.slice(start, start + this.pageSize);
  }

  get pages(): number[] {
    const total = this.totalPages;
    if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
    // Fenêtre glissante autour de la page courante
    const pages: number[] = [1];
    const start = Math.max(2, this.currentPage - 1);
    const end   = Math.min(total - 1, this.currentPage + 1);
    if (start > 2) pages.push(-1); // ellipse
    for (let i = start; i <= end; i++) pages.push(i);
    if (end < total - 1) pages.push(-1); // ellipse
    pages.push(total);
    return pages;
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages) return;
    this.currentPage = page;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // ─── Helpers image ────────────────────────────────────────
  getImageUrl(filename: string): string {
    if (!filename) return '';
    if (filename.startsWith('http')) return filename;
    return `${this.backendBase}/images/${filename}`;
  }

  // ─── Helpers UI ───────────────────────────────────────────
  getStatutBadge(statut: boolean): 'success' | 'warning' {
    return statut ? 'success' : 'warning';
  }

  getStatutLabel(statut: boolean): string {
    return statut ? 'Publié' : 'Brouillon';
  }

  getStockClass(quantite: number): string {
    if (quantite === 0) return 'text-error-600';
    if (quantite <= 5) return 'text-warning-600';
    return 'text-success-600';
  }

  // ─── Notification ─────────────────────────────────────────
  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType  = type;
    this.showAlert    = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
