import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import { TontineService } from '../../shared/services/tontine.service';
import { UsersService } from '../../shared/services/users.service';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../shared/components/ui/button/button.component';
import { InputFieldComponent } from '../../shared/components/form/input/input-field.component';
import { TextAreaComponent } from '../../shared/components/form/input/text-area.component';
import { DatePickerComponent } from '../../shared/components/form/date-picker/date-picker.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-tontines',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterLink,
    AlertComponent,
    ModalComponent,
    ButtonComponent,
    InputFieldComponent,
    TextAreaComponent,
    DatePickerComponent,
  ],
  templateUrl: './tontine.component.html',
  styleUrl: './tontine.component.css',
})
export class TontineComponent implements OnInit, OnDestroy {

  // ─── Pagination ───────────────────────────────────────────────
  page = 0;
  size = 15;
  totalPages = 0;
  totalElements = 0;

  // ─── Données ──────────────────────────────────────────────────
  allTontines: any[] = [];
  tontines: any[] = [];
  membres: any[] = [];
  isLoading = false;

  // ─── Statistiques ─────────────────────────────────────────────
  tontinesHebdo = 0;
  tontinesMensuelles = 0;
  tontinesTrimestrielles = 0;
  tontinesAutres = 0;
  adashesProduit = 0;
  adashesEnAttente = 0;

  // ─── Filtres ──────────────────────────────────────────────────
  searchTerm = '';
  selectedPeriodicite = '';
  selectedType = '';
  private searchSubject = new Subject<string>();
  private destroy$ = new Subject<void>();

  readonly periodicites = [
    { value: '', label: 'Toutes les périodicités' },
    { value: 'HEBDOMADAIRE', label: 'Hebdomadaire' },
    { value: 'MENSUEL', label: 'Mensuel' },
    { value: 'TRIMESTRIEL', label: 'Trimestriel' },
    { value: 'SEMESTRIEL', label: 'Semestriel' },
    { value: 'ANNUEL', label: 'Annuel' },
  ];

  readonly types = [
    { value: '', label: 'Tous les types' },
    { value: 'CLASSIQUE', label: 'Adashé classique' },
    { value: 'PRODUIT', label: 'Achat groupé (produit)' },
  ];

  readonly statutsAdashe: Record<string, { label: string; classes: string }> = {
    EN_ATTENTE_VENDEUR: { label: 'En attente du vendeur', classes: 'bg-warning-50 text-warning-700 dark:bg-warning-900/20 dark:text-warning-400' },
    ACTIF:              { label: 'Actif',                 classes: 'bg-success-50 text-success-700 dark:bg-success-900/20 dark:text-success-400' },
    REFUSE:             { label: 'Refusé',                classes: 'bg-error-50 text-error-700 dark:bg-error-900/20 dark:text-error-400' },
    OBJECTIF_ATTEINT:   { label: 'Objectif atteint',      classes: 'bg-brand-50 text-brand-700 dark:bg-brand-900/20 dark:text-brand-400' },
  };

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // ─── Modal ajout / modification ───────────────────────────────
  isFormModalOpen = false;
  tontineToEdit: any = null;
  tontineForm!: FormGroup;
  isSaving = false;

  // ─── Modal suppression ────────────────────────────────────────
  isDeleteModalOpen = false;
  tontineToDelete: any = null;
  isDeleting = false;

  constructor(
    private tontineService: TontineService,
    private userService: UsersService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadTontines();
    this.loadMembres();

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
  loadTontines(): void {
    this.isLoading = true;
    this.tontineService.getAllTontines(0, 1000).subscribe({
      next: (data: any) => {
        this.allTontines = Array.isArray(data?.content) ? data.content : [];

        this.tontinesHebdo         = this.allTontines.filter(t => t.periodicite === 'HEBDOMADAIRE').length;
        this.tontinesMensuelles    = this.allTontines.filter(t => t.periodicite === 'MENSUEL').length;
        this.tontinesTrimestrielles = this.allTontines.filter(t => t.periodicite === 'TRIMESTRIEL').length;
        this.tontinesAutres        = this.allTontines.filter(t =>
          !['HEBDOMADAIRE', 'MENSUEL', 'TRIMESTRIEL'].includes(t.periodicite)
        ).length;
        this.adashesProduit   = this.allTontines.filter(t => this.estProduit(t)).length;
        this.adashesEnAttente = this.allTontines.filter(t => this.statutDe(t) === 'EN_ATTENTE_VENDEUR').length;

        this.applyFiltersAndPaginate();
        this.isLoading = false;
      },
      error: err => {
        console.error(err);
        this.isLoading = false;
        this.notify('Erreur lors du chargement des tontines', 'error');
      }
    });
  }

  loadMembres(): void {
    this.userService.getAllUsers().subscribe({
      next: data => { this.membres = data; },
      error: err => console.error(err)
    });
  }

  private applyFiltersAndPaginate(): void {
    let filtered = [...this.allTontines];

    if (this.selectedPeriodicite) {
      filtered = filtered.filter(t => t.periodicite === this.selectedPeriodicite);
    }

    if (this.selectedType) {
      filtered = filtered.filter(t => (this.estProduit(t) ? 'PRODUIT' : 'CLASSIQUE') === this.selectedType);
    }

    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(t =>
        t.libelle?.toLowerCase().includes(term) ||
        t.tontineOwner?.personne?.nom?.toLowerCase().includes(term) ||
        t.tontineOwner?.personne?.prenom?.toLowerCase().includes(term) ||
        t.tontineOwner?.telephone?.toLowerCase().includes(term) ||
        t.produit?.libelle?.toLowerCase().includes(term)
      );
    }

    this.totalElements = filtered.length;
    this.totalPages = Math.ceil(this.totalElements / this.size) || 1;
    if (this.page >= this.totalPages) this.page = 0;
    this.tontines = filtered.slice(this.page * this.size, (this.page + 1) * this.size);
  }

