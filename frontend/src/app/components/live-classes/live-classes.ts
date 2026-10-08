import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../services/auth';
import { environment } from '../../../environments/environment';

export interface LiveClassAttachment {
  id: number;
  live_class_id: number;
  title?: string;
  file_type: 'pdf' | 'video' | 'image' | 'audio' | 'document' | 'other';
  file_path: string;
  original_name: string;
  file_extension: string;
  file_size: string;
  file_url: string;
  created_at?: string;
}

export interface LiveClassItem {
  id: number;
  tenant_id?: number;
  title: string;
  description?: string;
  meeting_link: string;
  platform: string;
  instructor_name?: string;
  start_time: string;
  duration_minutes: number;
  status: 'scheduled' | 'live' | 'completed' | 'cancelled';
  attachments?: LiveClassAttachment[];
  created_at?: string;
}

@Component({
  selector: 'app-live-classes',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './live-classes.html',
  styleUrls: ['./live-classes.css']
})
export class LiveClasses implements OnInit {
  private http = inject(HttpClient);
  protected authService = inject(AuthService);
  private fb = inject(FormBuilder);

  liveClasses = signal<LiveClassItem[]>([]);
  loading = signal<boolean>(true);
  error = signal<string | null>(null);
  successMsg = signal<string | null>(null);

  classForm: FormGroup;
  isSubmitting = signal<boolean>(false);
  showForm = signal<boolean>(false);
  filterStatus = signal<'all' | 'live' | 'scheduled' | 'completed'>('all');

  // New class attachments selection
  selectedFiles = signal<File[]>([]);

  // Materials modal state
  activeClassForMaterials = signal<LiveClassItem | null>(null);
  isUploadingMaterials = signal<boolean>(false);

  constructor() {
    const now = new Date();
    now.setMinutes(Math.ceil(now.getMinutes() / 15) * 15, 0, 0);
    const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);

    const currentUser = this.authService.getUser();
    const defaultInstructor = currentUser?.name || 'Academy Instructor';

