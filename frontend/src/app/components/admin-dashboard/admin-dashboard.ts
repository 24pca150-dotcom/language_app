import { environment } from '../../../environments/environment';
import { Component, OnInit, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../services/auth';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { NotificationService } from '../../services/notification.service';

export interface TenantStats {
  total_students: number;
  total_staff: number;
  active_courses: number;
  overall_completion_rate: number;
  active_today?: number;
  top_performers?: Array<{ id: number; name: string; username: string; xp: number; gems: number }>;
  recent_activities?: Array<{ user_name: string; action: string; title: string; time_ago: string; type: string }>;
  upcoming_live_classes?: Array<{ id: number; title: string; instructor_name: string; start_time: string; meeting_link: string; duration_minutes: number; status: string }>;
  recent_announcements?: Array<{ id: number; title: string; message: string; created_at: string }>;
  weekly_activity?: Array<{ day: string; count: number }>;
  skill_breakdown?: Array<{ skill: string; percentage: number; color: string }>;
  super_admin_data?: {
    total_tenants: number;
    tenants_list: Array<{ id: number; tenant_name: string; tenant_code: string; email: string; is_active: boolean; students_count: number; staff_count: number; created_at: string }>;
    total_packages: number;
    total_properties: number;
  };
}

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './admin-dashboard.html',
  styleUrls: ['./admin-dashboard.css']
})
export class AdminDashboardComponent implements OnInit {
  private http = inject(HttpClient);
  protected authService = inject(AuthService);
  private fb = inject(FormBuilder);
  private notificationService = inject(NotificationService);

  stats = signal<TenantStats | null>(null);
  loading = signal<boolean>(true);
  error = signal<string | null>(null);

  // Tenant Filtering for Super Admin
  selectedTenantFilter = signal<string>('all');

  // Modal Control for Branding Settings
  showBrandingModal = signal<boolean>(false);

  // Branding Signals & Properties
  brandingForm!: FormGroup;
  savingBranding = signal<boolean>(false);
  logoFile: File | null = null;
  logoPreviewUrl = signal<string | null>(null);
  tenant = signal<any>(null);
  tenantsList = signal<any[]>([]);

  // Current Date
  todayDate = new Date();

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  getMaxWeeklyCount(): number {
    const s = this.stats();
    if (!s || !s.weekly_activity || s.weekly_activity.length === 0) return 1;
    const max = Math.max(...s.weekly_activity.map(d => d.count));
    return max > 0 ? max : 5;
  }

  ngOnInit(): void {
    this.loadStats();
    this.initBrandingForm();
    if (this.authService.hasRole(['super_admin', 'admin'])) {
      this.loadTenantBranding();
    }
  }

  initBrandingForm(): void {
    this.brandingForm = this.fb.group({
      primary_color: ['#7c3aed', [Validators.required, Validators.maxLength(10)]],
      secondary_color: ['#db2777', [Validators.required, Validators.maxLength(10)]],
    });
  }

  loadTenantBranding(): void {
    this.http.get<any[]>(`${environment.apiUrl}/tenants`).subscribe({
      next: (tenants) => {
        this.tenantsList.set(tenants || []);
        if (tenants && tenants.length > 0) {
          const user = this.authService.getUser();
          const activeTenant = tenants.find(t => t.id === user?.tenant_id) || tenants[0];
          this.selectTenant(activeTenant);
        }
      },
      error: (err) => {
        console.error('Failed to load tenant details', err);
      }
    });
  }

  selectTenant(tenant: any): void {
    this.tenant.set(tenant);
    this.brandingForm.patchValue({
      primary_color: tenant.primary_color || '#7c3aed',
      secondary_color: tenant.secondary_color || '#db2777',
    });
    if (tenant.logo_path) {
      this.logoPreviewUrl.set(tenant.logo_path);
    } else {
      this.logoPreviewUrl.set(null);
    }
    this.logoFile = null;
  }

  onFilterTenantChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    const val = select.value;
    this.selectedTenantFilter.set(val);
    this.loadStats(val);

    // Also synchronize selected tenant for branding if a specific tenant is chosen
    if (val !== 'all') {
      const selected = this.tenantsList().find(t => t.id === Number(val));
      if (selected) {
        this.selectTenant(selected);
      }
    }
  }

  openBrandingModal(): void {
    this.showBrandingModal.set(true);
  }

  closeBrandingModal(): void {
    this.showBrandingModal.set(false);
  }

  onTenantChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    const tenantId = Number(select.value);
    const selected = this.tenantsList().find(t => t.id === tenantId);
    if (selected) {
      this.selectTenant(selected);
    }
  }

  onLogoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.logoFile = input.files[0];
      const reader = new FileReader();
      reader.onload = (e) => {
        this.logoPreviewUrl.set(e.target?.result as string);
      };
      reader.readAsDataURL(this.logoFile);
    }
  }

  saveBranding(): void {
    if (this.brandingForm.invalid || !this.tenant()) {
      return;
    }

    this.savingBranding.set(true);
    const formData = new FormData();
    formData.append('_method', 'PUT');
    formData.append('primary_color', this.brandingForm.get('primary_color')?.value);
    formData.append('secondary_color', this.brandingForm.get('secondary_color')?.value);
    if (this.logoFile) {
      formData.append('logo', this.logoFile);
    }

    const tenantId = this.tenant().id;
    this.http.post<any>(`${environment.apiUrl}/tenants/${tenantId}/branding`, formData).subscribe({
      next: (updatedTenant) => {
        this.savingBranding.set(false);
        this.closeBrandingModal();
        this.notificationService.show('success', 'Branding settings updated successfully!');
        
        const user = this.authService.getUser();
        if (user && user.tenant_id === updatedTenant.id) {
          const root = document.documentElement;
          if (updatedTenant.primary_color) {
            root.style.setProperty('--primary-color', updatedTenant.primary_color);
          }
          if (updatedTenant.secondary_color) {
            root.style.setProperty('--secondary-color', updatedTenant.secondary_color);
          }
          
          const localBranding = {
            tenant_name: updatedTenant.tenant_name,
            logo_url: updatedTenant.logo_path,
            primary_color: updatedTenant.primary_color,
            secondary_color: updatedTenant.secondary_color,
          };
          localStorage.setItem('tenant_branding', JSON.stringify(localBranding));

          setTimeout(() => {
            window.location.reload();
          }, 1200);
        } else {
          this.loadTenantBranding();
        }
      },
      error: (err) => {
        this.savingBranding.set(false);
        this.notificationService.show('error', 'Failed to update branding settings.');
      }
    });
  }

  loadStats(tenantId?: string): void {
    this.loading.set(true);
    this.error.set(null);

    let url = `${environment.apiUrl}/dashboard/tenant-stats`;
    const filter = tenantId !== undefined ? tenantId : this.selectedTenantFilter();
    if (filter && filter !== 'all') {
      url += `?tenant_id=${filter}`;
    }

    this.http.get<TenantStats>(url).subscribe({
      next: (data) => {
        this.stats.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to load dashboard statistics.');
        this.loading.set(false);
      }
    });
  }
}
