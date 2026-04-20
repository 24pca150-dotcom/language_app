import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';

interface SubChapter {
  id: number;
  name: string;
  content_type: string;
  content?: string;
  content_meta?: any;
  sort_order?: number;
  is_active: boolean;
}

interface Chapter {
  id: number;
  chapter_id?: number;
  name: string;
  code?: string;
  description?: string;
  content_type?: string;
  content?: string;
  content_meta?: any;
  sort_order?: number;
  is_active?: boolean;
  is_unlocked?: boolean;
  is_completed?: boolean;
  subChapters?: SubChapter[];
  sub_chapters?: SubChapter[];
  assessments?: any[];
}

interface ChapterProgress {
  chapter_id: number;
  name: string;
  is_unlocked: boolean;
  is_completed: boolean;
}

@Component({
  selector: 'app-course-player',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './course-player.html',
  styleUrls: ['./course-player.css']
})
export class CoursePlayer implements OnInit {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);

  levelId = signal<number>(1); // From route params
  userId = signal<number>(1);
  
  chapters = signal<Chapter[]>([]);
  activeChapterId = signal<number | null>(null);
  activeSubChapterId = signal<number | null>(null);
  
  // Computed values
  activeChapter = computed(() => {
    const id = this.activeChapterId();
    return id ? this.chapters().find(c => c.id === id) : null;
  });

  activeSubChapter = computed(() => {
    const subId = this.activeSubChapterId();
    const active = this.activeChapter();
    if (!active || !subId) return null;
    const subs = active.subChapters || active.sub_chapters || [];
    return subs.find(s => s.id === subId);
  });

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      if (params['levelId']) {
        this.levelId.set(+params['levelId']);
        this.loadProgress();
        this.loadChapters();
      }
    });

    // Also support query params
    this.route.queryParams.subscribe(params => {
      if (params['id']) {
        this.levelId.set(+params['id']);
        this.loadProgress();
        this.loadChapters();
      }
    });
  }

  loadProgress(): void {
    const url = `http://localhost:8000/api/users/${this.userId()}/levels/${this.levelId()}/chapters/progress`;
    this.http.get<{chapters: ChapterProgress[]}>(url).subscribe({
      next: (res) => {
        // Merge progress data with chapter data
        const progressMap = new Map(res.chapters.map(c => [c.chapter_id, c]));
        
        this.chapters.update(chapters => 
          chapters.map(ch => ({
            ...ch,
            is_unlocked: progressMap.get(ch.id)?.is_unlocked ?? true,
            is_completed: progressMap.get(ch.id)?.is_completed ?? false,
          }))
        );

        // Auto-select first unlocked chapter
        if (!this.activeChapterId()) {
          const firstUnlocked = this.chapters().find(c => c.is_unlocked);
          if (firstUnlocked) {
            this.selectChapter(firstUnlocked.id);
          }
        }
      }
    });
  }

  loadChapters(): void {
    const url = `http://localhost:8000/api/chapters?level_id=${this.levelId()}`;
    this.http.get<Chapter[]>(url).subscribe({
      next: (chapters) => {
        // Sort chapters by sort_order
        const sorted = chapters.sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0));
        this.chapters.set(sorted);
        
        // Load progress after chapters are loaded
        this.loadProgress();
      },
      error: (err) => console.error('Failed to load chapters:', err)
    });
  }

  selectChapter(id: number): void {
    const chapter = this.chapters().find(c => c.id === id);
    if (chapter && !chapter.is_unlocked) {
      alert('This chapter is locked! Please complete the previous chapter assessments.');
      return;
    }
    this.activeChapterId.set(id);
    // Auto-select first sub-chapter if available
    const subs = chapter?.subChapters || chapter?.sub_chapters || [];
    if (subs.length > 0) {
      this.activeSubChapterId.set(subs[0].id);
    } else {
      this.activeSubChapterId.set(null);
    }
  }

  selectSubChapter(id: number): void {
    this.activeSubChapterId.set(id);
  }

  getSubChapters(): SubChapter[] {
    return this.activeChapter()?.subChapters || this.activeChapter()?.sub_chapters || [];
  }
}
