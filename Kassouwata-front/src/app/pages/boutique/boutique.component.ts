import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RouterLink, RouterModule } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import { BoutiqueService } from '../../shared/services/boutique.service';
import { UsersService } from '../../shared/services/users.service';
import { BadgeComponent } from '../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../shared/components/ui/button/button.component';
import { InputFieldComponent } from '../../shared/components/form/input/input-field.component';
import { TextAreaComponent } from '../../shared/components/form/input/text-area.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-boutiques',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterLink,
    RouterModule,
    BadgeComponent,
    AlertComponent,
    ModalComponent,
    ButtonComponent,
    InputFieldComponent,
    TextAreaComponent,
  ],
  templateUrl: './boutique.component.html',
  styleUrl: './boutique.component.css',
})
export class BoutiquesComponent implements OnInit, OnDestroy {

  // ─── Pagination ───────────────────────────────────────────────
  page = 0;
  size = 15;
  totalPages = 0;
  totalElements = 0;

  // ─── Données ──────────────────────────────────────────────────
  allBoutiques: any[] = [];
  boutiques: any[] = [];
  vendeurs: any[] = [];
  isLoading = false;

  // ─── Statistiques ─────────────────────────────────────────────
  boutiquesActives = 0;
  boutiquesPending = 0;
  boutiquesSuspendues = 0;
  boutiquesClosees = 0;

  // ─── Filtres ──────────────────────────────────────────────────
  searchTerm = '';
  selectedStatus = '';
  private searchSubject = new Subject<string>();
  private destroy$ = new Subject<void>();

  readonly statusList = [
    { value: '', label: 'Tous les statuts' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'PENDING', label: 'En attente' },
    { value: 'SUSPENDED', label: 'Suspendue' },
    { value: 'CLOSED', label: 'Fermée' },
  ];

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // ─── Modal ajout / modification ───────────────────────────────
  isFormModalOpen = false;
  boutiqueToEdit: any = null;
  boutiqueForm!: FormGroup;
  isSaving = false;

  // ─── Modal suppression ────────────────────────────────────────
  isDeleteModalOpen = false;
  boutiqueToDelete: any = null;
  isDeleting = false;

  constructor(
    private boutiqueService: BoutiqueService,
    private userService: UsersService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadBoutiques();
    this.loadVendeurs();

    this.searchSubject.pipe(
      debounceTime(350),
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
  loadBoutiques(): void {
    this.isLoading = true;
    // On charge une grande page pour gérer filtres/pagination côté client
    this.boutiqueService.getAllBoutiques(0, 1000).subscribe({
      next: (data: any) => {
        this.allBoutiques = Array.isArray(data?.content) ? data.content : [];

        this.boutiquesActives    = this.allBoutiques.filter(b => b.status === 'ACTIVE').length;
        this.boutiquesPending    = this.allBoutiques.filter(b => b.status === 'PENDING').length;
        this.boutiquesSuspendues = this.allBoutiques.filter(b => b.status === 'SUSPENDED').length;
        this.boutiquesClosees    = this.allBoutiques.filter(b => b.status === 'CLOSED').length;

        this.applyFiltersAndPaginate();
        this.isLoading = false;
      },
      error: err => {
        console.error(err);
        this.isLoading = false;
        this.notify('Erreur lors du chargement des boutiques', 'error');
      }
    });
  }

  loadVendeurs(): void {
    this.userService.getAllVendeurs().subscribe({
      next: data => { this.vendeurs = data; },
      error: err => console.error(err)
    });
  }

  private applyFiltersAndPaginate(): void {
    let filtered = [...this.allBoutiques];

    if (this.selectedStatus) {
      filtered = filtered.filter(b => b.status === this.selectedStatus);
    }

    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(b =>
        b.libelle?.toLowerCase().includes(term) ||
        b.adresse?.toLowerCase().includes(term) ||
        b.vendeur?.personne?.nom?.toLowerCase().includes(term) ||
        b.vendeur?.personne?.prenom?.toLowerCase().includes(term) ||
        b.vendeur?.telephone?.toLowerCase().includes(term)
      );
    }

    this.totalElements = filtered.length;
    this.totalPages = Math.ceil(this.totalElements / this.size) || 1;
    if (this.page >= this.totalPages) this.page = 0;
    this.boutiques = filtered.slice(this.page * this.size, (this.page + 1) * this.size);
  }

  // ─── Filtres ──────────────────────────────────────────────────
  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
  }

