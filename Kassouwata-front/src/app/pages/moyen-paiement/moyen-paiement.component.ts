import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import {
  CategoriePaiement,
  MoyenPaiement,
  PaiementService,
} from '../../shared/services/paiement.service';
import { AlertComponent } from '../../shared/components/ui/alert/alert.component';
import { ModalComponent } from '../../shared/components/ui/modal/modal.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';

interface FormulaireMoyen {
  idMoyenPaiement?: number;
  code: string;
  libelle: string;
  categorieCode: string;
  codeAgregateur: string;
  ordre: number;
  actif: boolean;
}

@Component({
  selector: 'app-moyen-paiement',
  imports: [CommonModule, FormsModule, AlertComponent, ModalComponent],
  templateUrl: './moyen-paiement.component.html',
  styleUrl: './moyen-paiement.component.css',
})
export class MoyenPaiementComponent implements OnInit {
  categories: CategoriePaiement[] = [];
  isLoading = false;

  // ─── Modal moyen de paiement (création / modification) ───────
  isModalOpen = false;
  formulaire: FormulaireMoyen = this.formulaireVide();
  isSaving = false;

  // ─── Modal catégorie ──────────────────────────────────────────
  isCategorieModalOpen = false;
  categorieEnEdition: CategoriePaiement | null = null;
  formCategorie = { libelle: '', description: '', ordre: 0, actif: true };

  /** Moyens dont le logo est en cours d'envoi. */
  logosEnCours = new Set<number>();

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  constructor(private paiementService: PaiementService) {}

  ngOnInit(): void {
    this.charger();
  }

  charger(): void {
    this.isLoading = true;
    this.paiementService.getReferentiel().subscribe({
      next: data => {
        this.categories = data ?? [];
        this.isLoading = false;
      },
      error: err => {
        this.isLoading = false;
        this.notify(err?.status === 403 ? 'Accès réservé aux administrateurs'
          : 'Erreur lors du chargement des moyens de paiement', 'error');
      },
    });
  }

  // ─── Activation rapide ────────────────────────────────────────
  basculerMoyen(m: MoyenPaiement): void {
    this.paiementService.modifierMoyen(m.idMoyenPaiement, { actif: !m.actif }).subscribe({
      next: () => {
        this.notify(`${m.libelle} ${m.actif ? 'désactivé' : 'activé'}`, 'success');
        this.charger();
      },
      error: err => this.notify(this.messageErreur(err), 'error'),
    });
  }

  basculerCategorie(c: CategoriePaiement): void {
    this.paiementService.modifierCategorie(c.idCategoriePaiement, { actif: !c.actif }).subscribe({
      next: () => {
        this.notify(`Catégorie « ${c.libelle} » ${c.actif ? 'désactivée' : 'activée'}`, 'success');
        this.charger();
      },
      error: err => this.notify(this.messageErreur(err), 'error'),
    });
  }

  // ─── Logo ─────────────────────────────────────────────────────
  onLogoChoisi(m: MoyenPaiement, event: Event): void {
    const input = event.target as HTMLInputElement;
    const fichier = input.files?.[0];
    input.value = '';
    if (!fichier) return;
    if (!fichier.type.startsWith('image/')) {
      this.notify('Le logo doit être une image (PNG, JPG, SVG…)', 'warning');
      return;
    }
    this.logosEnCours.add(m.idMoyenPaiement);
    this.paiementService.changerLogo(m.idMoyenPaiement, fichier).subscribe({
      next: () => {
        this.logosEnCours.delete(m.idMoyenPaiement);
        this.notify(`Logo de ${m.libelle} mis à jour`, 'success');
        this.charger();
      },
      error: err => {
        this.logosEnCours.delete(m.idMoyenPaiement);
        this.notify(this.messageErreur(err), 'error');
      },
    });
  }

  urlLogo(m: MoyenPaiement): string | null {
    return this.paiementService.urlLogo(m.logoPath);
  }

  // ─── Modal moyen ──────────────────────────────────────────────
  ouvrirCreation(categorieCode: string): void {
    this.formulaire = { ...this.formulaireVide(), categorieCode };
    this.isModalOpen = true;
  }

  ouvrirModification(m: MoyenPaiement): void {
    this.formulaire = {
      idMoyenPaiement: m.idMoyenPaiement,
      code: m.code,
      libelle: m.libelle,
      categorieCode: m.categorieCode,
      codeAgregateur: m.codeAgregateur ?? '',
      ordre: m.ordre ?? 0,
      actif: m.actif,
    };
    this.isModalOpen = true;
  }

  fermerModal(): void {
    this.isModalOpen = false;
    this.isSaving = false;
  }

  enregistrer(): void {
    const f = this.formulaire;
    if (!f.libelle?.trim() || (!f.idMoyenPaiement && !f.code?.trim())) {
      this.notify('Le code et le libellé sont obligatoires', 'warning');
      return;
    }
    this.isSaving = true;
    const champs: Partial<MoyenPaiement> = {
      libelle: f.libelle.trim(),
      categorieCode: f.categorieCode,
      codeAgregateur: f.codeAgregateur?.trim() || null,
      ordre: Number(f.ordre) || 0,
      actif: f.actif,
    };
    const requete$ = f.idMoyenPaiement
      ? this.paiementService.modifierMoyen(f.idMoyenPaiement, champs)
      : this.paiementService.creerMoyen({ ...champs, code: f.code.trim() });
    requete$.subscribe({
      next: () => {
        this.fermerModal();
        this.notify('Moyen de paiement enregistré', 'success');
        this.charger();
      },
      error: err => {
        this.isSaving = false;
        this.notify(this.messageErreur(err), 'error');
      },
    });
  }

  // ─── Modal catégorie ──────────────────────────────────────────
  ouvrirCategorie(c: CategoriePaiement): void {
    this.categorieEnEdition = c;
    this.formCategorie = {
      libelle: c.libelle,
      description: c.description ?? '',
      ordre: c.ordre ?? 0,
      actif: c.actif,
    };
    this.isCategorieModalOpen = true;
  }

  fermerCategorie(): void {
    this.isCategorieModalOpen = false;
    this.categorieEnEdition = null;
  }

  enregistrerCategorie(): void {
    if (!this.categorieEnEdition) return;
    this.paiementService.modifierCategorie(this.categorieEnEdition.idCategoriePaiement, {
      libelle: this.formCategorie.libelle.trim(),
      description: this.formCategorie.description.trim(),
      ordre: Number(this.formCategorie.ordre) || 0,
      actif: this.formCategorie.actif,
    }).subscribe({
      next: () => {
        this.fermerCategorie();
        this.notify('Catégorie enregistrée', 'success');
        this.charger();
      },
      error: err => this.notify(this.messageErreur(err), 'error'),
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────
  /** Moyen visible dans l'application : actif, catégorie active et code KomiPay renseigné. */
  estVisible(m: MoyenPaiement, c: CategoriePaiement): boolean {
    return m.actif && c.actif && !!m.codeAgregateur;
  }

  private formulaireVide(): FormulaireMoyen {
    return { code: '', libelle: '', categorieCode: 'MOBILE_MONEY', codeAgregateur: '', ordre: 0, actif: false };
  }

  private messageErreur(err: any): string {
    return err?.error?.error || err?.error?.message || 'Une erreur est survenue';
  }

  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
