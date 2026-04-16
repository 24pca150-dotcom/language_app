import { Component, OnInit, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { ChapterService, ChapterData } from '../../services/chapter';
import { LevelService, LevelData } from '../../services/level';
import {
  McvInputField,
  McvTextArea,
  McvToggleField
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-chapter',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    TranslateModule
  ],
  templateUrl: './chapter.html',
  styleUrls: ['./chapter.css'],
})
export class Chapter implements OnInit {
  private fb = inject(FormBuilder);
  private chapterService = inject(ChapterService);
  private levelService = inject(LevelService);

  chapterForm: FormGroup;
  chapters = signal<ChapterData[]>([]);
  levels = signal<LevelData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentChapterId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.chapterForm = this.fb.group({
      level_id: ['', Validators.required],
      name: ['', Validators.required],
      code: ['', Validators.required],
      description: [''],
      sort_order: [0],
      is_active: [true],
    });
  }

  ngOnInit(): void {
    this.loadChapters();
    this.loadLevels();
  }

  loadChapters(): void {
    this.chapterService.getAll().subscribe({
      next: (data) => this.chapters.set(data),
      error: () => this.showFeedback('error', 'Failed to load chapters'),
    });
  }

  loadLevels(): void {
    this.levelService.getAll().subscribe({
      next: (data) => this.levels.set(data),
      error: () => this.showFeedback('error', 'Failed to load levels for selection'),
    });
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  generateCode(): void {
    const chaptersList = this.chapters();
    let nextCode = 'CH001';
    if (chaptersList.length > 0) {
      const codes = chaptersList
        .map(c => c.code)
        .filter(code => code && /^CH\d{3}$/.test(code))
        .map(code => parseInt(code.slice(2), 10));
      const max = codes.length ? Math.max(...codes) : 0;
      nextCode = 'CH' + ('' + (max + 1)).padStart(3, '0');
    }
    this.chapterForm.patchValue({ code: nextCode });
  }

  onSubmit(): void {
    if (this.chapterForm.invalid) {
      this.chapterForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const chapterData: ChapterData = this.chapterForm.value;

    if (this.isEditMode()) {
      const id = this.currentChapterId();
      if (id) {
        this.chapterService.update(id, chapterData).subscribe({
          next: () => {
            this.showFeedback('success', 'Chapter updated successfully');
            this.isFormVisible.set(false);
            this.loadChapters();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update chapter'),
        });
      }
    } else {
      this.chapterService.create(chapterData).subscribe({
        next: () => {
          this.showFeedback('success', 'Chapter created successfully');
          this.isFormVisible.set(false);
          this.loadChapters();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create chapter'),
      });
    }
  }

  editChapter(chapter: ChapterData): void {
    this.isEditMode.set(true);
    this.currentChapterId.set(chapter.id!);
    this.chapterForm.patchValue({
      level_id: chapter.level_id,
      name: chapter.name,
      code: chapter.code,
      description: chapter.description,
      sort_order: chapter.sort_order,
      is_active: chapter.is_active,
    });
    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteChapter(id: number): void {
    if (confirm('Are you sure you want to delete this chapter?')) {
      this.chapterService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Chapter deleted successfully');
          this.loadChapters();
        },
        error: () => this.showFeedback('error', 'Failed to delete chapter'),
      });
    }
  }

  resetForm(): void {
    this.chapterForm.reset({ is_active: true, sort_order: 0 });
    this.isEditMode.set(false);
    this.currentChapterId.set(null);
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