  onStatusChange(status: string): void {
    this.selectedStatus = this.selectedStatus === status ? '' : status;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onStatusSelectChange(status: string): void {
    this.selectedStatus = status;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = '';
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  get hasActiveFilters(): boolean {
    return !!(this.searchTerm || this.selectedStatus);
  }

  // ─── Pagination ───────────────────────────────────────────────
  goToPage(p: number): void {
    if (p < 0 || p >= this.totalPages) return;
    this.page = p;
    this.applyFiltersAndPaginate();
  }

  get pages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }

  // ─── Formulaire ───────────────────────────────────────────────
  initForm(boutique?: any): void {
    this.boutiqueForm = this.fb.group({
      libelle:     [boutique?.libelle     ?? '', Validators.required],
      adresse:     [boutique?.adresse     ?? '', Validators.required],
      description: [boutique?.description ?? ''],
      vendeur:     [boutique?.vendeur     ?? null],
      status:      [boutique?.status      ?? 'ACTIVE'],
      commission:  [boutique?.commission  ?? 5.0],
    });
  }

  compareVendeur(r1: any, r2: any): boolean {
    return r1 && r2 ? r1.idUser === r2.idUser : r1 === r2;
  }

  // ─── Modal ajout ──────────────────────────────────────────────
  openAddModal(): void {
    this.boutiqueToEdit = null;
    this.initForm();
    this.isFormModalOpen = true;
  }

  openEditModal(boutique: any): void {
    this.boutiqueToEdit = boutique;
    this.initForm(boutique);
    this.isFormModalOpen = true;
  }

  closeFormModal(): void {
    this.isFormModalOpen = false;
    this.boutiqueToEdit = null;
    this.isSaving = false;
  }

  onSave(): void {
    if (this.boutiqueForm.invalid) return;
    this.isSaving = true;

    const obs$ = this.boutiqueToEdit
      ? this.boutiqueService.updateBoutique(this.boutiqueToEdit.idBoutique, this.boutiqueForm.value)
      : this.boutiqueService.saveBoutique(this.boutiqueForm.value);

    obs$.subscribe({
      next: () => {
        this.closeFormModal();
        this.loadBoutiques();
        this.notify(this.boutiqueToEdit ? 'Boutique modifiée avec succès' : 'Boutique créée avec succès', 'success');
      },
      error: () => {
        this.isSaving = false;
        this.notify('Une erreur est survenue. Veuillez réessayer.', 'error');
      }
    });
  }

  // ─── Modal suppression ────────────────────────────────────────
  openDeleteModal(boutique: any): void {
    this.boutiqueToDelete = boutique;
    this.isDeleteModalOpen = true;
  }

  closeDeleteModal(): void {
    this.isDeleteModalOpen = false;
    this.boutiqueToDelete = null;
    this.isDeleting = false;
  }

  onDelete(): void {
    if (!this.boutiqueToDelete) return;
    this.isDeleting = true;
    this.boutiqueService.deleteBoutique(this.boutiqueToDelete.idBoutique).subscribe({
      next: () => {
        this.closeDeleteModal();
        this.loadBoutiques();
        this.notify('Boutique supprimée avec succès', 'success');
      },
      error: () => {
        this.isDeleting = false;
        this.notify('Erreur lors de la suppression', 'error');
      }
    });
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  getBadgeColor(status: string): 'success' | 'warning' | 'error' | 'light' {
    const map: Record<string, any> = {
      ACTIVE: 'success',
      PENDING: 'warning',
      SUSPENDED: 'warning',
      CLOSED: 'error',
    };
    return map[status] ?? 'light';
  }

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      ACTIVE: 'Active',
      PENDING: 'En attente',
      SUSPENDED: 'Suspendue',
      CLOSED: 'Fermée',
    };
    return labels[status] ?? status;
  }

  getInitiales(boutique: any): string {
    return (boutique?.libelle ?? 'B')[0].toUpperCase();
  }

  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
