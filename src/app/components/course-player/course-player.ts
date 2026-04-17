import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';

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
  
  chapters = signal<ChapterProgress[]>([]);
  activeChapterId = signal<number | null>(null);

  ngOnInit(): void {
    this.route.params.subscribe(params => {
        if(params['levelId']) {
            this.levelId.set(+params['levelId']);
            this.loadProgress();
        }
    });
  }

  loadProgress(): void {
    const url = `http://localhost:8000/api/users/${this.userId()}/levels/${this.levelId()}/chapters/progress`;
    this.http.get<{chapters: ChapterProgress[]}>(url).subscribe({
      next: (res) => {
        this.chapters.set(res.chapters);
        if (!this.activeChapterId() && res.chapters.length > 0) {
            const firstUnlocked = res.chapters.find(c => c.is_unlocked);
            if(firstUnlocked) this.selectChapter(firstUnlocked.chapter_id);
        }
      }
    });
  }

  selectChapter(id: number): void {
    const chapter = this.chapters().find(c => c.chapter_id === id);
    if (chapter && !chapter.is_unlocked) {
        alert('This chapter is locked! Please complete the previous chapter assessments.');
        return;
    }
    this.activeChapterId.set(id);
  }
}
