import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Commande } from '../models/commande.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export type StatutCommande = 'EN_ATTENTE' | 'CONFIRMEE' | 'EN_LIVRAISON' | 'LIVREE' | 'ANNULEE';

@Injectable({
  providedIn: 'root',
})
export class CommandeService {
  constructor(
    private http: HttpClient
  ){ }
  private readonly API_URL = environment.backendBaseUrl + "/nosCommandes";

  /** Récupère toutes les commandes (backend retourne List<Commande>) */
  getAllCommandes(): Observable<any[]> {
    return this.http.get<any[]>(this.API_URL + "/list");
  }

  /** Recherche et filtrage des commandes — le backend retourne List<Commande> */
  searchCommandes(statut?: string, search?: string): Observable<any[]> {
    let params = new HttpParams();
    if (statut) params = params.set('statut', statut);
    if (search) params = params.set('search', search);
    return this.http.get<any[]>(this.API_URL + "/list", { params });
  }

  /** Récupère le détail d'une commande */
  getCommande(id: number): Observable<any> {
    return this.http.get<any>(this.API_URL + "/" + id);
  }

  /** Sauvegarde une nouvelle commande */
  saveCommande(commande: Commande): Observable<Commande> {
    return this.http.post<Commande>(this.API_URL + "/save", commande);
  }

  /** Mise à jour globale d'une commande */
  updateCommande(id: number, newCommande: any): Observable<Commande> {
    return this.http.put<Commande>(this.API_URL + "/update/" + id, newCommande);
  }

  /** Changement de statut d'une commande */
  updateStatut(id: number, statut: StatutCommande): Observable<any> {
    return this.http.put<any>(this.API_URL + "/updateStatut/" + id, { statut });
  }

  /** Confirmer une commande (EN_ATTENTE → CONFIRMEE) */
  confirmerCommande(id: number): Observable<any> {
    return this.http.put<any>(this.API_URL + "/confirmer/" + id, {});
  }

  /** Mettre en livraison (CONFIRMEE → EN_LIVRAISON) */
  mettreEnLivraison(id: number): Observable<any> {
    return this.http.put<any>(this.API_URL + "/enLivraison/" + id, {});
  }

  /** Marquer comme livrée (EN_LIVRAISON → LIVREE) */
  marquerLivree(id: number): Observable<any> {
    return this.http.put<any>(this.API_URL + "/livrer/" + id, {});
  }

  /** Annuler une commande */
  annulerCommande(id: number): Observable<any> {
    return this.http.put<any>(this.API_URL + "/annuler/" + id, {});
  }

  /** Supprimer une commande */
  deleteCommande(id: number): Observable<void> {
    return this.http.delete<void>(this.API_URL + "/delete/" + id);
  }
}
