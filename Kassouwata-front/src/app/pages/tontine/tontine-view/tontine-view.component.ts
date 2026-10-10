import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';

import { TontineService } from '../../../shared/services/tontine.service';
import { TontineVersementService } from '../../../shared/services/tontine-versement.service';
import { BadgeComponent } from '../../../shared/components/ui/badge/badge.component';
import { AlertComponent } from '../../../shared/components/ui/alert/alert.component';

export type VariantType = 'success' | 'error' | 'warning' | 'info';
type ActiveTab = 'membres' | 'periodes';

@Component({
  selector: 'app-tontine-view',
  imports: [
    CommonModule,
    RouterLink,
    BadgeComponent,
    AlertComponent,
  ],
  templateUrl: './tontine-view.component.html',
  styleUrl: './tontine-view.component.css',
})
export class TontineViewComponent implements OnInit {

  // ─── Données ──────────────────────────────────────────────
  tontineId!: number;
  tontine: any = null;
  membres: any[] = [];
  periodes: any[] = [];
  isLoading = true;

  // ─── Onglets ──────────────────────────────────────────────
  activeTab: ActiveTab = 'membres';

  // ─── Panel versements ─────────────────────────────────────
  selectedPeriode: any = null;
  versements: any[] = [];
  isLoadingVersements = false;
  isPanelOpen = false;

  // ─── Alertes ──────────────────────────────────────────────
  showAlert = false;
  alertMessage = '';
  variantType: VariantType = 'info';

  constructor(
    private route: ActivatedRoute,
    private tontineService: TontineService,
    private versementService: TontineVersementService,
  ) {}

  ngOnInit(): void {
    const encoded = this.route.snapshot.paramMap.get('id');
    if (encoded) {
      this.tontineId = Number(atob(encoded));
      this.loadAll();
    }
  }

  // ─── Chargement initial ───────────────────────────────────
  loadAll(): void {
    this.isLoading = true;
    forkJoin({
      tontine:  this.tontineService.getTontine(this.tontineId),
      membres:  this.tontineService.getMembres(this.tontineId),
      periodes: this.tontineService.getPeriodes(this.tontineId),
    }).subscribe({
      next: ({ tontine, membres, periodes }) => {
        this.tontine  = tontine;
        this.membres  = Array.isArray(membres)  ? membres  : [];
        this.periodes = Array.isArray(periodes) ? periodes : [];
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.notify('Erreur lors du chargement de la tontine', 'error');
      }
    });
  }

  // ─── Onglets ──────────────────────────────────────────────
  setTab(tab: ActiveTab): void {
    this.activeTab = tab;
    this.closePanel();
  }

  // ─── Panel versements d'une période ──────────────────────
  openVersements(periode: any): void {
    this.selectedPeriode = periode;
    this.isPanelOpen = true;
    this.versements = [];
    this.isLoadingVersements = true;

    this.versementService.getVersementsByPeriode(
      periode.idTontinePeriodeVersement
    ).subscribe({
      next: (data) => {
        this.versements = Array.isArray(data) ? data : [];
        this.isLoadingVersements = false;
      },
      error: () => {
        this.isLoadingVersements = false;
        this.notify('Erreur lors du chargement des versements', 'error');
      }
    });
  }

  closePanel(): void {
    this.isPanelOpen = false;
    this.selectedPeriode = null;
    this.versements = [];
  }

  // ─── Stats ────────────────────────────────────────────────
  get nombreMembresActifs(): number {
    return this.membres.filter(m => m.statut === 'ACCEPTEE').length;
  }

  get totalVerse(): number {
    return this.versements.reduce((sum, v) => sum + (v.montant ?? 0), 0);
  }

  get montantAttenduPeriode(): number {
    if (!this.tontine || !this.nombreMembresActifs) return 0;
    return this.tontine.montant * this.nombreMembresActifs;
  }

  get tauxCollecte(): number {
    const attendu = this.montantAttenduPeriode;
    if (!attendu) return 0;
    return Math.min(100, Math.round((this.totalVerse / attendu) * 100));
  }

  // ─── Helpers UI ───────────────────────────────────────────
  getStatutBadge(statut: string): 'success' | 'warning' | 'error' | 'primary' {
    const map: Record<string, any> = {
      ACCEPTEE: 'success', ENVOYEE: 'warning', REFUSEE: 'error',
    };
    return map[statut] ?? 'primary';
  }

  getStatutLabel(statut: string): string {
    const map: Record<string, string> = {
      ACCEPTEE: 'Membre actif', ENVOYEE: 'Invitation envoyée', REFUSEE: 'Refusée',
    };
    return map[statut] ?? statut;
  }

  getPeriodiciteLabel(p: string): string {
    const map: Record<string, string> = {
      HEBDOMADAIRE: 'Hebdomadaire', MENSUEL: 'Mensuel',
      TRIMESTRIEL: 'Trimestriel', SEMESTRIEL: 'Semestriel', ANNUEL: 'Annuel',
    };
    return map[p] ?? p;
  }

  getPeriodeStatut(periode: any): 'active' | 'future' | 'passee' {
    const now   = new Date();
    const debut = new Date(periode.dateDebut);
    const fin   = new Date(periode.dateFin);
    if (now >= debut && now <= fin) return 'active';
    if (now < debut) return 'future';
    return 'passee';
  }

  getPeriodeBadge(periode: any): 'success' | 'warning' | 'primary' {
    const s = this.getPeriodeStatut(periode);
    return s === 'active' ? 'success' : s === 'future' ? 'warning' : 'primary';
  }

  getPeriodeStatutLabel(periode: any): string {
    const s = this.getPeriodeStatut(periode);
    return s === 'active' ? 'En cours' : s === 'future' ? 'À venir' : 'Terminée';
  }

  getMembreNom(demande: any): string {
    const user = demande?.user;
    const p = user?.personne;
    if (p?.prenom || p?.nom) return `${p?.prenom ?? ''} ${p?.nom ?? ''}`.trim();
    return demande?.telephone ?? '—';
  }

  getMembreInitiales(demande: any): string {
    const nom = this.getMembreNom(demande);
    const words = nom.trim().split(' ').filter((w: string) => w.length > 0);
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    return nom.substring(0, 2).toUpperCase();
  }

  // ─── Notification ─────────────────────────────────────────
  notify(message: string, type: VariantType): void {
    this.alertMessage = message;
    this.variantType  = type;
    this.showAlert    = true;
    setTimeout(() => (this.showAlert = false), 4000);
  }
}
