import { Component, inject, signal } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Auth } from '../../../core/services/auth';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CommonModule } from '@angular/common';
import { getValidationMessage } from '../../../core/validators/form.validators';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(Auth);
  private readonly router = inject(Router);
  
  // Modern signals for reactive state
  readonly errorMessage = signal<string>('');
  readonly isLoading = this.authService.isLoading;
  
  // Reactive form with validation
  readonly loginForm: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });
  
  /**
   * Handle login form submission
   */
  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }
    
    this.errorMessage.set('');
    
    this.authService.login(this.loginForm.value).subscribe({
      next: () => {
        // Redirect based on user role
        if (this.authService.isSeller()) {
          this.router.navigate(['/seller/dashboard']);
        } else {
          this.router.navigate(['/products']);
        }
      },
      error: (error) => {
        console.error('Login error:', error);
        this.errorMessage.set(error.error?.message || 'Login failed. Please check your credentials.');
      }
    });
  }
  
  /**
   * Get form control error message
   */
  getErrorMessage(controlName: string): string {
    const control = this.loginForm.get(controlName);
    
    if (!control?.errors) {
      return '';
    }
    
    return getValidationMessage(control.errors, controlName);
  }
}

