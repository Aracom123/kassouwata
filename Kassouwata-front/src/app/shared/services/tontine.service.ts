import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Tontine } from '../models/tontine.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class TontineService {
  constructor(
    private http: HttpClient
  ){ }
  
  private readonly API_URL = environment.backendBaseUrl+"/nosTontines";

  getAllTontines(page:number, size:number):Observable<any>{
    return this.http.get<Tontine>(this.API_URL+ "/list?page="+page+"&size="+size);
  }


  //delete any
  deleteTontine(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveTontine(Tontine:Tontine):Observable<Tontine>{
      return this.http.post<Tontine>(this.API_URL+"/save",Tontine);
  }

  //get any
    getTontine(id:number):Observable<Tontine>{
    return this.http.get<Tontine>(this.API_URL+"/"+id);
  }

  //update any
  updateTontine(id:number, newTontine:Tontine):Observable<Tontine>{
    return this.http.put<Tontine>(this.API_URL+"/update/"+id, newTontine);
  }

  getMembres(id: number): Observable<any[]> {
    return this.http.get<any[]>(this.API_URL + '/' + id + '/membres');
  }

  getPeriodes(id: number): Observable<any[]> {
    return this.http.get<any[]>(this.API_URL + '/' + id + '/periodes');
  }
}