    this.classForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(255)]],
      meeting_link: ['', [Validators.required, Validators.pattern(/https?:\/\/.+/)]],
      instructor_name: [defaultInstructor, [Validators.required]],
      start_time: [localIso, [Validators.required]],
      duration_minutes: [60, [Validators.required, Validators.min(5), Validators.max(480)]],
      status: ['scheduled'],
      description: ['']
    });
  }

  ngOnInit(): void {
    this.loadClasses();
  }

  loadClasses(): void {
    this.loading.set(true);
    this.http.get<LiveClassItem[]>(`${environment.apiUrl}/live-classes`).subscribe({
      next: (data) => {
        this.liveClasses.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Error loading live classes:', err);
        this.error.set('Failed to load live classes.');
        this.loading.set(false);
      }
    });
  }

  filteredClasses(): LiveClassItem[] {
    const list = this.liveClasses();
    const filter = this.filterStatus();
    if (filter === 'all') return list;
    return list.filter(item => item.status === filter);
  }

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const newFiles = Array.from(input.files);
      this.selectedFiles.update(files => [...files, ...newFiles]);
      input.value = ''; // Reset input to allow selecting same file again if needed
    }
  }

  removeSelectedFile(index: number): void {
    this.selectedFiles.update(files => files.filter((_, i) => i !== index));
  }

  submitClass(): void {
    if (this.classForm.invalid) {
      this.classForm.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    this.error.set(null);

    const formData = new FormData();
    Object.keys(this.classForm.value).forEach(key => {
      const val = this.classForm.value[key];
      if (val !== null && val !== undefined) {
        formData.append(key, val);
      }
    });

    // Append attachments
    this.selectedFiles().forEach(file => {
      formData.append('files[]', file, file.name);
    });

    this.http.post<LiveClassItem>(`${environment.apiUrl}/live-classes`, formData).subscribe({
      next: (newClass) => {
        this.liveClasses.update(list => [newClass, ...list]);
        this.showForm.set(false);
        this.selectedFiles.set([]);
        this.isSubmitting.set(false);
        this.successMsg.set('Live class with materials created successfully!');
        setTimeout(() => this.successMsg.set(null), 4000);
        
        // Reset form
        const now = new Date();
        now.setMinutes(Math.ceil(now.getMinutes() / 15) * 15, 0, 0);
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        this.classForm.patchValue({
          title: '',
          meeting_link: '',
          start_time: localIso,
          duration_minutes: 60,
          status: 'scheduled',
          description: ''
        });
      },
      error: (err) => {
        console.error('Failed to create live class:', err);
        this.error.set(err?.error?.message || 'Failed to schedule live class.');
        this.isSubmitting.set(false);
      }
    });
  }

  // Materials Modal Management
  openMaterialsModal(classItem: LiveClassItem): void {
    this.activeClassForMaterials.set(classItem);
  }

  closeMaterialsModal(): void {
    this.activeClassForMaterials.set(null);
  }

  uploadNewFilesToClass(event: Event): void {
    const classItem = this.activeClassForMaterials();
    if (!classItem) return;

    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    this.isUploadingMaterials.set(true);
    const formData = new FormData();
    Array.from(input.files).forEach(file => {
      formData.append('files[]', file, file.name);
    });

    this.http.post<{ message: string; attachments: LiveClassAttachment[] }>(
      `${environment.apiUrl}/live-classes/${classItem.id}/attachments`,
      formData
    ).subscribe({
      next: (res) => {
        const updatedAttachments = res.attachments;
        // Update in active modal
        this.activeClassForMaterials.update(c => c ? { ...c, attachments: updatedAttachments } : null);
        // Update in list
        this.liveClasses.update(list =>
          list.map(c => c.id === classItem.id ? { ...c, attachments: updatedAttachments } : c)
        );
        this.isUploadingMaterials.set(false);
        input.value = '';
      },
      error: (err) => {
        console.error('Upload failed:', err);
        this.error.set('Failed to upload materials.');
        this.isUploadingMaterials.set(false);
      }
    });
  }

  deleteAttachment(attachmentId: number): void {
    const classItem = this.activeClassForMaterials();
    if (!classItem) return;
    if (!confirm('Are you sure you want to remove this file?')) return;

    this.http.delete(`${environment.apiUrl}/live-classes/attachments/${attachmentId}`).subscribe({
      next: () => {
        const remaining = (classItem.attachments || []).filter(a => a.id !== attachmentId);
        this.activeClassForMaterials.update(c => c ? { ...c, attachments: remaining } : null);
        this.liveClasses.update(list =>
          list.map(c => c.id === classItem.id ? { ...c, attachments: remaining } : c)
        );
      },
      error: () => {
        this.error.set('Failed to delete attachment.');
      }
    });
  }

  updateStatus(item: LiveClassItem, newStatus: 'scheduled' | 'live' | 'completed'): void {
    this.http.put<LiveClassItem>(`${environment.apiUrl}/live-classes/${item.id}`, { status: newStatus }).subscribe({
      next: (updated) => {
        this.liveClasses.update(list => list.map(c => c.id === item.id ? { ...c, status: updated.status } : c));
      },
      error: () => {
        this.error.set('Failed to update class status.');
      }
    });
  }

  deleteClass(id: number): void {
    if (!confirm('Are you sure you want to delete this live class and all its materials?')) return;

    this.http.delete(`${environment.apiUrl}/live-classes/${id}`).subscribe({
      next: () => {
        this.liveClasses.update(list => list.filter(c => c.id !== id));
      },
      error: () => {
        this.error.set('Failed to delete live class.');
      }
    });
  }

  getPlatformIcon(platform: string): string {
    switch (platform) {
      case 'google_meet': return 'bi-google';
      case 'zoom': return 'bi-camera-video-fill';
      case 'teams': return 'bi-microsoft';
      case 'youtube': return 'bi-youtube';
      default: return 'bi-broadcast';
    }
  }

  getPlatformName(platform: string): string {
    switch (platform) {
      case 'google_meet': return 'Google Meet';
      case 'zoom': return 'Zoom';
      case 'teams': return 'Microsoft Teams';
      case 'youtube': return 'YouTube Live';
      default: return 'Live Link';
    }
  }

  getFileIcon(type: string): string {
    switch (type) {
      case 'pdf': return 'bi-file-earmark-pdf-fill text-danger';
      case 'video': return 'bi-film text-info';
      case 'audio': return 'bi-music-note-beamed text-success';
      case 'image': return 'bi-file-earmark-image-fill text-primary';
      default: return 'bi-file-earmark-text-fill text-secondary';
    }
  }

  getFileBadgeClass(type: string): string {
    switch (type) {
      case 'pdf': return 'bg-danger-subtle text-danger border border-danger-subtle';
      case 'video': return 'bg-info-subtle text-info border border-info-subtle';
      case 'audio': return 'bg-success-subtle text-success border border-success-subtle';
      case 'image': return 'bg-primary-subtle text-primary border border-primary-subtle';
      default: return 'bg-secondary-subtle text-secondary';
    }
  }
}
