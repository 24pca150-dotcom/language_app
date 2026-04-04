import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { PackageService, PackageData } from '../../services/package';

@Component({
  selector: 'app-package',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './package.html',
  styleUrls: ['./package.css'],
})
export class Package implements OnInit {
  private fb = inject(FormBuilder);
  private packageService = inject(PackageService);

  packageForm: FormGroup;
  packages = signal<PackageData[]>([]);
  isEditMode = signal(false);
  currentPackageId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.packageForm = this.fb.group({
      name: ['', Validators.required],
      code: ['', Validators.required],
      description: [''],
      is_active: [true],
    });
  }

  ngOnInit(): void {
    this.loadPackages();
  }

  loadPackages(): void {
    this.packageService.getAll().subscribe({
      next: (data) => this.packages.set(data),
      error: (err) => this.showFeedback('error', 'Failed to load packages'),
    });
  }

  onSubmit(): void {
    if (this.packageForm.invalid) {
      this.packageForm.markAllAsTouched();
      return;
    }

    const packageData: PackageData = this.packageForm.value;

    if (this.isEditMode()) {
      const id = this.currentPackageId();
      if (id) {
        this.packageService.update(id, packageData).subscribe({
          next: () => {
            this.showFeedback('success', 'Package updated successfully');
            this.resetForm();
            this.loadPackages();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update package'),
        });
      }
    } else {
      this.packageService.create(packageData).subscribe({
        next: () => {
          this.showFeedback('success', 'Package created successfully');
          this.resetForm();
          this.loadPackages();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create package'),
      });
    }
  }

  editPackage(pkg: PackageData): void {
    this.isEditMode.set(true);
    this.currentPackageId.set(pkg.id!);
    this.packageForm.patchValue({
      name: pkg.name,
      code: pkg.code,
      description: pkg.description,
      is_active: pkg.is_active,
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deletePackage(id: number): void {
    if (confirm('Are you sure you want to delete this package?')) {
      this.packageService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Package deleted successfully');
          this.loadPackages();
        },
        error: (err) => this.showFeedback('error', 'Failed to delete package'),
      });
    }
  }

  resetForm(): void {
    this.packageForm.reset({ is_active: true });
    this.isEditMode.set(false);
    this.currentPackageId.set(null);
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
