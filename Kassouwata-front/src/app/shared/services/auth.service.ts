import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { AuthRequest } from '../models/auth-request.model';

import { jwtDecode } from 'jwt-decode';
import { environment } from '../../../environments/environment';

export interface UserSession {
  token: string;
  id: number;
  nom: string;
  prenom: string;
  telephone: string;
  email?: string;
}

interface JwtPayload {
  exp: number;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private apiUrl = environment.backendBaseUrl+"/authenticate";
  private userData = 'access_token';

  private currentUserSubject = new BehaviorSubject<any>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    // Si token + user sont dans le localStorage au démarrage, on les remet dans le BehaviorSubject
    const session = localStorage.getItem('userSession');
    if (session) {
      this.currentUserSubject.next(JSON.parse(session));
    }
  }

  login(login: string, password: string): Observable<UserSession> {
    return this.http.post<UserSession>(`${this.apiUrl}`, { login, password })
      .pipe(
        tap(user => {
          // Stocker dans localStorage pour persistance
          localStorage.setItem('userSession', JSON.stringify(user));
          this.currentUserSubject.next(user);
        })
      );
  }

  logout() {
    localStorage.removeItem('userSession');
    this.currentUserSubject.next(null);
  }

  getToken(): string | null {
    // Lecture depuis le BehaviorSubject en priorité
    const current = this.currentUserSubject.value;
    if (current?.token) return current.token;

    // Fallback : lire directement depuis localStorage (cas post-navigation immédiate)
    try {
      const session = localStorage.getItem('userSession');
      if (session) {
        const parsed = JSON.parse(session);
        // Réhydrater le BehaviorSubject si vide
        if (parsed?.token) {
          this.currentUserSubject.next(parsed);
          return parsed.token;
        }
      }
    } catch {
      // localStorage inaccessible (SSR, incognito strict, etc.)
    }
    return null;
  }

  getCurrentUser(): UserSession | null {
    return this.currentUserSubject.value;
  }

  isAuthenticated(): boolean {
    return !!this.getToken() && !this.isTokenExpired();
  }

  isTokenExpired(): boolean {
    const token = this.getToken();
    if (!token) return true;

    try {
      const decoded = jwtDecode<JwtPayload>(token);
      const now = Date.now() / 1000;
      return decoded.exp < now;
    } catch {
      return true;
    }
  }

  // login(data: AuthRequest): Observable<any> {
  //   return this.http.post<any>(`${this.apiUrl}`, data).pipe(
  //     tap(response => {
  //       // console.log(response);

  //       localStorage.setItem(this.userData, response);
  //       this.currentUserSubject.next(response);
  //     })
  //   );
  // }

  // logout(): void {
  //   localStorage.removeItem(this.userData);
  //   this.currentUserSubject.next(null);
  // }

  // getUserData(): string | null {
  //   return localStorage.getItem(this.userData);
  // }

  // getToken(): string | null {
  //   const userData = this.getUserData();
  //   if (!userData) return null;

  //   try {
  //     const payload = JSON.parse(atob(userData.split('.')[1]));
  //     return payload.token;
  //   } catch (e) {
  //     console.error('Erreur décodage JWT', e);
  //     return null;
  //   }
  //   return localStorage.getItem(this.userData);
  // }

  // isAuthenticated(): boolean {
  //   return !!this.getUserData();
  // }

  // getUserName(): { nom: string; prenom: string } | null {
  //   const token = this.getUserData();
  //   if (!token) return null;

  //   try {
  //     const payload = JSON.parse(atob(token.split('.')[1]));
  //     return { nom: payload.nom, prenom: payload.prenom };
  //   } catch (e) {
  //     console.error('Erreur décodage JWT', e);
  //     return null;
  //   }
  // }
}