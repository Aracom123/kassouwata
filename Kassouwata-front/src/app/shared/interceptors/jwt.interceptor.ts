import { HttpInterceptorFn } from '@angular/common/http';
import { AuthService } from '../services/auth.service';
import { inject } from '@angular/core';
import { Router } from '@angular/router';

import { catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
    const router = inject(Router);

  // 🔹 URLs publiques (sans JWT)
  const publicUrls = [
    '/api/authenticate'
  ];

  // 🔹 Vérifier si la requête est publique
  const isPublic = publicUrls.some(url => req.url.includes(url));

  
  if (isPublic) {
    return next(req); // 🚀 on ne touche pas au header
  }

  const token = authService.getToken();

  const authReq = token
    ? req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      })
    : req;

  return next(authReq).pipe(
    catchError(err => {
      // 401 = token invalide / expiré → déconnecter
      // 403 = droits insuffisants → NE PAS déconnecter (évite la boucle post-login)
      if (err.status === 401) {
        authService.logout();
        router.navigate(['/signin']);
      }
      return throwError(() => err);
    })
  );
};