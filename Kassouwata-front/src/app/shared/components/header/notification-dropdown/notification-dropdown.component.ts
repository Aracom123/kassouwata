import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { DropdownComponent } from '../../ui/dropdown/dropdown.component';
import { DropdownItemComponent } from '../../ui/dropdown/dropdown-item/dropdown-item.component';
import { CommandeService } from '../../../services/commande.service';

@Component({
  selector: 'app-notification-dropdown',
  templateUrl: './notification-dropdown.component.html',
  imports:[CommonModule,RouterModule,DropdownComponent,DropdownItemComponent]
})
export class NotificationDropdownComponent implements OnInit {
  isOpen = false;
  notifying = true;

  commandes: any[] = [];
    isLoading = true;
    commandesEnAttente : any[] = [];
  
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
          this.commandesEnAttente = all.filter(c => c.statut === 'EN_ATTENTE');
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

  toggleDropdown() {
    this.isOpen = !this.isOpen;
    this.notifying = false;
  }

  closeDropdown() {
    this.isOpen = false;
  }
}