import { Component, OnInit } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { DashboardService } from '../../../services/dashboard.service';

@Component({
  selector: 'app-ecommerce-metrics',
  imports: [DecimalPipe],
  templateUrl: './ecommerce-metrics.component.html'
})
export class EcommerceMetricsComponent implements OnInit {

  indicateurs: any = null;

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadIndicateurs();
  }

  loadIndicateurs(): void {
    this.dashboardService.getIndicateurs().subscribe({
      next: data => { this.indicateurs = data; },
      error: err => console.error(err)
    });
  }

  /** Taux commission moyen = commissions / CA * 100 */
  get tauxCommission(): number {
    if (!this.indicateurs?.chiffresAffaires || this.indicateurs.chiffresAffaires === 0) return 0;
    return Math.round((this.indicateurs.totalCommissions / this.indicateurs.chiffresAffaires) * 100);
  }

  /** Taux livraison : utilise la valeur précalculée par le backend, sinon calcul local */
  get tauxLivraison(): number {
    if (this.indicateurs?.tauxLivraison != null) return this.indicateurs.tauxLivraison;
    const total = this.indicateurs?.nombreVentes ?? 0;
    const livrees = this.indicateurs?.commandesLivrees ?? 0;
    if (total === 0) return 0;
    return Math.round((livrees / total) * 100);
  }
}
