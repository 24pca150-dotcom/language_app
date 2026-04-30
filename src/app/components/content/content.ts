import { Component, OnInit, inject, signal, HostListener, computed, Pipe, PipeTransform } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { DomSanitizer } from '@angular/platform-browser';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

@Pipe({
  name: 'safeHtml',
  standalone: true
})
export class SafeHtmlPipe implements PipeTransform {
  private sanitizer = inject(DomSanitizer);
  transform(value: any) {
    return this.sanitizer.bypassSecurityTrustHtml(value);
  }
}


import { ContentService, ContentData } from '../../services/content';
import { ChapterService, ChapterData } from '../../services/chapter';

import {
  McvInputField,
  McvToggleField
} from 'mcv-ui-toolkit';
import { EditorComponent } from '@tinymce/tinymce-angular';
@Component({
  selector: 'app-content',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvToggleField,
    TranslateModule,
    EditorComponent,
    SafeHtmlPipe
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
  previewContent = signal<ContentData | null>(null);

  editorConfig = {
    base_url: '/tinymce',
    suffix: '.min',
    height: 500,
    menubar: 'file edit view insert format tools table help',
    plugins: [
      'advlist autolink lists link image charmap print preview anchor',
      'searchreplace visualblocks code fullscreen',
      'insertdatetime media table paste code help wordcount'
    ],
    toolbar:
      'undo redo | formatselect | bold italic backcolor | ' +
      'alignleft aligncenter alignright alignjustify | ' +
      'bullist numlist outdent indent | removeformat | help',
    skin: 'oxide',
    content_css: 'default'
  };



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
  uploadedFiles = signal<{file: File, url: string, name: string}[]>([]);
  existingFiles = signal<{url: string, name: string, type: string}[]>([]);

  constructor() {
    this.contentForm = this.fb.group({
      name: ['', Validators.required],
      sort_order: [0],
      is_active: [true],
      text_content: [''],
      urls: this.fb.array([this.fb.control('')])
    });
  }

  get urlControls() {
    return (this.contentForm.get('urls') as FormArray).controls;
  }

  addUrlField() {
    (this.contentForm.get('urls') as FormArray).push(this.fb.control(''));
  }

  removeUrlField(index: number) {
    const urls = this.contentForm.get('urls') as FormArray;
    if (urls.length > 1) {
      urls.removeAt(index);
    } else {
      urls.at(0).setValue('');
    }
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

  onMultipleFileChange(event: any): void {
    const files = event.target.files as FileList;
    if (files && files.length > 0) {
      const newFiles = Array.from(files).map(file => ({
        file,
        url: URL.createObjectURL(file),
        name: file.name
      }));
      this.uploadedFiles.update(curr => [...curr, ...newFiles]);
    }
    event.target.value = '';
  }

  removeFile(index: number): void {
    this.uploadedFiles.update(curr => {
      const updated = [...curr];
      URL.revokeObjectURL(updated[index].url);
      updated.splice(index, 1);
      return updated;
    });
  }

  removeExistingFile(index: number): void {
    this.existingFiles.update(curr => {
      const updated = [...curr];
      updated.splice(index, 1);
      return updated;
    });
  }

  viewFile(url: string): void {
    window.open(url, '_blank');
  }

  onSubmit(): void {
    if (this.contentForm.invalid) {
      this.contentForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const filesToUpload = this.uploadedFiles();
    
    if (filesToUpload.length > 0) {
      this.showFeedback('success', 'Uploading files...');
      const uploadObservables = filesToUpload.map(f => 
        this.contentService.uploadFile(f.file).pipe(
          catchError(err => {
            console.error('Upload failed for', f.name, err);
            return of(null);
          })
        )
      );

      forkJoin(uploadObservables).subscribe(results => {
        const uploadedData: any = {
          image: [],
          video: [],
          pdf: [],
          doc: [],
          xlsx: [],
          ppt: []
        };

        const typeMap: any = {
          'images': 'image',
          'videos': 'video',
          'pdfs': 'pdf',
          'docs': 'doc',
          'xlsx': 'xlsx',
          'ppts': 'ppt'
        };

        results.forEach(res => {
          if (res) {
            const field = typeMap[res.type];
            if (field && uploadedData[field]) {
              uploadedData[field].push({
                url: res.url,
                name: res.name,
                extension: res.extension
              });
            }
          }
        });

        this.saveContent(uploadedData);
      });
    } else {
      this.saveContent({});
    }
  }

  private saveContent(fileData: any): void {
    // Collect all existing files by type
    const finalFileData: any = { ...fileData };
    
    // Initialize collections for existing files if not already in finalFileData
    const typeMap: any = {
      'image': 'image',
      'video': 'video',
      'pdf': 'pdf',
      'doc': 'doc',
      'xlsx': 'xlsx',
      'ppt': 'ppt'
    };

    // If we are in edit mode, we need to include remaining existing files
    if (this.isEditMode()) {
      this.existingFiles().forEach(file => {
        const field = typeMap[file.type];
        if (field) {
          if (!finalFileData[field]) finalFileData[field] = [];
          finalFileData[field].push(file);
        }
      });
    }

    const contentData = {
      ...this.contentForm.value,
      ...finalFileData,
      chapter_ids: this.selectedChapterIds()
    };

    if (this.isEditMode()) {
      const id = this.currentContentId();
      if (id) {
        this.contentService.update(id, contentData).subscribe({
          next: () => {
            this.showFeedback('success', 'Content updated successfully');
            this.isFormVisible.set(false);
            this.loadContents();
            this.resetForm();
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
          this.resetForm();
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
    });
    
    // Patch URLs
    const urlArray = this.contentForm.get('urls') as FormArray;
    urlArray.clear();
    const urls = (content as any).urls || (content.external_url ? [content.external_url] : ['']);
    urls.forEach((url: string) => urlArray.push(this.fb.control(url)));

    // Load existing files
    const existing: {url: string, name: string, type: string}[] = [];
    if (content.image_list) content.image_list.forEach(f => existing.push({ ...f, type: 'image' }));
    if (content.video_list) content.video_list.forEach(f => existing.push({ ...f, type: 'video' }));
    if (content.pdf_list) content.pdf_list.forEach(f => existing.push({ ...f, type: 'pdf' }));
    if (content.doc_list) content.doc_list.forEach(f => existing.push({ ...f, type: 'doc' }));
    if (content.xlsx_list) content.xlsx_list.forEach(f => existing.push({ ...f, type: 'xlsx' }));
    if (content.ppt_list) content.ppt_list.forEach(f => existing.push({ ...f, type: 'ppt' }));
    this.existingFiles.set(existing);

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
    const urlArray = this.contentForm.get('urls') as FormArray;
    urlArray.clear();
    urlArray.push(this.fb.control(''));
    
    this.selectedChapterIds.set([]);
    
    // Revoke object URLs to free memory
    this.uploadedFiles().forEach(f => URL.revokeObjectURL(f.url));
    this.uploadedFiles.set([]);
    this.existingFiles.set([]);
    
    this.isEditMode.set(false);
    this.currentContentId.set(null);
  }

  showPreview(content: ContentData): void {
    this.previewContent.set(content);
  }

  closePreview(): void {
    this.previewContent.set(null);
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
