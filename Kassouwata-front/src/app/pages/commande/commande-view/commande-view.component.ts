import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ReactiveFormsModule, FormBuilder, FormGroup } from '@angular/forms';
import { CommandeService, StatutCommande } from '../../../shared/services/commande.service';
import { ActivatedRoute } from '@angular/router';
import { AlertComponent } from '../../../shared/components/ui/alert/alert.component';
import { BadgeComponent } from '../../../shared/components/ui/badge/badge.component';
import { ModalComponent } from '../../../shared/components/ui/modal/modal.component';
import { ButtonComponent } from '../../../shared/components/ui/button/button.component';
import { InputFieldComponent } from '../../../shared/components/form/input/input-field.component';
import { VariantType } from '../commande.component';
import {
  PaiementService,
  ResumePaiementCommande,
  TransactionPaiement,
  classeStatutPaiement,
  libelleFournisseur,
  libelleStatutPaiement,
} from '../../../shared/services/paiement.service';

interface StatutStep {
  key: StatutCommande;
  label: string;
}

@Component({
  selector: 'app-commande-view',
  imports: [
    CommonModule,
    RouterLink,
    ReactiveFormsModule,
    AlertComponent,
    BadgeComponent,
    ModalComponent,
    ButtonComponent,
    InputFieldComponent,
  ],
  templateUrl: './commande-view.component.html',
  styleUrl: './commande-view.component.css',
})
export class CommandeViewComponent implements OnInit {
  idCurrentCommande: any;
  currentCommande: any;
  isLoading = true;

  // ─── Alertes ──────────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  // ─── Modal changement de statut ──────────────────────────────
  isStatutModalOpen = false;
  targetStatut: StatutCommande | null = null;
  statutForm!: FormGroup;
  isChangingStatut = false;

  // ─── Modal édition complète ───────────────────────────────────
  isEditModalOpen = false;
  editForm!: FormGroup;
  isEditing = false;

  // ─── Paiements ────────────────────────────────────────────────
  resumePaiement: ResumePaiementCommande | null = null;
  paiements: TransactionPaiement[] = [];
  isLoadingPaiements = false;
  enVerification = new Set<string>();

  // ─── Workflow des statuts ─────────────────────────────────────
  readonly statutSteps: StatutStep[] = [
    { key: 'EN_ATTENTE', label: 'En attente' },
    { key: 'CONFIRMEE', label: 'Confirmée' },
    { key: 'EN_LIVRAISON', label: 'En livraison' },
    { key: 'LIVREE', label: 'Livrée' },
  ];

  readonly statuts = [
    { value: 'EN_ATTENTE', label: 'En attente' },
    { value: 'CONFIRMEE', label: 'Confirmée' },
    { value: 'EN_LIVRAISON', label: 'En livraison' },
    { value: 'LIVREE', label: 'Livrée' },
    { value: 'ANNULEE', label: 'Annulée' },
  ];

  constructor(
    private commandeService: CommandeService,
    private paiementService: PaiementService,
    private route: ActivatedRoute,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initForms();
    this.route.paramMap.subscribe(params => {
      const encoded = params.get('id');
      if (encoded) {
        this.idCurrentCommande = atob(encoded);
        this.loadCommande();
      }
    });
  }

  // ─── Init formulaires ────────────────────────────────────────
  initForms(): void {
    this.statutForm = this.fb.group({
      adresseLivraison: [''],
    });
    this.editForm = this.fb.group({
      statut: [''],
      typeVente: [''],
      moyenPaiement: [''],
      adresseLivraison: [''],
    });
  }

  // ─── Chargement ──────────────────────────────────────────────
  loadCommande(): void {
    this.isLoading = true;
    this.commandeService.getCommande(this.idCurrentCommande).subscribe({
      next: data => {
        this.currentCommande = data;
        this.isLoading = false;
        this.loadPaiements();
      },
      error: () => {
        this.isLoading = false;
        this.showNotification('Erreur lors du chargement de la commande', 'error');
      }
    });
  }

  // ─── Paiements ───────────────────────────────────────────────
  loadPaiements(): void {
    const id = this.currentCommande?.idCommande;
    if (!id) return;
    this.isLoadingPaiements = true;
    this.paiementService.getResumeCommande(id).subscribe({
      next: r => (this.resumePaiement = r),
      error: () => (this.resumePaiement = null),
    });
    this.paiementService.getTransactions(0, 50, { commandeId: id }).subscribe({
      next: page => {
        this.paiements = page?.content ?? [];
        this.isLoadingPaiements = false;
      },
      error: () => {
        this.paiements = [];
        this.isLoadingPaiements = false;
      },
    });
  }

  verifierPaiement(t: TransactionPaiement): void {
    const ref = t.referenceExterne;
    if (!ref || this.enVerification.has(ref)) return;
    this.enVerification.add(ref);
    this.paiementService.verifierStatut(ref).subscribe({
      next: res => {
        this.enVerification.delete(ref);
        const statut = res?.statut;
        this.showNotification(
          statut === 'REUSSIE' ? 'Paiement confirmé'
            : statut === 'ECHOUEE' ? 'Paiement en échec'
            : 'Paiement toujours en attente de validation',
          statut === 'REUSSIE' ? 'success' : statut === 'ECHOUEE' ? 'warning' : 'info');
        this.loadPaiements();
      },
      error: err => {
        this.enVerification.delete(ref);
        this.showNotification(err?.error?.error || 'Vérification impossible pour le moment', 'error');
      },
    });
  }

