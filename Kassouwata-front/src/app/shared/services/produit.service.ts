import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Produit } from '../models/produit.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class ProduitService {
  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosProduits";

  getAllProduits(page?: number, size?: number): Observable<any> {
    return this.http.get<any[]>(this.API_URL + '/list');
  }


  //delete any
  deleteProduit(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveProduit(Produit:Produit):Observable<Produit>{
      return this.http.post<Produit>(this.API_URL+"/save",Produit);
  }

  //get any
    getProduit(id:number):Observable<Produit>{
    return this.http.get<Produit>(this.API_URL+"/"+id);
  }

  //update any
  updateProduit(id:number, newProduit:Produit):Observable<Produit>{
    return this.http.put<Produit>(this.API_URL+"/update/"+id, newProduit);
  }

  resetPassword(idProduit: number, newPassword: string) {
    return this.http.put<Produit>(this.API_URL+"/resetPaswword/"+idProduit, newPassword);
  }

  getProduitsByBoutiqueId(idBoutique: number):Observable<Produit[]>{
    return this.http.get<Produit[]>(this.API_URL+ "/getByBoutiqueId/"+idBoutique);
  }
}