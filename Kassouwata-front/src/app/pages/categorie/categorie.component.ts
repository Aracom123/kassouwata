import { Component, OnInit } from '@angular/core';
import { ComponentCardComponent } from '../../shared/components/common/component-card/component-card.component';
import { CommonModule } from '@angular/common';
import { ButtonComponent } from '../../shared/components/ui/button/button.component';
import { TableDropdownComponent } from '../../shared/components/common/table-dropdown/table-dropdown.component';
import { BadgeComponent } from '../../shared/components/ui/badge/badge.component';
import { Categorie } from '../../shared/models/categorie.model';
import { CategorieService } from '../../shared/services/categorie.service';
import { ModalService } from '../../shared/services/modal.service';
import { InputFieldComponent } from '../../shared/components/form/input/input-field.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidationErrors, ValidatorFn, Validators } from '@angular/forms';
import { ProfileService } from '../../shared/services/profile.service';
import { Profile } from '../../shared/models/profile.model';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

@Component({
  selector: 'app-categories',
  imports: [
    CommonModule,
    // ComponentCardComponent,
    ModalComponent,
    AlertComponent,
    InputFieldComponent,
    ButtonComponent,
    TableDropdownComponent,
    ReactiveFormsModule
  ],
  templateUrl: './categorie.component.html',
  styleUrl: './categorie.component.css',
})
export class CategoriesComponent implements OnInit {
  page: number = 0;
  size: number = 30;
  categories: Categorie[] = [];
  isLoading = false;
  skeletonRows = [1, 2, 3, 4, 5, 6];

  categorieToEdit?: any;
  categorieToDelete?: any;

  categorieForm!: FormGroup;

  isOpen = false;

  isAddCategorieModalOpen = false;
  isDeleteCategorieModalOpen = false;

  profiles: Profile[] = [];

  showPassword = false;
  showConfirmPassword = false;
  isChecked = false;

  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // email = '';
  // password = '';


  openModal(categorie: Categorie) {
    this.categorieToEdit = categorie;
    this.onInitCategorieUpdateFG();
    this.isOpen = true;
  }

  openAddCategorieModal() {
    this.categorieToEdit = null;
    this.onInitCategorieUpdateFG();
    this.isAddCategorieModalOpen = true;
  }

  openDeleteCategorieModal(categorie: Categorie) {
    this.categorieToDelete = categorie;
    this.isDeleteCategorieModalOpen = true;
  }

  closeModal() {
    this.isOpen = false;
  }

  closeDeleteCategorieModal() {
    this.isDeleteCategorieModalOpen = false;
  }

  closeAddCategorieModal() {
    this.categorieToEdit = null;
    this.isAddCategorieModalOpen = false;
  }

  constructor(
    private categorieService: CategorieService,
    private profileService: ProfileService,
    public modal: ModalService,
    private fb: FormBuilder,
  ) { }

  ngOnInit(): void {
    this.onInitCategorieUpdateFG();
    this.onGetAllCategories();
    this.onGetAllProfiles();
  }

  onInitCategorieUpdateFG() {
    if (this.categorieToEdit != null) {
      this.categorieForm = this.fb.group({
        // 🔐 Partie Categorie
        libelle: [this.categorieToEdit.libelle ],
        description: [this.categorieToEdit.description],
      });
    } else {
      this.categorieForm = this.fb.group({
        libelle: ["", Validators.required],
        description: [""]
      });
    }
  }

  onGetAllCategories() {
    this.isLoading = true;
    this.categorieService.getAllCategories(this.page, this.size).subscribe({
      next: data => {
        this.categories = data.content;
        this.isLoading = false;
      },
      error: err => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  onGetAllProfiles() {
    this.profileService.getAllProfiles(this.page, this.size).subscribe({
      next: data => {
        this.profiles = data;
        // console.log(this.profiles);

      },
      error: err => console.error(err)
    });
  }

  onUpdate() {
    if (this.categorieForm.invalid) return;

    if (this.categorieToEdit != null) {
      this.categorieService.updateCategorie(this.categorieToEdit.idCategorie, this.categorieForm.value).subscribe(
        {
          next: data => {
            this.closeModal();
            this.ngOnInit();
            this.alertMessage = 'Utilisateur enrégistré avec succès';
            this.variantType = 'success';
            this.showAlert = true;
            setTimeout(() => {
              this.showAlert = false;
            }, 10000); // ⏱ 10 seconds
            // console.log("OK");
          },
          error: err => {
            this.alertMessage = 'Un problème est rencontré lors de la modification !!! <br>Veuillez reprendre cette l\'opération.';
            this.variantType = 'error';
            this.showAlert = true;

            setTimeout(() => {
              this.showAlert = false;
            }, 10000); // ⏱ 10 seconds
          }
        });
    }
    else {
      this.categorieService.saveCategorie(this.categorieForm.value).subscribe(
        {
          next: data => {
            this.closeAddCategorieModal();
            this.ngOnInit();
            this.alertMessage = 'Nouvelle catégorie enrégistrée avec succès';
            this.variantType = 'success';
            this.showAlert = true;

            setTimeout(() => {
              this.showAlert = false;
            }, 10000); // ⏱ 10 seconds
          },
          error: err => {
            this.alertMessage = 'Un problème est rencontré lors de la création de la catégorie !!! <br>Veuillez reprendre cette l\'opération.';
            this.variantType = 'error';
            this.showAlert = true;

            setTimeout(() => {
              this.showAlert = false;
            }, 10000); // ⏱ 10 seconds
          }
        });
    }

  }

  onDeleteCategorie() {
    this.isDeleteCategorieModalOpen = false;
    this.categorieService.deleteCategorie(this.categorieToDelete.idCategorie).subscribe({
      next: success => {
        this.ngOnInit();
        this.alertMessage = 'Catégorie enrégistré avec succès';
        this.variantType = 'success';
        this.showAlert = true;

        setTimeout(() => {
          this.showAlert = false;
        }, 10000); // ⏱ 10 seconds
      },
      error: err => {
        this.alertMessage = 'Un problème est rencontré lors de la suppression !!! <br>Veuillez reprendre cette l\'opération.';
        this.variantType = 'error';
        this.showAlert = true;

        setTimeout(() => {
          this.showAlert = false;
        }, 10000); // ⏱ 10 seconds
      }

    })
  }

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

  toggleConfirmPasswordVisibility() {
    this.showConfirmPassword = !this.showConfirmPassword;
  }

  handleSave() {
    // Handle save logic here
    console.log('Saving changes...');
    this.modal.closeModal();
  }

  handleSaveNewCategorie() {
    // Handle save logic here
    console.log('New categorie added...');
    this.modal.closeModal();
  }
}