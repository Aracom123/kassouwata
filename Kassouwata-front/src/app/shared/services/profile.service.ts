import { Injectable } from '@angular/core';
import { Profile } from '../models/profile.model';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root',
})
export class ProfileService {
  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosProfiles";

  getAllProfiles(page:number, size:number):Observable<any>{
    return this.http.get<Profile>(this.API_URL+ "/list?page="+page+"&size="+size);
  }


  //delete any
  deleteProfile(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/delete/"+id);
  }
  
  
  //save any method
  saveProfile(Profile:Profile):Observable<Profile>{
      return this.http.post<Profile>(this.API_URL+"/save",Profile);
  }

  //get any
    getProfile(id:number):Observable<Profile>{
    return this.http.get<Profile>(this.API_URL+"/"+id);
  }

  //update any
  updateProfile(id:number, newProfile:Profile):Observable<Profile>{
    return this.http.put<Profile>(this.API_URL+"/update/"+id, newProfile);
  }

  resetPassword(idProfile: number, newPassword: string) {
    return this.http.put<Profile>(this.API_URL+"/resetPaswword/"+idProfile, newPassword);
  }
}
