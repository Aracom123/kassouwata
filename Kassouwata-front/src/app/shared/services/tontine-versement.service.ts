import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { TontineVersement } from '../models/tontine-versement.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class TontineVersementService {
  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosTontineVersements";

  getAllTontineVersements(page:number, size:number):Observable<any>{
    return this.http.get<TontineVersement>(this.API_URL+ "/list?page="+page+"&size="+size);
  }


  //delete any
  deleteTontineVersement(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveTontineVersement(TontineVersement:TontineVersement):Observable<TontineVersement>{
      return this.http.post<TontineVersement>(this.API_URL+"/save",TontineVersement);
  }

  //get any
    getTontineVersement(id:number):Observable<TontineVersement>{
    return this.http.get<TontineVersement>(this.API_URL+"/"+id);
  }

  //update any
  updateTontineVersement(id:number, newTontineVersement:TontineVersement):Observable<TontineVersement>{
    return this.http.put<TontineVersement>(this.API_URL+"/update/"+id, newTontineVersement);
  }

  getVersementsByPeriode(idPeriode: number): Observable<any[]> {
    return this.http.get<any[]>(
      environment.backendBaseUrl + '/nosTontinePeriodeVersements/' + idPeriode + '/versements'
    );
  }
}
