import { Component, OnInit, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { SubChapterService, SubChapterData } from '../../services/sub-chapter';
import { ChapterService, ChapterData } from '../../services/chapter';
import {
  McvInputField,
  McvTextArea,
  McvToggleField
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-sub-chapter',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    TranslateModule
  ],
  templateUrl: './sub-chapter.html',
  styleUrls: ['./sub-chapter.css'],
})
export class SubChapter implements OnInit {
  private fb = inject(FormBuilder);
  private subChapterService = inject(SubChapterService);
  private chapterService = inject(ChapterService);

  subChapterForm: FormGroup;
  subChapters = signal<SubChapterData[]>([]);
  chapters = signal<ChapterData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentSubChapterId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.subChapterForm = this.fb.group({
      chapter_id: ['', Validators.required],
      name: ['', Validators.required],
      content_type: ['text', Validators.required],
      content: [''],
      content_meta: [null],
      sort_order: [0],
      is_active: [true],
    });
  }

  ngOnInit(): void {
    this.loadSubChapters();
    this.loadChapters();
  }

  loadSubChapters(): void {
    this.subChapterService.getAll().subscribe({
      next: (data) => this.subChapters.set(data),
      error: () => this.showFeedback('error', 'Failed to load sub-chapters'),
    });
  }

  loadChapters(): void {
    this.chapterService.getAll().subscribe({
      next: (data) => this.chapters.set(data),
      error: () => this.showFeedback('error', 'Failed to load chapters for selection'),
    });
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  onSubmit(): void {
    if (this.subChapterForm.invalid) {
      this.subChapterForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const subChapterData: SubChapterData = this.subChapterForm.value;

    if (this.isEditMode()) {
      const id = this.currentSubChapterId();
      if (id) {
        this.subChapterService.update(id, subChapterData).subscribe({
          next: () => {
            this.showFeedback('success', 'Sub-chapter updated successfully');
            this.isFormVisible.set(false);
            this.loadSubChapters();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update sub-chapter'),
        });
      }
    } else {
      this.subChapterService.create(subChapterData).subscribe({
        next: () => {
          this.showFeedback('success', 'Sub-chapter created successfully');
          this.isFormVisible.set(false);
          this.loadSubChapters();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create sub-chapter'),
      });
    }
  }

  editSubChapter(subChapter: SubChapterData): void {
    this.isEditMode.set(true);
    this.currentSubChapterId.set(subChapter.id!);
    this.subChapterForm.patchValue({
      chapter_id: subChapter.chapter_id,
      name: subChapter.name,
      content_type: subChapter.content_type,
      content: subChapter.content,
      content_meta: subChapter.content_meta,
      sort_order: subChapter.sort_order,
      is_active: subChapter.is_active,
    });
    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteSubChapter(id: number): void {
    if (confirm('Are you sure you want to delete this sub-chapter?')) {
      this.subChapterService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Sub-chapter deleted successfully');
          this.loadSubChapters();
        },
        error: () => this.showFeedback('error', 'Failed to delete sub-chapter'),
      });
    }
  }

  resetForm(): void {
    this.subChapterForm.reset({ is_active: true, sort_order: 0, content_type: 'text' });
    this.isEditMode.set(false);
    this.currentSubChapterId.set(null);
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
