import { environment } from '../../../environments/environment';
import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { TranslateModule } from '@ngx-translate/core';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, TranslateModule, RouterModule],
  templateUrl: './login.html',
  styleUrls: ['./login.css'],
})
export class LoginComponent implements OnInit {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private http = inject(HttpClient);

  loginForm!: FormGroup;
  errorMessage = '';
  successMessage = '';
  loading = false;
  tenantBranding: any = null;
  showPassword = false;

  // Multi-Tenant selection state
  tenants: any[] = [];
  selectedTenant: any = null;
  selectedTenantCode = '';
  loadingTenants = false;

  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  ngOnInit(): void {
    // Clear any previous active auth token when visiting login
    this.authService.clearSession();
    this.initForm();
    this.loadPublicTenants();
  }

  initForm(): void {
    this.loginForm = this.fb.group({
      login: ['', [Validators.required, Validators.minLength(3)]], // Username or Email
      password: ['', [Validators.required, Validators.minLength(4)]],
    });
  }

  loadPublicTenants(): void {
    this.loadingTenants = true;
    this.http.get<any[]>(`${environment.apiUrl}/tenants/public-list`).subscribe({
      next: (list) => {
        this.loadingTenants = false;
        this.tenants = list || [];

        const savedCode = localStorage.getItem('selected_tenant_code');
        if (savedCode && this.tenants.some(t => t.tenant_code === savedCode)) {
          this.onTenantChange(savedCode);
        } else if (this.tenants.length > 0) {
          // Pre-select first institution to immediately show logo & branding
          this.onTenantChange(this.tenants[0].tenant_code);
        }
      },
      error: () => {
        this.loadingTenants = false;
      }
    });
  }

  onTenantChange(code: string): void {
    this.selectedTenantCode = code || '';
    if (!code) {
      this.selectedTenant = null;
      this.resetBranding();
      localStorage.removeItem('selected_tenant_code');
      return;
    }

    const found = this.tenants.find(t => t.tenant_code === code);
    if (found) {
      this.selectedTenant = found;
      localStorage.setItem('selected_tenant_code', found.tenant_code);
      this.applyBranding({
        tenant_name: found.tenant_name,
        logo_url: found.logo_path,
        primary_color: found.primary_color || '#7c3aed',
        secondary_color: found.secondary_color || '#db2777'
      });
    }
  }

  getInitials(name?: string): string {
    if (!name) return 'LP';
    const words = name.trim().split(/\s+/);
    if (words.length >= 2) {
      return (words[0][0] + words[1][0] + (words[2] ? words[2][0] : '')).toUpperCase();
    }
    return name.slice(0, 3).toUpperCase();
  }

  getLogoBadgeBackground(): string {
    if (this.selectedTenant?.primary_color && this.selectedTenant?.secondary_color) {
      return `linear-gradient(135deg, ${this.selectedTenant.primary_color} 0%, ${this.selectedTenant.secondary_color} 100%)`;
    }
    return 'linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%)';
  }

  fetchBranding(code: string): void {
    if (!code) return;

    this.http.get<any>(`${environment.apiUrl}/tenants/brand/${code}`).subscribe({
      next: (brand) => {
        this.tenantBranding = brand;
        this.applyBranding(brand);
      },
      error: () => {
        this.resetBranding();
      }
    });
  }

  applyBranding(brand: any): void {
    const root = document.documentElement;
    if (brand.primary_color) {
      root.style.setProperty('--primary-color', brand.primary_color);
      root.style.setProperty('--tenant-primary', brand.primary_color);
    }
    if (brand.secondary_color) {
      root.style.setProperty('--secondary-color', brand.secondary_color);
      root.style.setProperty('--tenant-secondary', brand.secondary_color);
    }
    localStorage.setItem('tenant_branding', JSON.stringify(brand));
    if (this.selectedTenantCode) {
      localStorage.setItem('tenant_code', this.selectedTenantCode);
    }
  }

  resetBranding(): void {
    this.tenantBranding = null;
    const root = document.documentElement;
    root.style.removeProperty('--primary-color');
    root.style.removeProperty('--secondary-color');
    root.style.removeProperty('--tenant-primary');
    root.style.removeProperty('--tenant-secondary');
    localStorage.removeItem('tenant_branding');
    localStorage.removeItem('tenant_code');
  }

  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.loading = true;
    this.errorMessage = '';
    this.successMessage = '';

    const credentials = {
      ...this.loginForm.value,
      tenant_code: this.selectedTenantCode || undefined,
    };

    this.authService.login(credentials).subscribe({
      next: (response) => {
        this.loading = false;
        this.successMessage = 'Login successful! Redirecting...';

        const role = response.user.role;
        const finalTenantCode = response.tenant_code || this.selectedTenantCode;

        if (finalTenantCode) {
          localStorage.setItem('tenant_code', finalTenantCode);
          this.fetchBranding(finalTenantCode);
        }

        // Redirect dynamically based on the user's role
        if (role === 'student') {
          this.router.navigate(['/learn']); // Student workspace
        } else if (role === 'super_admin') {
          this.router.navigate(['/tenants']); // Super Admin workspace
        } else if (role === 'admin' || role === 'staff') {
          this.router.navigate(['/admin-dashboard']); // Admin dashboard
        } else {
          this.router.navigate(['/learn']);
        }
      },
      error: (err) => {
        this.loading = false;
        const errors = err.error?.errors;
        if (errors) {
          let hasSpecificError = false;
          if (errors.login) {
            this.loginForm.get('login')?.setErrors({ serverError: errors.login[0] });
            hasSpecificError = true;
          }
          if (errors.password) {
            this.loginForm.get('password')?.setErrors({ serverError: errors.password[0] });
            hasSpecificError = true;
          }
          
          if (!hasSpecificError) {
             this.errorMessage = 'Authentication failed. Please verify credentials.';
          }
        } else {
          this.errorMessage = err.error?.message || 'Authentication failed. Please verify credentials.';
        }
      },
    });
  }
}
