import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  NgApexchartsModule,
  ApexAxisChartSeries,
  ApexChart,
  ApexXAxis,
  ApexPlotOptions,
  ApexDataLabels,
  ApexStroke,
  ApexLegend,
  ApexYAxis,
  ApexGrid,
  ApexFill,
  ApexTooltip,
} from 'ng-apexcharts';
import { DashboardService } from '../../../services/dashboard.service';

@Component({
  selector: 'app-monthly-sales-chart',
  standalone: true,
  imports: [NgApexchartsModule, CommonModule],
  templateUrl: './monthly-sales-chart.component.html'
})
export class MonthlySalesChartComponent implements OnInit {

  readonly mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

  public series: ApexAxisChartSeries = [
    { name: "Chiffre d'affaires", data: Array(12).fill(0) },
    { name: 'Commissions',        data: Array(12).fill(0) },
  ];

  public chart: ApexChart = {
    fontFamily: 'Outfit, sans-serif',
    type: 'bar',
    height: 220,
    toolbar: { show: false },
    stacked: false,
  };

  public xaxis: ApexXAxis = {
    categories: this.mois,
    axisBorder: { show: false },
    axisTicks: { show: false },
    labels: { style: { fontSize: '11px' } },
  };

  public plotOptions: ApexPlotOptions = {
    bar: { horizontal: false, columnWidth: '50%', borderRadius: 4, borderRadiusApplication: 'end' },
  };

  public dataLabels: ApexDataLabels = { enabled: false };

  public stroke: ApexStroke = { show: true, width: 3, colors: ['transparent'] };

  public legend: ApexLegend = {
    show: true, position: 'top', horizontalAlign: 'left', fontFamily: 'Outfit', fontSize: '12px',
  };

  public yaxis: ApexYAxis = {
    labels: {
      formatter: (val: number) => val >= 1000 ? (val / 1000).toFixed(0) + 'k' : String(val),
      style: { fontSize: '11px' },
    }
  };

  public grid: ApexGrid = { yaxis: { lines: { show: true } }, borderColor: '#F3F4F6' };

  public fill: ApexFill = { opacity: 1 };

  public tooltip: ApexTooltip = {
    x: { show: false },
    y: { formatter: (val: number) => val.toLocaleString('fr-FR') + ' FCFA' },
  };

  public colors: string[] = ['#465fff', '#10B981'];

  isLoading = true;

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadEvolution();
  }

  loadEvolution(): void {
    this.dashboardService.getIndicateurs().subscribe({
      next: (data: any) => {
        // Tente de lire l'évolution mensuelle si fournie par le backend
        const evolution: any[] = data.evolutionMensuelle ?? [];
        if (evolution.length > 0) {
          const ca     = Array(12).fill(0);
          const comms  = Array(12).fill(0);
          evolution.forEach((item: any) => {
            const idx = (item.mois ?? 1) - 1;
            if (idx >= 0 && idx < 12) {
              ca[idx]    = item.chiffreAffaires ?? item.ca ?? 0;
              comms[idx] = item.commissions ?? 0;
            }
          });
          this.series = [
            { name: "Chiffre d'affaires", data: ca },
            { name: 'Commissions',        data: comms },
          ];
        }
        this.isLoading = false;
      },
      error: () => { this.isLoading = false; }
    });
  }
}
