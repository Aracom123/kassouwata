import { Routes } from '@angular/router';
import { BoutiquesComponent } from './boutique.component';
import { BoutiqueViewComponent } from './boutique-view/boutique-view.component';

export const BOUTIQUES_ROUTES: Routes = [
  {
    path: '',
    component: BoutiquesComponent
  },
  {
    path: ':id',
    component: BoutiqueViewComponent
  }
];