import { Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { User } from '../models/user.model';

@Injectable({
  providedIn: 'root',
})
export class UsersService {

  constructor(
    private http: HttpClient
  ){ }
   private readonly API_URL = environment.backendBaseUrl+"/nosUsers";

  getAllUsers(page:number=0, size:number=200):Observable<any>{
    return this.http.get<User>(this.API_URL+ "/list?page="+page+"&size="+size);
  }

  getAllVendeurs():Observable<any>{
    return this.http.get<User>(this.API_URL+ "/getByProfileId/"+2);
  }


  //delete any
  deleteUser(id:number):Observable<void>{
    return this.http.delete<void>(this.API_URL+"/"+id);
  }
  
  
  //save any method
  saveUser(user:User):Observable<User>{
      return this.http.post<User>(this.API_URL+"/save",user);
  }

  //get any
    getUser(id:number):Observable<User>{
    return this.http.get<User>(this.API_URL+"/"+id);
  }

  //update any
  updateUser(id:number, newUser:User):Observable<User>{
    return this.http.put<User>(this.API_URL+"/update/"+id, newUser);
  }

  resetPassword(idUser: number, newPassword: string) {
    return this.http.put<User>(this.API_URL+"/resetPaswword/"+idUser, newPassword);
  }
}
