import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import {
  AbstractControl, FormBuilder, FormGroup,
  ReactiveFormsModule, ValidationErrors, ValidatorFn, Validators
} from '@angular/forms';

import { User } from '../../shared/models/user.model';
import { Profile } from '../../shared/models/profile.model';
import { UsersService } from '../../shared/services/users.service';
import { ProfileService } from '../../shared/services/profile.service';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../shared/components/ui/button/button.component';
import { BadgeComponent } from '../../shared/components/ui/badge/badge.component';
import { InputFieldComponent } from '../../shared/components/form/input/input-field.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-users',
  imports: [
    CommonModule,
    ReactiveFormsModule,
    AlertComponent,
    ModalComponent,
    ButtonComponent,
    BadgeComponent,
    InputFieldComponent,
  ],
  templateUrl: './users.component.html',
  styleUrl: './users.component.css',
})
export class UsersComponent implements OnInit, OnDestroy {

  // ─── Pagination ───────────────────────────────────────────────
  page = 0;
  size = 15;
  totalPages = 0;
  totalElements = 0;

  // ─── Données ──────────────────────────────────────────────────
  allUsers: User[] = [];
  users: User[] = [];
  profiles: Profile[] = [];
  isLoading = false;
  skeletonRows = [1, 2, 3, 4, 5, 6];

  // ─── Statistiques ─────────────────────────────────────────────
  usersActifs = 0;
  usersSuspendus = 0;
  usersKycPending = 0;
  usersBloquesOuFermes = 0;

  // ─── Filtres ──────────────────────────────────────────────────
  searchTerm = '';
  selectedStatus = '';
  selectedProfileId = '';
  private searchSubject = new Subject<string>();
  private destroy$ = new Subject<void>();

  readonly statuses = [
    { value: '', label: 'Tous les statuts' },
    { value: 'ACTIVE', label: 'Actif' },
    { value: 'SUSPENDED', label: 'Suspendu' },
    { value: 'KYC_PENDING', label: 'KYC en attente' },
    { value: 'BLOCKED', label: 'Bloqué' },
    { value: 'CLOSED', label: 'Fermé' },
  ];

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // ─── Modal ajout / modification ───────────────────────────────
  isFormModalOpen = false;
  userToEdit: any = null;
  userForm!: FormGroup;
  isSaving = false;
  showPassword = false;
  showConfirmPassword = false;

  // ─── Modal suppression ────────────────────────────────────────
  isDeleteModalOpen = false;
  userToDelete: any = null;
  isDeleting = false;

  constructor(
    private userService: UsersService,
    private profileService: ProfileService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadUsers();
    this.loadProfiles();

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
  loadUsers(): void {
    this.isLoading = true;
    this.userService.getAllUsers(0, 1000).subscribe({
      next: (data: any) => {
        this.allUsers = Array.isArray(data) ? data : (Array.isArray(data?.content) ? data.content : []);

        this.usersActifs           = this.allUsers.filter(u => u.status === 'ACTIVE').length;
        this.usersSuspendus        = this.allUsers.filter(u => u.status === 'SUSPENDED').length;
        this.usersKycPending       = this.allUsers.filter(u => u.status === 'KYC_PENDING').length;
        this.usersBloquesOuFermes  = this.allUsers.filter(u => u.status === 'BLOCKED' || u.status === 'CLOSED').length;

        this.applyFiltersAndPaginate();
        this.isLoading = false;
      },
      error: err => {
        console.error(err);
        this.isLoading = false;
        this.notify('Erreur lors du chargement des utilisateurs', 'error');
      }
    });
  }

  loadProfiles(): void {
    this.profileService.getAllProfiles(0, 50).subscribe({
      next: (data: any) => {
        this.profiles = Array.isArray(data) ? data : (Array.isArray(data?.content) ? data.content : []);
      },
      error: err => console.error(err)
    });
  }

  private applyFiltersAndPaginate(): void {
    let filtered = [...this.allUsers];

    if (this.selectedStatus) {
      filtered = filtered.filter(u => u.status === this.selectedStatus);
    }

    if (this.selectedProfileId) {
      filtered = filtered.filter(u => String(u.profile?.idProfile) === this.selectedProfileId);
    }

    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(u =>
        u.personne?.nom?.toLowerCase().includes(term) ||
        u.personne?.prenom?.toLowerCase().includes(term) ||
        u.telephone?.toLowerCase().includes(term) ||
        u.personne?.email?.toLowerCase().includes(term)
      );
    }

    this.totalElements = filtered.length;
    this.totalPages = Math.ceil(this.totalElements / this.size) || 1;
    if (this.page >= this.totalPages) this.page = 0;
    this.users = filtered.slice(this.page * this.size, (this.page + 1) * this.size);
  }

