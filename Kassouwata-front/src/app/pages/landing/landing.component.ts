import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './landing.component.html',
})
export class LandingComponent {
  readonly vendorApkUrl = '#';   // TODO : remplacer par l'URL réelle de l'APK vendeur
  readonly clientApkUrl = '#';   // TODO : remplacer par l'URL réelle de l'APK client
  readonly currentYear = new Date().getFullYear();

  features = [
    {
      icon: 'store',
      title: 'Boutiques en ligne',
      description: 'Les vendeurs créent leur boutique, publient leurs produits et gèrent leurs stocks directement depuis leur téléphone.',
    },
    {
      icon: 'shopping_cart',
      title: 'Commandes simplifiées',
      description: 'Les clients parcourent le catalogue, passent commande et suivent leurs livraisons en temps réel.',
    },
    {
      icon: 'groups',
      title: 'Tontines numériques',
      description: 'Créez ou rejoignez des tontines, gérez les tours de passage et suivez les cotisations en toute transparence.',
    },
    {
      icon: 'verified_user',
      title: 'Sécurisé & fiable',
      description: 'Authentification sécurisée, données chiffrées et historique complet de toutes vos transactions.',
    },
  ];
}
