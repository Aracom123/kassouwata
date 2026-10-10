import { Routes } from '@angular/router';
import { EcommerceComponent } from './pages/dashboard/ecommerce/ecommerce.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { FormElementsComponent } from './pages/forms/form-elements/form-elements.component';
import { BasicTablesComponent } from './pages/tables/basic-tables/basic-tables.component';
import { BlankComponent } from './pages/blank/blank.component';
import { NotFoundComponent } from './pages/other-page/not-found/not-found.component';
import { AppLayoutComponent } from './shared/layout/app-layout/app-layout.component';
import { InvoicesComponent } from './pages/invoices/invoices.component';
import { LineChartComponent } from './pages/charts/line-chart/line-chart.component';
import { BarChartComponent } from './pages/charts/bar-chart/bar-chart.component';
import { AlertsComponent } from './pages/ui-elements/alerts/alerts.component';
import { AvatarElementComponent } from './pages/ui-elements/avatar-element/avatar-element.component';
import { BadgesComponent } from './pages/ui-elements/badges/badges.component';
import { ButtonsComponent } from './pages/ui-elements/buttons/buttons.component';
import { ImagesComponent } from './pages/ui-elements/images/images.component';
import { VideosComponent } from './pages/ui-elements/videos/videos.component';
import { SignInComponent } from './pages/auth-pages/sign-in/sign-in.component';
import { SignUpComponent } from './pages/auth-pages/sign-up/sign-up.component';
import { CalenderComponent } from './pages/calender/calender.component';
import { authGuard } from './shared/guards/auth.guard';
import { noAuthGuard } from './shared/guards/no-auth.guard';
import { UsersComponent } from './pages/users/users.component';
import { CategoriesComponent } from './pages/categorie/categorie.component';
import { TontineComponent } from './pages/tontine/tontine.component';
import { LandingComponent } from './pages/landing/landing.component';

export const routes: Routes = [
  // ── Landing page publique ────────────────────────────────────────
  {
    path: '',
    redirectTo: 'home',
    pathMatch: 'full',
  },
  {
    path: 'home',
    component: LandingComponent,
    title: 'Kassouwata — Commerce & Tontines',
  },
  // ── Backoffice (authentifié) ─────────────────────────────────────
  {
    path: '',
    component: AppLayoutComponent,
    canActivate: [authGuard],
    children: [
      {
        path: 'dashboard',
        component: EcommerceComponent,
        pathMatch: 'full',
        title:
          'Tableau de bord | Kassouwata',
      },
      {
        path: 'users',
        component: UsersComponent,
        title: 'Utilisateurs | Kassouwata',
      },
      {
        path: 'categories',
        component: CategoriesComponent,
        title: 'Catégories des produits | Kassouwata',
      },
      {
        path: 'commandes',
        loadChildren: () =>
          import('./pages/commande/commandes.routes').then(m => m.COMMANDES_ROUTES)
      },
      {
        path: 'boutiques',
        loadChildren: () =>
          import('./pages/boutique/boutiques.routes').then(m => m.BOUTIQUES_ROUTES)
      },
      {
        path: 'produits',
        loadChildren: () =>
          import('./pages/produit/produits.routes').then(m => m.PRODUITS_ROUTES)
      },
      {
        path: 'tontines',
        loadChildren: () =>
          import('./pages/tontine/tontines.routes').then(m => m.TONTINES_ROUTES)
      },
      {
        path: 'paiements',
        loadComponent: () =>
          import('./pages/paiement/paiement.component').then(m => m.PaiementComponent),
        title: 'Paiements | Kassouwata',
      },
      {
        path: 'moyens-paiement',
        loadComponent: () =>
          import('./pages/moyen-paiement/moyen-paiement.component').then(m => m.MoyenPaiementComponent),
        title: 'Moyens de paiement | Kassouwata',
      },
      {
        path: 'calendar',
        component: CalenderComponent,
        title: 'Angular Calender | Kassouwata',
      },
      {
        path: 'profile',
        component: ProfileComponent,
        title: 'Angular Profile Dashboard | Kassouwata'
      },
      {
        path: 'form-elements',
        component: FormElementsComponent,
        title: 'Angular Form Elements Dashboard | Kassouwata'
      },
      {
        path: 'basic-tables',
        component: BasicTablesComponent,
        title: 'Angular Basic Tables Dashboard | Kassouwata'
      },
      {
        path: 'blank',
        component: BlankComponent,
        title: 'Angular Blank Dashboard | Kassouwata'
      },
      // support tickets
      {
        path: 'invoice',
        component: InvoicesComponent,
        title: 'Angular Invoice Details Dashboard | Kassouwata'
      },
      {
        path: 'line-chart',
        component: LineChartComponent,
        title: 'Angular Line Chart Dashboard | Kassouwata'
      },
      {
        path: 'bar-chart',
        component: BarChartComponent,
        title: 'Angular Bar Chart Dashboard | Kassouwata'
      },
      {
        path: 'alerts',
        component: AlertsComponent,
        title: 'Angular Alerts Dashboard | Kassouwata'
      },
      {
        path: 'avatars',
        component: AvatarElementComponent,
        title: 'Angular Avatars Dashboard | Kassouwata'
      },
      {
        path: 'badge',
        component: BadgesComponent,
        title: 'Angular Badges Dashboard | Kassouwata'
      },
      {
        path: 'buttons',
        component: ButtonsComponent,
        title: 'Angular Buttons Dashboard | Kassouwata'
      },
      {
        path: 'images',
        component: ImagesComponent,
        title: 'Angular Images Dashboard | Kassouwata'
      },
      {
        path: 'videos',
        component: VideosComponent,
        title: 'Angular Videos Dashboard | Kassouwata'
      },
    ]
  },
  // auth pages
  {
    path: 'signin',
    canActivate: [noAuthGuard],
    component: SignInComponent,
    title: 'S\'authentifiez-vous | Kassouwata'
  },
  {
    path: 'signup',
    component: SignUpComponent,
    title: 'Angular Sign Up Dashboard | Kassouwata'
  },
  // error pages
  {
    path: '**',
    component: NotFoundComponent,
    title: 'Angular NotFound Dashboard | Kassouwata'
  },
];
