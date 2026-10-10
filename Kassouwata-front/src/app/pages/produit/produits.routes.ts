import { Routes } from '@angular/router';
import { ProduitComponent } from './produit.component';
import { ProduitViewComponent } from './produit-view/produit-view.component';

export const PRODUITS_ROUTES: Routes = [
  {
    path: '',
    component: ProduitComponent,
    title: 'Produits | Kassouwata',
  },
  {
    path: ':id',
    component: ProduitViewComponent,
    title: 'Détail produit | Kassouwata',
  }
];
