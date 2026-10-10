import { Routes } from '@angular/router';
import { CommandeComponent } from './commande.component';
import { CommandeViewComponent } from './commande-view/commande-view.component';

export const COMMANDES_ROUTES: Routes = [
  {
    path: '',
    component: CommandeComponent
  },
  {
    path: ':id',
    component: CommandeViewComponent
  }
];