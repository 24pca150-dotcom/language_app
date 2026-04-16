import { Component, OnInit, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { LevelService, LevelData } from '../../services/level';
import { CourseService, CourseData } from '../../services/course';
import {
  McvInputField,
  McvTextArea,
  McvToggleField
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-level',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    TranslateModule
  ],
  templateUrl: './level.html',
  styleUrls: ['./level.css'],
})
export class Level implements OnInit {
  private fb = inject(FormBuilder);
  private levelService = inject(LevelService);
  private courseService = inject(CourseService);

  levelForm: FormGroup;
  levels = signal<LevelData[]>([]);
  courses = signal<CourseData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentLevelId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.levelForm = this.fb.group({
      course_id: ['', Validators.required],
      name: ['', Validators.required],
      code: ['', Validators.required],
      description: [''],
      estimated_hours: [0, [Validators.required, Validators.min(0)]],
      sort_order: [0],
      is_active: [true],
    });
  }

  ngOnInit(): void {
    this.loadLevels();
    this.loadCourses();
  }

  loadLevels(): void {
    this.levelService.getAll().subscribe({
      next: (data) => this.levels.set(data),
      error: () => this.showFeedback('error', 'Failed to load levels'),
    });
  }

  loadCourses(): void {
    this.courseService.getAll().subscribe({
      next: (data) => this.courses.set(data),
      error: () => this.showFeedback('error', 'Failed to load courses for selection'),
    });
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  generateCode(): void {
    const levelsList = this.levels();
    let nextCode = 'LV001';
    if (levelsList.length > 0) {
      const codes = levelsList
        .map(l => l.code)
        .filter(code => code && /^LV\d{3}$/.test(code))
        .map(code => parseInt(code.slice(2), 10));
      const max = codes.length ? Math.max(...codes) : 0;
      nextCode = 'LV' + ('' + (max + 1)).padStart(3, '0');
    }
    this.levelForm.patchValue({ code: nextCode });
  }

  onSubmit(): void {
    if (this.levelForm.invalid) {
      this.levelForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const levelData: LevelData = this.levelForm.value;

    if (this.isEditMode()) {
      const id = this.currentLevelId();
      if (id) {
        this.levelService.update(id, levelData).subscribe({
          next: () => {
            this.showFeedback('success', 'Level updated successfully');
            this.isFormVisible.set(false);
            this.loadLevels();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update level'),
        });
      }
    } else {
      this.levelService.create(levelData).subscribe({
        next: () => {
          this.showFeedback('success', 'Level created successfully');
          this.isFormVisible.set(false);
          this.loadLevels();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create level'),
      });
    }
  }

  editLevel(level: LevelData): void {
    this.isEditMode.set(true);
    this.currentLevelId.set(level.id!);
    this.levelForm.patchValue({
      course_id: level.course_id,
      name: level.name,
      code: level.code,
      description: level.description,
      estimated_hours: level.estimated_hours,
      sort_order: level.sort_order,
      is_active: level.is_active,
    });
    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteLevel(id: number): void {
    if (confirm('Are you sure you want to delete this level?')) {
      this.levelService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Level deleted successfully');
          this.loadLevels();
        },
        error: () => this.showFeedback('error', 'Failed to delete level'),
      });
    }
  }

  resetForm(): void {
    this.levelForm.reset({ is_active: true, estimated_hours: 0, sort_order: 0 });
    this.isEditMode.set(false);
    this.currentLevelId.set(null);
  }

  cancelForm(): void {
    this.resetForm();
    this.isFormVisible.set(false);
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
