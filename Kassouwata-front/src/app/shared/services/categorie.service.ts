import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Categorie } from '../models/categorie.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class CategorieService {
  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosCategories";

  getAllCategories(page:number, size:number):Observable<any>{
    return this.http.get<Categorie>(this.API_URL+ "/list?page="+page+"&size="+size);
  }


  //delete any
  deleteCategorie(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveCategorie(Categorie:Categorie):Observable<Categorie>{
      return this.http.post<Categorie>(this.API_URL+"/save",Categorie);
  }

  //get any
    getCategorie(id:number):Observable<Categorie>{
    return this.http.get<Categorie>(this.API_URL+"/"+id);
  }

  //update any
  updateCategorie(id:number, newCategorie:Categorie):Observable<Categorie>{
    return this.http.put<Categorie>(this.API_URL+"/update/"+id, newCategorie);
  }

  resetPassword(idCategorie: number, newPassword: string) {
    return this.http.put<Categorie>(this.API_URL+"/resetPaswword/"+idCategorie, newPassword);
  }
}