  // ─── Filtres ──────────────────────────────────────────────────
  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
  }

  onStatusChange(val: string): void {
    this.selectedStatus = this.selectedStatus === val ? '' : val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onStatusSelectChange(val: string): void {
    this.selectedStatus = val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  onProfileSelectChange(val: string): void {
    this.selectedProfileId = val;
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedStatus = '';
    this.selectedProfileId = '';
    this.page = 0;
    this.applyFiltersAndPaginate();
  }

  get hasActiveFilters(): boolean {
    return !!(this.searchTerm || this.selectedStatus || this.selectedProfileId);
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
  initForm(user?: any): void {
    if (user) {
      this.userForm = this.fb.group({
        telephone: [{ value: user.telephone, disabled: true }],
        status: [user.status ?? 'ACTIVE'],
        profile: [user.profile],
        personne: this.fb.group({
          idPersonne: [user.personne?.idPersonne],
          prenom: [user.personne?.prenom, Validators.required],
          nom: [user.personne?.nom],
          email: [user.personne?.email],
          adresse: [user.personne?.adresse],
          dateNaissance: [user.personne?.dateNaissance],
          lieuNaissance: [user.personne?.lieuNaissance],
          genre: [user.personne?.genre],
          photo: [user.personne?.photo],
        })
      });
    } else {
      this.userForm = this.fb.group({
        telephone: ['', Validators.required],
        status: ['ACTIVE'],
        password: [''],
        confirmPassword: [''],
        profile: [null],
        personne: this.fb.group({
          prenom: ['', Validators.required],
          nom: [''],
          email: [''],
          adresse: [''],
          dateNaissance: [''],
          lieuNaissance: [''],
          genre: [''],
          photo: [''],
        })
      }, { validators: passwordMatchValidator });
    }
  }

  compareProfile(r1: any, r2: any): boolean {
    return r1 && r2 ? r1.idProfile === r2.idProfile : r1 === r2;
  }

  // ─── Modal ajout / modification ───────────────────────────────
  openAddModal(): void {
    this.userToEdit = null;
    this.showPassword = false;
    this.showConfirmPassword = false;
    this.initForm();
    this.isFormModalOpen = true;
  }

  openEditModal(user: User): void {
    this.userToEdit = user;
    this.initForm(user);
    this.isFormModalOpen = true;
  }

  closeFormModal(): void {
    this.isFormModalOpen = false;
    this.userToEdit = null;
    this.isSaving = false;
  }

  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  toggleConfirmPasswordVisibility(): void {
    this.showConfirmPassword = !this.showConfirmPassword;
  }

  onSave(): void {
    if (this.userForm.invalid) return;
    this.isSaving = true;

    if (this.userToEdit) {
      this.userService.updateUser(this.userToEdit.idUser, this.userForm.value).subscribe({
        next: () => {
          this.closeFormModal();
          this.loadUsers();
          this.notify('Utilisateur modifié avec succès', 'success');
        },
        error: () => {
          this.isSaving = false;
          this.notify('Une erreur est survenue. Veuillez réessayer.', 'error');
        }
      });
    } else {
      this.userService.saveUser(this.userForm.value).subscribe({
        next: () => {
          this.closeFormModal();
          this.loadUsers();
          this.notify('Utilisateur créé avec succès', 'success');
        },
        error: () => {
          this.isSaving = false;
          this.notify('Une erreur est survenue. Veuillez réessayer.', 'error');
        }
      });
    }
  }

  // ─── Modal suppression ────────────────────────────────────────
  openDeleteModal(user: User): void {
    this.userToDelete = user;
    this.isDeleteModalOpen = true;
  }

  closeDeleteModal(): void {
    this.isDeleteModalOpen = false;
    this.userToDelete = null;
    this.isDeleting = false;
  }

  onDelete(): void {
    if (!this.userToDelete) return;
    this.isDeleting = true;
    this.userService.deleteUser(this.userToDelete.idUser).subscribe({
      next: () => {
        this.closeDeleteModal();
        this.loadUsers();
        this.notify('Utilisateur supprimé avec succès', 'success');
      },
      error: () => {
        this.isDeleting = false;
        this.notify('Erreur lors de la suppression', 'error');
      }
    });
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  getBadgeColor(status: string): 'success' | 'warning' | 'error' {
    if (status === 'ACTIVE') return 'success';
    if (status === 'KYC_PENDING' || status === 'SUSPENDED') return 'warning';
    return 'error';
  }

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      ACTIVE: 'Actif',
      SUSPENDED: 'Suspendu',
      KYC_PENDING: 'KYC en attente',
      BLOCKED: 'Bloqué',
      CLOSED: 'Fermé',
    };
    return labels[status] ?? status;
  }

  getInitiales(user: any): string {
    const prenom = user?.personne?.prenom ?? '';
    const nom = user?.personne?.nom ?? '';
    return ((prenom[0] ?? '') + (nom[0] ?? '')).toUpperCase() || 'U';
  }

  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}

export const passwordMatchValidator: ValidatorFn = (
  control: AbstractControl
): ValidationErrors | null => {
  const password = control.get('password')?.value;
  const confirmPassword = control.get('confirmPassword')?.value;
  if (!password || !confirmPassword) return null;
  return password === confirmPassword ? null : { passwordMismatch: true };
};
