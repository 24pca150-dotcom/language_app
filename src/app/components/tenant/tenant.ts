import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TenantService, TenantData } from '../../services/tenant';

@Component({
  selector: 'app-tenant',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './tenant.html',
  styleUrls: ['./tenant.css'],
})
export class Tenant implements OnInit {
  private fb = inject(FormBuilder);
  private tenantService = inject(TenantService);

  tenantForm: FormGroup;
  tenants = signal<TenantData[]>([]);
  isEditMode = signal(false);
  currentTenantId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.tenantForm = this.fb.group({
      tenant_code: ['', Validators.required],
      tenant_name: ['', Validators.required],
      contact_person: [''],
      email: ['', [Validators.email]],
      phone: [''],
      address: [''],
      is_active: [true],
    });
  }

  ngOnInit(): void {
    this.loadTenants();
  }

  loadTenants(): void {
    this.tenantService.getAll().subscribe({
      next: (data) => this.tenants.set(data),
      error: (err) => this.showFeedback('error', 'Failed to load tenants'),
    });
  }

  onSubmit(): void {
    if (this.tenantForm.invalid) {
      this.tenantForm.markAllAsTouched();
      return;
    }

    const tenantData: TenantData = this.tenantForm.value;

    if (this.isEditMode()) {
      const id = this.currentTenantId();
      if (id) {
        this.tenantService.update(id, tenantData).subscribe({
          next: () => {
            this.showFeedback('success', 'Tenant updated successfully');
            this.resetForm();
            this.loadTenants();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update tenant'),
        });
      }
    } else {
      this.tenantService.create(tenantData).subscribe({
        next: () => {
          this.showFeedback('success', 'Tenant created successfully');
          this.resetForm();
          this.loadTenants();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create tenant'),
      });
    }
  }

  editTenant(tenant: TenantData): void {
    this.isEditMode.set(true);
    this.currentTenantId.set(tenant.id!);
    this.tenantForm.patchValue({
      tenant_code: tenant.tenant_code,
      tenant_name: tenant.tenant_name,
      contact_person: tenant.contact_person,
      email: tenant.email,
      phone: tenant.phone,
      address: tenant.address,
      is_active: tenant.is_active,
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteTenant(id: number): void {
    if (confirm('Are you sure you want to delete this tenant?')) {
      this.tenantService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Tenant deleted successfully');
          this.loadTenants();
        },
        error: (err) => this.showFeedback('error', 'Failed to delete tenant'),
      });
    }
  }

  resetForm(): void {
    this.tenantForm.reset({ is_active: true });
    this.isEditMode.set(false);
    this.currentTenantId.set(null);
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
