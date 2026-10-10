import { Routes } from '@angular/router';
import { TontineComponent } from './tontine.component';
import { TontineViewComponent } from './tontine-view/tontine-view.component';

export const TONTINES_ROUTES: Routes = [
  {
    path: '',
    component: TontineComponent,
    title: 'Tontines | Kassouwata',
  },
  {
    path: ':id',
    component: TontineViewComponent,
    title: 'Détail tontine | Kassouwata',
  }
];
