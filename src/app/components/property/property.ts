import { Component, OnInit, inject, signal, ChangeDetectorRef } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { PropertyService, PropertyData } from '../../services/property';
import { TenantService, TenantData } from '../../services/tenant';
import { PackageService, PackageData } from '../../services/package';
import {
  McvInputField,
  McvTextArea,
  McvToggleField,
  McvDateRangePicker,
  McvCheckbox
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-property',
  standalone: true,
  imports: [
    CommonModule,
    DatePipe,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    McvDateRangePicker,
    McvCheckbox
  ],
  templateUrl: './property.html',
  styleUrls: ['./property.css'],
})
export class Property implements OnInit {
  private fb = inject(FormBuilder);
  private propertyService = inject(PropertyService);
  private tenantService = inject(TenantService);
  private packageService = inject(PackageService);
  private cdr = inject(ChangeDetectorRef);

  propertyForm: FormGroup;
  properties = signal<PropertyData[]>([]);
  tenants = signal<TenantData[]>([]);
  availablePackages = signal<PackageData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false); // Default to table view
  currentPropertyId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.propertyForm = this.fb.group({
      tenant_id: ['', Validators.required],
      property_code: ['', Validators.required],
      property_name: ['', Validators.required],
      location: [''],
      address: [''],
      max_users: [1, [Validators.required, Validators.min(1)]],
      is_active: [true],
      packages: this.fb.array([])
    });
  }

  get packagesFormArray() {
    return this.propertyForm.get('packages') as FormArray;
  }

  ngOnInit(): void {
    this.loadInitialData();
  }

  loadInitialData(): void {
    this.propertyService.getAll().subscribe({
      next: (data) => this.properties.set(data),
      error: () => this.showFeedback('error', 'Failed to load properties')
    });

    this.tenantService.getAll().subscribe({
      next: (data) => this.tenants.set(data),
      error: () => this.showFeedback('error', 'Failed to load tenants')
    });

    this.packageService.getAll().subscribe({
      next: (data) => {
        this.availablePackages.set(data);
        this.initPackageFormArray(data);
      },
      error: () => this.showFeedback('error', 'Failed to load packages')
    });

    this.cdr.detectChanges();
  }

  initPackageFormArray(packages: PackageData[]) {
    this.packagesFormArray.clear();
    packages.forEach((pkg, index) => {
      const group = this.fb.group({
        id: [pkg.id],
        name: [pkg.name],
        selected: [false],
        date_range: [null],
        is_active: [true]
      });

      // Add dynamic validators for date_range based on selected status
      group.get('selected')?.valueChanges.subscribe(selected => {
        const dateRangeControl = group.get('date_range');
        if (selected) {
          dateRangeControl?.setValidators([Validators.required]);
        } else {
          dateRangeControl?.clearValidators();
        }
        dateRangeControl?.updateValueAndValidity();
      });

      this.packagesFormArray.push(group);
    });
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  onSubmit(): void {
    if (this.propertyForm.invalid) {
      this.propertyForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const formValue = this.propertyForm.value;
    const propertyData = {
      ...formValue,
      tenant_id: Number(formValue.tenant_id),
      max_users: Number(formValue.max_users),
      is_active: !!formValue.is_active,
      packages: formValue.packages
        .filter((pkg: any) => pkg.selected)
        .map((pkg: any) => {
          const startDate = pkg.date_range?.start ? this.formatDate(pkg.date_range.start) : null;
          const endDate = pkg.date_range?.end ? this.formatDate(pkg.date_range.end) : null;
          
          return {
            id: pkg.id,
            start_date: startDate,
            end_date: endDate,
            is_active: !!pkg.is_active
          };
        })
    };

    if (this.isEditMode()) {
      const id = this.currentPropertyId();
      if (id) {
        this.propertyService.update(id, propertyData).subscribe({
          next: () => {
            this.showFeedback('success', 'Property updated successfully');
            this.isFormVisible.set(false);
            this.loadInitialData();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update property'),
        });
      }
    } else {
      this.propertyService.create(propertyData).subscribe({
        next: () => {
          this.showFeedback('success', 'Property created successfully');
          this.isFormVisible.set(false);
          this.loadInitialData();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create property'),
      });
    }
  }

  editProperty(property: PropertyData): void {
    this.isEditMode.set(true);
    this.currentPropertyId.set(property.id!);

    this.propertyForm.patchValue({
      tenant_id: property.tenant_id,
      property_code: property.property_code,
      property_name: property.property_name,
      location: property.location,
      address: property.address,
      max_users: property.max_users,
      is_active: property.is_active
    });

    // Handle package selections
    this.packagesFormArray.controls.forEach(control => {
      const pkgId = control.get('id')?.value;
      const pkgMap = property.packages?.find(p => p.id === pkgId);
      const pivot = pkgMap?.pivot;

      if (pivot) {
        control.patchValue({
          selected: true,
          date_range: {
            start: pivot.start_date ? new Date(pivot.start_date) : null,
            end: pivot.end_date ? new Date(pivot.end_date) : null
          },
          is_active: pivot.is_active
        });
      } else {
        control.patchValue({
          selected: false,
          date_range: null,
          is_active: true
        });
      }
    });

    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteProperty(id: number): void {
    if (confirm('Are you sure you want to delete this property?')) {
      this.propertyService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Property deleted successfully');
          this.loadInitialData();
        },
        error: () => this.showFeedback('error', 'Failed to delete property'),
      });
    }
  }

  resetForm(): void {
    this.propertyForm.reset({ max_users: 1, is_active: true });
    this.initPackageFormArray(this.availablePackages());
    this.isEditMode.set(false);
    this.currentPropertyId.set(null);
  }

  cancelForm(): void {
    this.resetForm();
    this.isFormVisible.set(false);
  }

  private formatDate(date: any): string | null {
    if (!date) return null;
    try {
      const d = new Date(date);
      if (isNaN(d.getTime())) return null;
      const month = '' + (d.getMonth() + 1);
      const day = '' + d.getDate();
      const year = d.getFullYear();
      return [year, month.padStart(2, '0'), day.padStart(2, '0')].join('-');
    } catch {
      return null;
    }
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
