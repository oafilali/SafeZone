import { Component, inject, signal, computed } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Auth } from '../../../core/services/auth';
import { NotificationService } from '../../../core/services/notification.service';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { CommonModule } from '@angular/common';
import { matchValidator, getValidationMessage } from '../../../core/validators/form.validators';
import { validateFile, ValidationPresets } from '../../../core/validators/file-upload.validator';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatSelectModule,
    MatProgressSpinnerModule,
    MatIconModule,
    MatTooltipModule
  ],
  templateUrl: './register.html',
  styleUrl: './register.css',
})
export class Register {
  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(Auth);
  private readonly router = inject(Router);
  private readonly notification = inject(NotificationService);
  
  // Modern signals for avatar upload
  readonly errorMessage = signal<string>('');
  readonly isLoading = this.authService.isLoading;
  readonly selectedFile = signal<File | null>(null);
  readonly imagePreview = signal<string | null>(null);
  readonly uploadError = signal<string>('');
  
  // Computed signal - show avatar upload only for sellers
  readonly showAvatarUpload = computed(() => {
    return this.registerForm.get('role')?.value === 'SELLER';
  });
  
  // Reactive form
  readonly registerForm: FormGroup = this.fb.group({
    name: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(50)]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    confirmPassword: ['', [Validators.required]],
    role: ['CLIENT', [Validators.required]]
  }, {
    validators: matchValidator('password', 'confirmPassword')
  });
  
  /**
   * Handle file selection with validation
   */
  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    
    // Reset previous state
    this.uploadError.set('');
    this.selectedFile.set(null);
    this.imagePreview.set(null);
    
    if (!file) {
      return;
    }
    
    // Validate file using ValidationPresets
    const validationResult = validateFile(file, ValidationPresets.AVATAR);
    
    if (!validationResult.valid) {
      this.uploadError.set(validationResult.errors[0]);
      return;
    }
    
    // Set selected file
    this.selectedFile.set(file);
    
    // Generate preview
    const reader = new FileReader();
    reader.onload = (e) => {
      this.imagePreview.set(e.target?.result as string);
    };
    reader.readAsDataURL(file);
  }
  
  /**
   * Remove selected avatar
   */
  removeAvatar(): void {
    this.selectedFile.set(null);
    this.imagePreview.set(null);
    this.uploadError.set('');
    
    // Reset file input
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement;
    if (fileInput) {
      fileInput.value = '';
    }
  }
  
  /**
   * Handle register form submission
   */
  onSubmit(): void {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      return;
    }
    
    this.errorMessage.set('');
    
    const { confirmPassword, ...registerData } = this.registerForm.value;
    
    // Add avatar URL if file is selected (for now, we'll use a placeholder)
    // In production, you would upload to a server first and get back a URL
    if (this.selectedFile()) {
      // For now, use the base64 preview as avatarUrl
      // In production: upload file first, then use the returned URL
      registerData.avatarUrl = this.imagePreview();
    }
    
    this.authService.register(registerData).subscribe({
      next: () => {
        // Show success message
        this.notification.success('Registration successful! Please log in with your credentials.');
        
        // Redirect to login page
        this.router.navigate(['/auth/login']);
      },
      error: (error) => {
        console.error('Registration error:', error);
        this.errorMessage.set(error.error?.message || 'Registration failed. Please try again.');
      }
    });
  }
  
  /**
   * Get form control error message
   */
  getErrorMessage(controlName: string): string {
    const control = this.registerForm.get(controlName);
    
    if (!control?.errors) {
      return '';
    }
    
    return getValidationMessage(control.errors, controlName);
  }
}

