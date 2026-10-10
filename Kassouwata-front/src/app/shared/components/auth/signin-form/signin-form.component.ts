
import { Component } from '@angular/core';
import { LabelComponent } from '../../form/label/label.component';
import { CheckboxComponent } from '../../form/input/checkbox.component';
import { ButtonComponent } from '../../ui/button/button.component';
import { InputFieldComponent } from '../../form/input/input-field.component';
import { Router, RouterModule } from '@angular/router';
import { FormBuilder, Validators, ReactiveFormsModule, FormGroup } from '@angular/forms';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-signin-form',
  imports: [
    LabelComponent,
    CheckboxComponent,
    ButtonComponent,
    InputFieldComponent,
    RouterModule,
    ReactiveFormsModule
],
  templateUrl: './signin-form.component.html',
  styles: ``
})
export class SigninFormComponent {

  loginForm!: FormGroup;
  loading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      login: ['', Validators.required],
      password: ['', Validators.required]
    });
  }

  onSubmit(): void {
    // console.log(this.loginForm.value);   
    if (this.loginForm.invalid) return;

    this.loading = true;
    this.errorMessage = '';

    const { login, password } = this.loginForm.value;

    this.authService.login(login, password).subscribe({
      next: (user) => {
        // console.log('Utilisateur connecté :', user);
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.errorMessage = 'Téléphone ou mot de passe incorrect';
        this.loading = false;
      }
    });
  }

  showPassword = false;
  isChecked = false;

  // email = '';
  // password = '';

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

  // onSignIn() {
  //   console.log('Email:', this.email);
  //   console.log('Password:', this.password);
  //   console.log('Remember Me:', this.isChecked);
  // }
}
