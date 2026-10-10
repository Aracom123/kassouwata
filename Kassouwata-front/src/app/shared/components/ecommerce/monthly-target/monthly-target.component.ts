import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import {
  ApexNonAxisChartSeries,
  ApexChart,
  ApexPlotOptions,
  ApexFill,
  NgApexchartsModule,
} from 'ng-apexcharts';
import { DashboardService } from '../../../services/dashboard.service';

@Component({
  selector: 'app-monthly-target',
  imports: [NgApexchartsModule, CommonModule, RouterLink],
  templateUrl: './monthly-target.component.html',
})
export class MonthlyTargetComponent implements OnInit {

  indicateurs: any = null;

  // Graphique donut statuts
  public donutSeries: ApexNonAxisChartSeries = [];
  public donutChart: ApexChart = {
    fontFamily: 'Outfit, sans-serif',
    type: 'donut',
    height: 200,
    sparkline: { enabled: false },
    toolbar: { show: false },
  };
  public donutLabels: string[] = ['En attente', 'Confirmée', 'En livraison', 'Livrée', 'Annulée'];
  public donutColors: string[] = ['#F59E0B', '#465FFF', '#8B5CF6', '#10B981', '#EF4444'];
  public donutFill: ApexFill = { type: 'solid' };
  public donutPlotOptions: ApexPlotOptions = {
    pie: {
      donut: {
        size: '65%',
        labels: {
          show: true,
          total: {
            show: true,
            label: 'Total',
            fontSize: '13px',
            color: '#6B7280',
          }
        }
      }
    }
  };

  // Stats par statut
  statutStats: { label: string; value: number; color: string; key: string }[] = [
    { label: 'En attente',   value: 0, color: 'bg-warning-400', key: 'EN_ATTENTE' },
    { label: 'Confirmée',    value: 0, color: 'bg-brand-500',   key: 'CONFIRMEE' },
    { label: 'En livraison', value: 0, color: 'bg-purple-500',  key: 'EN_LIVRAISON' },
    { label: 'Livrée',       value: 0, color: 'bg-success-500', key: 'LIVREE' },
    { label: 'Annulée',      value: 0, color: 'bg-error-500',   key: 'ANNULEE' },
  ];

  totalCommandes = 0;

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadIndicateurs();
  }

  loadIndicateurs(): void {
    this.dashboardService.getIndicateurs().subscribe({
      next: data => {
        this.indicateurs = data;
        this.buildStatuts(data);
      },
      error: err => console.error(err)
    });
  }

  private buildStatuts(data: any): void {
    const statsMap: Record<string, number> = {
      EN_ATTENTE:   data.commandesEnAttente    ?? 0,
      CONFIRMEE:    data.commandesConfirmees   ?? 0,
      EN_LIVRAISON: data.commandesEnLivraison  ?? 0,
      LIVREE:       data.commandesLivrees      ?? 0,
      ANNULEE:      data.commandesAnnulees     ?? 0,
    };

    this.statutStats = this.statutStats.map(s => ({
      ...s,
      value: statsMap[s.key] ?? 0,
    }));

    this.totalCommandes = this.statutStats.reduce((sum, s) => sum + s.value, 0);

    // Séries pour le donut (même ordre que donutLabels)
    this.donutSeries = [
      statsMap['EN_ATTENTE'],
      statsMap['CONFIRMEE'],
      statsMap['EN_LIVRAISON'],
      statsMap['LIVREE'],
      statsMap['ANNULEE'],
    ];
  }

  getPercent(value: number): number {
    if (this.totalCommandes === 0) return 0;
    return Math.round((value / this.totalCommandes) * 100);
  }
}