  get pourcentagePaye(): number {
    const r = this.resumePaiement;
    if (!r || !r.montantTotal) return 0;
    return Math.min(100, Math.round((r.montantPaye / r.montantTotal) * 100));
  }

  libelleStatutPaiementCommande(statut?: string): string {
    const map: Record<string, string> = {
      NON_PAYEE: 'Non payée',
      PARTIELLEMENT_PAYEE: 'Partiellement payée',
      PAYEE: 'Payée',
    };
    return statut ? map[statut] ?? statut : '—';
  }

  classeStatutPaiementCommande(statut?: string): string {
    switch (statut) {
      case 'PAYEE': return 'bg-success-50 text-success-700 dark:bg-success-500/15 dark:text-success-500';
      case 'PARTIELLEMENT_PAYEE': return 'bg-warning-50 text-warning-700 dark:bg-warning-500/15 dark:text-orange-400';
      default: return 'bg-gray-100 text-gray-700 dark:bg-white/5 dark:text-white/80';
    }
  }

  libelleStatutPaiement = libelleStatutPaiement;
  libelleFournisseur = libelleFournisseur;
  classeStatutPaiement = classeStatutPaiement;

  // ─── Workflow statut ─────────────────────────────────────────
  get prochainStatut(): StatutCommande | null {
    if (!this.currentCommande) return null;
    const map: Record<string, StatutCommande> = {
      EN_ATTENTE: 'CONFIRMEE',
      CONFIRMEE: 'EN_LIVRAISON',
      EN_LIVRAISON: 'LIVREE',
    };
    return map[this.currentCommande.statut] ?? null;
  }

  get prochainStatutLabel(): string {
    const map: Record<string, string> = {
      EN_ATTENTE: 'Confirmer la commande',
      CONFIRMEE: 'Mettre en livraison',
      EN_LIVRAISON: 'Marquer comme livrée',
    };
    return map[this.currentCommande?.statut] ?? '';
  }

  get canAnnuler(): boolean {
    return this.currentCommande?.statut === 'EN_ATTENTE' ||
           this.currentCommande?.statut === 'CONFIRMEE';
  }

  getStepState(step: StatutStep): 'done' | 'current' | 'pending' {
    const order: StatutCommande[] = ['EN_ATTENTE', 'CONFIRMEE', 'EN_LIVRAISON', 'LIVREE'];
    const currentIdx = order.indexOf(this.currentCommande?.statut);
    const stepIdx = order.indexOf(step.key);
    if (stepIdx < currentIdx) return 'done';
    if (stepIdx === currentIdx) return 'current';
    return 'pending';
  }

  openStatutModal(statut: StatutCommande): void {
    this.targetStatut = statut;
    this.statutForm.patchValue({ adresseLivraison: this.currentCommande?.adresseLivraison ?? '' });
    this.isStatutModalOpen = true;
  }

  closeStatutModal(): void {
    this.isStatutModalOpen = false;
    this.targetStatut = null;
    this.isChangingStatut = false;
  }

  confirmerChangementStatut(): void {
    if (!this.targetStatut || !this.currentCommande) return;
    this.isChangingStatut = true;
    const id = this.currentCommande.idCommande;
    let obs$;

    switch (this.targetStatut) {
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
        obs$ = this.commandeService.updateStatut(id, this.targetStatut);
    }

    obs$.subscribe({
      next: () => {
        this.closeStatutModal();
        this.loadCommande();
        this.showNotification('Statut mis à jour avec succès', 'success');
      },
      error: () => {
        this.isChangingStatut = false;
        this.showNotification('Erreur lors du changement de statut', 'error');
      }
    });
  }

  annulerCommande(): void {
    this.openStatutModal('ANNULEE');
  }

  // ─── Modal édition ────────────────────────────────────────────
  openEditModal(): void {
    this.editForm.patchValue({
      statut: this.currentCommande?.statut ?? '',
      typeVente: this.currentCommande?.typeVente ?? '',
      moyenPaiement: this.currentCommande?.moyenPaiement ?? '',
      adresseLivraison: this.currentCommande?.adresseLivraison ?? '',
    });
    this.isEditModalOpen = true;
  }

  closeEditModal(): void {
    this.isEditModalOpen = false;
    this.isEditing = false;
  }

  onSaveEdit(): void {
    if (!this.currentCommande) return;
    this.isEditing = true;
    this.commandeService.updateCommande(this.currentCommande.idCommande, this.editForm.value).subscribe({
      next: () => {
        this.closeEditModal();
        this.loadCommande();
        this.showNotification('Commande mise à jour avec succès', 'success');
      },
      error: () => {
        this.isEditing = false;
        this.showNotification('Erreur lors de la mise à jour', 'error');
      }
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────
  calculCommission(commande: any): number {
    return (commande?.lignes ?? []).reduce((total: number, lp: any) => {
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

  getBoutiquesUniques(commande: any): string[] {
    const boutiques = (commande?.lignes ?? [])
      .map((lp: any) => lp.produit?.boutique?.libelle)
      .filter((b: any) => !!b);
    return [...new Set<string>(boutiques)];
  }

  showNotification(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType = type;
    this.showAlert = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
