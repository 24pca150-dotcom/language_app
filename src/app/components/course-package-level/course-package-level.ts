import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CoursePackageLevelService } from '../../services/course-package-level';
import { PackageService, PackageData } from '../../services/package';
import { LevelService, LevelData } from '../../services/level';

@Component({
  selector: 'app-course-package-level',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './course-package-level.html',
  styleUrls: ['./course-package-level.css'],
})
export class CoursePackageLevel implements OnInit {
  private packageService = inject(PackageService);
  private levelService = inject(LevelService);
  private mappingService = inject(CoursePackageLevelService);

  packages = signal<PackageData[]>([]);
  allLevels = signal<LevelData[]>([]);
  selectedPackageId = signal<number | null>(null);
  mappedLevels = signal<any[]>([]);
  availableLevels = signal<LevelData[]>([]);
  
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  ngOnInit(): void {
    this.loadPackages();
    this.loadAllLevels();
  }

  loadPackages(): void {
    this.packageService.getAll().subscribe({
      next: (data) => this.packages.set(data),
      error: () => this.showFeedback('error', 'Failed to load packages'),
    });
  }

  loadAllLevels(): void {
    this.levelService.getAll().subscribe({
      next: (data) => this.allLevels.set(data),
      error: () => this.showFeedback('error', 'Failed to load levels'),
    });
  }

  onPackageChange(): void {
    const pkgId = this.selectedPackageId();
    if (pkgId) {
      this.loadMappings(pkgId);
    } else {
      this.mappedLevels.set([]);
      this.availableLevels.set([]);
    }
  }

  loadMappings(packageId: number): void {
    this.mappingService.getByPackage(packageId).subscribe({
      next: (mapped) => {
        this.mappedLevels.set(mapped);
        this.filterAvailableLevels(mapped);
      },
      error: () => this.showFeedback('error', 'Failed to load level mappings'),
    });
  }

  filterAvailableLevels(mapped: any[]): void {
    const mappedIds = mapped.map(m => m.id);
    this.availableLevels.set(
      this.allLevels().filter(level => !mappedIds.includes(level.id))
    );
  }

  mapLevel(levelId: number): void {
    const pkgId = this.selectedPackageId();
    if (pkgId) {
      this.mappingService.mapLevels(pkgId, [levelId]).subscribe({
        next: () => {
          this.showFeedback('success', 'Level mapped successfully');
          this.loadMappings(pkgId);
        },
        error: () => this.showFeedback('error', 'Failed to map level'),
      });
    }
  }

  unmapLevel(levelId: number): void {
    const pkgId = this.selectedPackageId();
    if (pkgId && confirm('Are you sure you want to remove this level from the package?')) {
      this.mappingService.unmap(pkgId, levelId).subscribe({
        next: () => {
          this.showFeedback('success', 'Level mapping removed');
          this.loadMappings(pkgId);
        },
        error: () => this.showFeedback('error', 'Failed to remove mapping'),
      });
    }
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
