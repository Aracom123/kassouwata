import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { BadgeComponent } from '../../ui/badge/badge.component';
import { CommandeService } from '../../../services/commande.service';

@Component({
  selector: 'app-recent-orders',
  imports: [CommonModule, RouterLink, BadgeComponent],
  templateUrl: './recent-orders.component.html',
})
export class RecentOrdersComponent implements OnInit {
  commandes: any[] = [];
  isLoading = true;
  commandesEnAttente = 0;

  constructor(private commandeService: CommandeService) {}

  ngOnInit(): void {
    this.commandeService.getAllCommandes().subscribe({
      next: data => {
        const all: any[] = Array.isArray(data) ? data : [];
        // Trier : EN_ATTENTE en premier, puis par date décroissante
        this.commandes = all
          .sort((a, b) => {
            if (a.statut === 'EN_ATTENTE' && b.statut !== 'EN_ATTENTE') return -1;
            if (a.statut !== 'EN_ATTENTE' && b.statut === 'EN_ATTENTE') return 1;
            return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
          })
          .slice(0, 8);
        this.commandesEnAttente = all.filter(c => c.statut === 'EN_ATTENTE').length;
        this.isLoading = false;
      },
      error: () => (this.isLoading = false)
    });
  }

  getBadgeColor(status: string): 'success' | 'warning' | 'error' | 'primary' {
    const map: Record<string, 'success' | 'warning' | 'error' | 'primary'> = {
      LIVREE: 'success', CONFIRMEE: 'primary', EN_LIVRAISON: 'primary', ANNULEE: 'error', EN_ATTENTE: 'warning',
    };
    return map[status] ?? 'error';
  }

  getStatutLabel(status: string): string {
    const labels: Record<string, string> = {
      EN_ATTENTE: 'En attente', CONFIRMEE: 'Confirmée', EN_LIVRAISON: 'En livraison', LIVREE: 'Livrée', ANNULEE: 'Annulée',
    };
    return labels[status] ?? status;
  }

  encode(id: any): string { return btoa(String(id)); }

  calculCommission(commande: any): number {
    return (commande.lignes ?? []).reduce((total: number, lp: any) => {
      return total + (lp.prixUnitaire * lp.quantite * (lp.produit?.boutique?.commission ?? 0)) / 100;
    }, 0);
  }
}
