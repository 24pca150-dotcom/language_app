import { Component, OnInit, inject, signal, ChangeDetectorRef } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { PropertyService, PropertyData } from '../../services/property';
import { TenantService, TenantData } from '../../services/tenant';
import { PackageService, PackageData } from '../../services/package';
import { CourseService, CourseData } from '../../services/course';
import { LearningModeService, LearningModeData } from '../../services/learning-mode';
import {
  McvInputField,
  McvTextArea,
  McvToggleField,
  McvDateRangePicker
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
    TranslateModule
  ],
  templateUrl: './property.html',
  styleUrls: ['./property.css'],
})
export class Property implements OnInit {
  private fb = inject(FormBuilder);
  private propertyService = inject(PropertyService);
  private tenantService = inject(TenantService);
  private packageService = inject(PackageService);
  private courseService = inject(CourseService);
  private learningModeService = inject(LearningModeService);
  private cdr = inject(ChangeDetectorRef);

  propertyForm: FormGroup;
  properties = signal<PropertyData[]>([]);
  tenants = signal<TenantData[]>([]);
  availablePackages = signal<PackageData[]>([]);
  courses = signal<CourseData[]>([]);
  learningModes = signal<LearningModeData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentPropertyId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);
  today = new Date();

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
      next: (data) => this.availablePackages.set(data),
      error: () => this.showFeedback('error', 'Failed to load packages')
    });

    this.courseService.getAll().subscribe({
      next: (data) => this.courses.set(data),
      error: () => this.showFeedback('error', 'Failed to load courses')
    });

    this.learningModeService.getAll().subscribe({
      next: (data) => this.learningModes.set(data),
      error: () => this.showFeedback('error', 'Failed to load learning modes')
    });

    this.cdr.detectChanges();
  }

  createPackageRow(): FormGroup {
    return this.fb.group({
      course_id: ['', Validators.required],
      package_id: ['', Validators.required],
      date_range: [null], // Combined start/end
      is_active: [true],
      learning_modes: [[]]
    });
  }

  addPackageRow() {
    this.packagesFormArray.push(this.createPackageRow());
  }

  removePackageRow(index: number) {
    this.packagesFormArray.removeAt(index);
  }

  dateRangeValidator(group: FormGroup): any {
    const start = group.get('start_date')?.value;
    const end = group.get('end_date')?.value;
    if (start && end && new Date(start) > new Date(end)) {
      return { invalidDateRange: true };
    }
    return null;
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  generateCode(): void {
    const propertiesList = this.properties();
    let nextCode = 'PC001';
    if (propertiesList.length > 0) {
      const codes = propertiesList
        .map(p => p.property_code)
        .filter(code => code && /^PC\d{3}$/.test(code))
        .map(code => parseInt(code.slice(2), 10));
      const max = codes.length ? Math.max(...codes) : 0;
      nextCode = 'PC' + ('' + (max + 1)).padStart(3, '0');
    }
    this.propertyForm.patchValue({ property_code: nextCode });
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
      packages: formValue.packages.map((pkg: any) => ({
        id: Number(pkg.package_id),
        course_id: pkg.course_id ? Number(pkg.course_id) : null,
        start_date: pkg.date_range?.start ? this.formatDate(pkg.date_range.start) : null,
        end_date: pkg.date_range?.end ? this.formatDate(pkg.date_range.end) : null,
        is_active: !!pkg.is_active,
        learning_mode_ids: pkg.learning_modes || []
      }))
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

    this.packagesFormArray.clear();
    if (property.packages && property.packages.length > 0) {
      property.packages.forEach((pkg: any) => {
        const pivot = pkg.pivot;
        const row = this.fb.group({
          course_id: [pivot?.course_id || '', Validators.required],
          package_id: [pkg.id, Validators.required],
          date_range: [{
            start: pivot?.start_date ? new Date(pivot.start_date) : null,
            end: pivot?.end_date ? new Date(pivot.end_date) : null
          }],
          is_active: [pivot?.is_active ?? true],
          learning_modes: [pivot?.learning_mode_ids ? JSON.parse(pivot.learning_mode_ids) : []]
        });
        this.packagesFormArray.push(row);
      });
    } else {
      this.addPackageRow(); // At least one empty row
    }

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
    this.packagesFormArray.clear();
    this.addPackageRow();
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