import { Component, OnInit, HostListener } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { environment } from '../../../../environments/environment';
import { ProduitService } from '../../../shared/services/produit.service';
import { BadgeComponent } from '../../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../../shared/components/ui/alert/alert.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-produit-view',
  imports: [
    CommonModule,
    DecimalPipe,
    RouterLink,
    BadgeComponent,
    AlertComponent,
  ],
  templateUrl: './produit-view.component.html',
  styleUrl: './produit-view.component.css',
})
export class ProduitViewComponent implements OnInit {

  // ─── Données ──────────────────────────────────────────────
  produitId!: number;
  produit: any = null;
  isLoading = true;

  // ─── Galerie images ───────────────────────────────────────
  /** Liste de toutes les images (principale + photos supplémentaires) */
  allImages: string[] = [];
  /** Index de l'image actuellement affichée en grand */
  activeIndex = 0;

  // ─── Lightbox zoom ────────────────────────────────────────
  isLightboxOpen = false;
  lightboxIndex = 0;
  /** Niveau de zoom courant (1 = normal, max 4) */
  zoomLevel = 1;
  /** Position du pan quand zoomé */
  panX = 0;
  panY = 0;
  /** Drag en cours */
  isDragging = false;
  dragStartX = 0;
  dragStartY = 0;
  panStartX = 0;
  panStartY = 0;

  // ─── Alertes ──────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  private readonly backendBase = environment.backendBaseUrl.replace('/api', '');

  constructor(
    private route: ActivatedRoute,
    private produitService: ProduitService,
  ) {}

  ngOnInit(): void {
    this.produitId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadProduit();
  }

  // ─── Chargement ───────────────────────────────────────────
  loadProduit(): void {
    this.isLoading = true;
    this.produitService.getProduit(this.produitId).subscribe({
      next: (produit) => {
        this.produit = produit;
        this.buildGallery();
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.notify('Erreur lors du chargement du produit', 'error');
      }
    });
  }

  // ─── Galerie ──────────────────────────────────────────────
  buildGallery(): void {
    const imgs: string[] = [];
    if (this.produit.imagePrincipale) {
      imgs.push(this.getImageUrl(this.produit.imagePrincipale));
    }
    if (this.produit.photos) {
      const extra = this.produit.photos
        .split(',')
        .map((p: string) => p.trim())
        .filter((p: string) => p.length > 0)
        .map((p: string) => this.getImageUrl(p));
      imgs.push(...extra);
    }
    this.allImages = imgs;
    this.activeIndex = 0;
  }

  selectImage(index: number): void {
    this.activeIndex = index;
  }

  prevImage(): void {
    this.activeIndex = (this.activeIndex - 1 + this.allImages.length) % this.allImages.length;
  }

  nextImage(): void {
    this.activeIndex = (this.activeIndex + 1) % this.allImages.length;
  }

  // ─── Lightbox ─────────────────────────────────────────────
  openLightbox(index: number): void {
    this.lightboxIndex = index;
    this.zoomLevel = 1;
    this.panX = 0;
    this.panY = 0;
    this.isLightboxOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeLightbox(): void {
    this.isLightboxOpen = false;
    this.zoomLevel = 1;
    this.panX = 0;
    this.panY = 0;
    document.body.style.overflow = '';
  }

  lightboxPrev(): void {
    this.lightboxIndex = (this.lightboxIndex - 1 + this.allImages.length) % this.allImages.length;
    this.resetZoom();
  }

  lightboxNext(): void {
    this.lightboxIndex = (this.lightboxIndex + 1) % this.allImages.length;
    this.resetZoom();
  }

  zoomIn(): void {
    if (this.zoomLevel < 4) {
      this.zoomLevel = Math.min(4, +(this.zoomLevel + 0.5).toFixed(1));
    }
  }

  zoomOut(): void {
    if (this.zoomLevel > 1) {
      this.zoomLevel = Math.max(1, +(this.zoomLevel - 0.5).toFixed(1));
      if (this.zoomLevel === 1) { this.panX = 0; this.panY = 0; }
    }
  }

  resetZoom(): void {
    this.zoomLevel = 1;
    this.panX = 0;
    this.panY = 0;
  }

  /** Zoom à la molette sur la lightbox */
  onWheelZoom(event: WheelEvent): void {
    event.preventDefault();
    if (event.deltaY < 0) this.zoomIn();
    else this.zoomOut();
  }

  /** Début du drag pour pan */
  onDragStart(event: MouseEvent): void {
    if (this.zoomLevel <= 1) return;
    this.isDragging = true;
    this.dragStartX = event.clientX;
    this.dragStartY = event.clientY;
    this.panStartX = this.panX;
    this.panStartY = this.panY;
    event.preventDefault();
  }

  onDragMove(event: MouseEvent): void {
    if (!this.isDragging) return;
    this.panX = this.panStartX + (event.clientX - this.dragStartX);
    this.panY = this.panStartY + (event.clientY - this.dragStartY);
  }

  onDragEnd(): void {
    this.isDragging = false;
  }

  @HostListener('document:keydown', ['$event'])
  onKeydown(event: KeyboardEvent): void {
    if (!this.isLightboxOpen) return;
    switch (event.key) {
      case 'Escape':    this.closeLightbox(); break;
      case 'ArrowLeft': this.lightboxPrev(); break;
      case 'ArrowRight':this.lightboxNext(); break;
      case '+':         this.zoomIn(); break;
      case '-':         this.zoomOut(); break;
    }
  }

  // ─── Helpers UI ───────────────────────────────────────────
  getImageUrl(filename: string): string {
    if (!filename) return '';
    if (filename.startsWith('http')) return filename;
    return `${this.backendBase}/images/${filename}`;
  }

  getStatutBadge(statut: boolean): 'success' | 'warning' {
    return statut ? 'success' : 'warning';
  }

  getStatutLabel(statut: boolean): string {
    return statut ? 'Publié' : 'Brouillon';
  }

  getStockClass(quantite: number): string {
    if (quantite === 0) return 'text-error-600 font-bold';
    if (quantite <= 5) return 'text-warning-600 font-semibold';
    return 'text-success-600 font-semibold';
  }

  getStockLabel(quantite: number): string {
    if (quantite === 0) return 'Rupture de stock';
    if (quantite <= 5) return 'Stock faible';
    return 'En stock';
  }

  get imageTransform(): string {
    return `scale(${this.zoomLevel}) translate(${this.panX / this.zoomLevel}px, ${this.panY / this.zoomLevel}px)`;
  }

  get imageCursor(): string {
    if (this.zoomLevel > 1) return this.isDragging ? 'grabbing' : 'grab';
    return 'zoom-in';
  }

  // ─── Notification ─────────────────────────────────────────
  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType  = type;
    this.showAlert    = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