  // ─── Filtres ──────────────────────────────────────────────────
  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
  }

  onPeriodiciteChange(val: string): void {
    this.selectedPeriodicite = this.selectedPeriodicite === val ? '' : val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onPeriodiciteSelectChange(val: string): void {
    this.selectedPeriodicite = val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onTypeChange(val: string): void {
    this.selectedType = this.selectedType === val ? '' : val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onTypeSelectChange(val: string): void {
    this.selectedType = val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  // ─── Type / statut Adashé ─────────────────────────────────────
  estProduit(t: any): boolean {
    return t?.typeAdashe === 'PRODUIT';
  }

  statutDe(t: any): string {
    return t?.statutAdashe || 'ACTIF';
  }

  statutLabel(t: any): string {
    return this.statutsAdashe[this.statutDe(t)]?.label ?? this.statutDe(t);
  }

  statutClasses(t: any): string {
    return this.statutsAdashe[this.statutDe(t)]?.classes ?? 'bg-gray-100 text-gray-600';
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedPeriodicite = '';
    this.selectedType = '';
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  get hasActiveFilters(): boolean {
    return !!(this.searchTerm || this.selectedPeriodicite || this.selectedType);
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
  initForm(tontine?: any): void {
    this.tontineForm = this.fb.group({
      libelle:      [tontine?.libelle      ?? '', Validators.required],
      montant:      [tontine?.montant      ?? 0,  Validators.required],
      periodicite:  [tontine?.periodicite  ?? '', Validators.required],
      tontineOwner: [tontine?.tontineOwner ?? null, Validators.required],
      dateDebut:    [tontine?.dateDebut    ?? null, Validators.required],
      dateFin:      [tontine?.dateFin      ?? null, Validators.required],
      description:  [tontine?.description  ?? ''],
    });
  }

  compareMembre(r1: any, r2: any): boolean {
    return r1 && r2 ? r1.idUser === r2.idUser : r1 === r2;
  }

  handleDateDebutChange(event: any): void {
    this.tontineForm.patchValue({ dateDebut: new Date(event.dateStr) });
  }

  handleDateFinChange(event: any): void {
    this.tontineForm.patchValue({ dateFin: new Date(event.dateStr) });
  }

  // ─── Modal ajout ──────────────────────────────────────────────
  openAddModal(): void {
    this.tontineToEdit = null;
    this.initForm();
    this.isFormModalOpen = true;
  }

  openEditModal(tontine: any): void {
    this.tontineToEdit = tontine;
    this.initForm(tontine);
    this.isFormModalOpen = true;
  }

  closeFormModal(): void {
    this.isFormModalOpen = false;
    this.tontineToEdit = null;
    this.isSaving = false;
  }

  onSave(): void {
    if (this.tontineForm.invalid) return;
    this.isSaving = true;

    const obs$ = this.tontineToEdit
      ? this.tontineService.updateTontine(this.tontineToEdit.idTontine, this.tontineForm.value)
      : this.tontineService.saveTontine(this.tontineForm.value);

    obs$.subscribe({
      next: () => {
        this.closeFormModal();
        this.loadTontines();
        this.notify(this.tontineToEdit ? 'Tontine modifiée avec succès' : 'Tontine créée avec succès', 'success');
      },
      error: () => {
        this.isSaving = false;
        this.notify('Une erreur est survenue. Veuillez réessayer.', 'error');
      }
    });
  }

  // ─── Modal suppression ────────────────────────────────────────
  openDeleteModal(tontine: any): void {
    this.tontineToDelete = tontine;
    this.isDeleteModalOpen = true;
  }

  closeDeleteModal(): void {
    this.isDeleteModalOpen = false;
    this.tontineToDelete = null;
    this.isDeleting = false;
  }

  onDelete(): void {
    if (!this.tontineToDelete) return;
    this.isDeleting = true;
    this.tontineService.deleteTontine(this.tontineToDelete.idTontine).subscribe({
      next: () => {
        this.closeDeleteModal();
        this.loadTontines();
        this.notify('Tontine supprimée avec succès', 'success');
      },
      error: () => {
        this.isDeleting = false;
        this.notify('Erreur lors de la suppression', 'error');
      }
    });
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  getPeriodiciteLabel(p: string): string {
    const labels: Record<string, string> = {
      HEBDOMADAIRE: 'Hebdo.',
      MENSUEL: 'Mensuel',
      TRIMESTRIEL: 'Trimestriel',
      SEMESTRIEL: 'Semestriel',
      ANNUEL: 'Annuel',
    };
    return labels[p] ?? p;
  }

  getInitiales(tontine: any): string {
    return (tontine?.libelle ?? 'T')[0].toUpperCase();
  }

  encode(id: any): string {
    return btoa(String(id));
  }

  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
