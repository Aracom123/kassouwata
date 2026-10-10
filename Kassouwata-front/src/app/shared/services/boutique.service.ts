import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Boutique } from '../models/boutique.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class BoutiqueService {
  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosBoutiques";

  getAllBoutiques(page:number, size:number):Observable<any>{
    return this.http.get<Boutique>(this.API_URL+ "/list?page="+page+"&size="+size);
  }


  //delete any
  deleteBoutique(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveBoutique(Boutique:Boutique):Observable<Boutique>{
      return this.http.post<Boutique>(this.API_URL+"/save",Boutique);
  }

  //get any
  getBoutique(id:number):Observable<Boutique>{
    return this.http.get<Boutique>(this.API_URL+"/"+id);
  }

  //update any
  updateBoutique(id:number, newBoutique:Boutique):Observable<Boutique>{
    return this.http.put<Boutique>(this.API_URL+"/update/"+id, newBoutique);
  }

  // stats détaillées d'une boutique
  getStatsBoutique(id: number): Observable<any> {
    return this.http.get<any>(this.API_URL + '/' + id + '/stats');
  }
}
