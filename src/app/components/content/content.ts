import { Component, OnInit, inject, signal, HostListener, computed } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { ContentService, ContentData } from '../../services/content';
import { ChapterService, ChapterData } from '../../services/chapter';

import {
  McvInputField,
  McvTextArea,
  McvToggleField
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-content',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    TranslateModule
  ],
  templateUrl: './content.html',
  styleUrls: ['./content.css'],
})
export class Content implements OnInit {
  private fb = inject(FormBuilder);
  private contentService = inject(ContentService);
  private chapterService = inject(ChapterService);

  contentForm: FormGroup;
  contents = signal<ContentData[]>([]);
  chapters = signal<ChapterData[]>([]);
  
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentContentId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);
  
  chapterSearchQuery = signal('');
  isChapterDropdownOpen = signal(false);
  selectedChapterIds = signal<number[]>([]);

  filteredChapters = computed(() => {
    const query = this.chapterSearchQuery().toLowerCase().trim();
    if (!query) return this.chapters();
    return this.chapters().filter(c => 
      c.name.toLowerCase().includes(query) || 
      c.code.toLowerCase().includes(query)
    );
  });

  allChaptersSelected = computed(() => {
    const chapters = this.chapters();
    return chapters.length > 0 && this.selectedChapterIds().length === chapters.length;
  });

  @HostListener('document:click')
  onDocumentClick() {
    this.isChapterDropdownOpen.set(false);
  }

  // File states
  selectedFiles: { [key: string]: File | null } = {
    image: null,
    video: null,
    pdf: null,
    doc: null,
    xlsx: null,
    ppt: null
  };

  constructor() {
    this.contentForm = this.fb.group({
      name: ['', Validators.required],
      sort_order: [0],
      is_active: [true],
      text_content: [''],
      external_url: ['']
    });
  }

  ngOnInit(): void {
    this.loadContents();
    this.loadChapters();
  }

  loadContents(): void {
    this.contentService.getAll().subscribe({
      next: (data) => this.contents.set(data),
      error: () => this.showFeedback('error', 'Failed to load contents'),
    });
  }

  loadChapters(): void {
    this.chapterService.getAll().subscribe({
      next: (data) => this.chapters.set(data),
      error: () => this.showFeedback('error', 'Failed to load chapters'),
    });
  }



  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
  }

  onFileChange(event: any, type: string): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFiles[type] = file;
    }
  }

  onSubmit(): void {
    if (this.contentForm.invalid) {
      this.contentForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const contentData = { 
      ...this.contentForm.value,
      chapter_ids: this.selectedChapterIds()
    };
    
    // In a real app, you'd upload files first then send URLs
    // For now, let's assume we send them or the service handles it.
    // If I had file upload endpoints, I'd call them here.

    if (this.isEditMode()) {
      const id = this.currentContentId();
      if (id) {
        this.contentService.update(id, contentData).subscribe({
          next: () => {
            this.showFeedback('success', 'Content updated successfully');
            this.isFormVisible.set(false);
            this.loadContents();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update content'),
        });
      }
    } else {
      this.contentService.create(contentData).subscribe({
        next: () => {
          this.showFeedback('success', 'Content created successfully');
          this.isFormVisible.set(false);
          this.loadContents();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create content'),
      });
    }
  }

  editContent(content: ContentData): void {
    this.isEditMode.set(true);
    this.currentContentId.set(content.id!);
    this.contentForm.patchValue({
      name: content.name,
      sort_order: content.sort_order,
      is_active: content.is_active,
      text_content: content.text_content,
      external_url: content.external_url
    });
    this.selectedChapterIds.set((content as any).chapters ? (content as any).chapters.map((c: any) => c.id) : []);
    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteContent(id: number): void {
    if (confirm('Are you sure you want to delete this content?')) {
      this.contentService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Content deleted successfully');
          this.loadContents();
        },
        error: () => this.showFeedback('error', 'Failed to delete content'),
      });
    }
  }

  resetForm(): void {
    this.contentForm.reset({ is_active: true, sort_order: 0 });
    this.selectedChapterIds.set([]);
    this.selectedFiles = {
      image: null,
      video: null,
      pdf: null,
      doc: null,
      xlsx: null,
      ppt: null
    };
    this.isEditMode.set(false);
    this.currentContentId.set(null);
  }

  cancelForm(): void {
    this.resetForm();
    this.isFormVisible.set(false);
  }

  toggleChapterDropdown(event: Event): void {
    event.stopPropagation();
    this.isChapterDropdownOpen.update(v => !v);
  }

  onChapterSearch(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.chapterSearchQuery.set(target.value);
  }

  toggleChapterSelection(id: number): void {
    this.selectedChapterIds.update(ids => {
      if (ids.includes(id)) {
        return ids.filter(i => i !== id);
      } else {
        return [...ids, id];
      }
    });
  }

  toggleAllChapters(): void {
    if (this.allChaptersSelected()) {
      this.selectedChapterIds.set([]);
    } else {
      this.selectedChapterIds.set(this.chapters().map(c => c.id!));
    }
  }

  isChapterSelected(id: number): boolean {
    return this.selectedChapterIds().includes(id);
  }

  getSelectedChaptersLabel(): string {
    const count = this.selectedChapterIds().length;
    if (count === 0) return 'Select Chapters';
    if (count === 1) {
      const chapter = this.getChapterById(this.selectedChapterIds()[0]);
      return chapter ? chapter.name : '1 chapter selected';
    }
    return `${count} chapters selected`;
  }

  getChapterById(id: number): ChapterData | undefined {
    return this.chapters().find(c => c.id === id);
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
