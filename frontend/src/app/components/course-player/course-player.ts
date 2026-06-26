import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { gsap } from 'gsap';

interface Content {
  id: number;
  name: string;
  title?: string;
  text_content?: string;
  attachments?: any[];
  external_url?: any[];
  assessments?: any[];
  sort_order?: number;
  is_active?: boolean;
}

interface Chapter {
  id: number;
  name: string;
  contents: Content[];
  assessments?: any[];
  is_expanded?: boolean;
}

interface Level {
  id: number;
  name: string;
  chapters: Chapter[];
  is_expanded?: boolean;
}

interface CourseStructure {
  id: number;
  name: string;
  description?: string;
  levels: Level[];
}

import { RouterModule, Router } from '@angular/router';
import { ActivityRenderer } from '../activity-engine/activity-renderer/activity-renderer';
import { CourseService } from '../../services/course';

@Component({
  selector: 'app-course-player',
  standalone: true,
  imports: [CommonModule, RouterModule, ActivityRenderer],
  templateUrl: './course-player.html',
  styleUrls: ['./course-player.css']
})
export class CoursePlayer implements OnInit {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private courseService = inject(CourseService);

  courseId = signal<number | null>(null);
  userId = signal<number>(1);

  courseStructure = signal<CourseStructure | null>(null);
  activeContentId = signal<number | null>(null);
  fullContent = signal<Content | null>(null);
  isFullscreen = signal(false);
  currentView = signal<'levels' | 'map' | 'content' | 'activity'>('levels');
  currentActivityIndex = signal<number>(0);
  activeLevelId = signal<number | null>(null);
  activeChapterId = signal<number | null>(null);

  // Local progress mapping
  completedLevelIds = signal<number[]>([]);
  completedChapterIds = signal<number[]>([]);

  // Slide pagination for reading blocks
  currentContentPage = signal<number>(0);
  pageSize = 2;

  // Gamification stats
  hearts = signal<number>(5);
  coins = signal<number>(85);
  xp = signal<number>(1250);
  showGameOver = signal<boolean>(false);
  showCorrectSplash = signal<boolean>(false);
  showIncorrectSplash = signal<boolean>(false);

  // Mascot warning notifications
  mascotWarning = signal<string | null>(null);
  showMascotWarning = signal<boolean>(false);

  triggerMascotWarning(message: string) {
    this.mascotWarning.set(message);
    this.showMascotWarning.set(true);
    setTimeout(() => {
      this.showMascotWarning.set(false);
    }, 3000);
  }

  // Computed level selection
  selectedLevel = computed(() => {
    const structure = this.courseStructure();
    const levId = this.activeLevelId();
    if (!structure || !levId) return null;
    return structure.levels.find(l => l.id === levId) || null;
  });

  // Computed chapter selection inside the active level
  selectedChapter = computed(() => {
    const level = this.selectedLevel();
    const chapId = this.activeChapterId();
    if (!level || !chapId) return null;
    return level.chapters.find(c => c.id === chapId) || null;
  });

  // Flat chapters mapping for the selected level (roadmap layout)
  levelChaptersMap = computed(() => {
    const level = this.selectedLevel();
    const map = new Map<number, { globalNumber: number; globalIndex: number; xOffset: number }>();
    if (!level) return map;

    const pattern = [-100, -40, 40, 100, 40, -40];
    level.chapters.forEach((chapter, idx) => {
      const xOffset = pattern[idx % pattern.length];
      map.set(chapter.id, {
        globalNumber: idx + 1,
        globalIndex: idx,
        xOffset
      });
    });

    return map;
  });

  activeContent = computed(() => {
    const id = this.activeContentId();
    const full = this.fullContent();

    if (!id || !this.courseStructure()) return null;

    // If we have full content and its ID matches the active ID, return it
    if (full && full.id === id) {
      // Find chapter assessments to append and merge with content assessments
      for (const level of this.courseStructure()!.levels) {
        for (const chapter of level.chapters) {
          const topic = chapter.contents.find(c => c.id === id);
          if (topic) {
            const contentAssessments = full.assessments || [];
            const chapterAssessments = chapter.assessments || [];
            const allAssessments = [...contentAssessments, ...chapterAssessments];
            return { ...full, assessments: allAssessments };
          }
        }
      }
      return full;
    }

    // Fallback to sidebar structure (titles only) while loading
    for (const level of this.courseStructure()!.levels) {
      for (const chapter of level.chapters) {
        const content = chapter.contents.find(c => c.id === id);
        if (content) {
          return { ...content, assessments: chapter.assessments };
        }
      }
    }
    return null;
  });

  isJsonContent = computed(() => {
    const content = this.activeContent();
    if (!content || !content.text_content) return false;
    const trimmed = content.text_content.trim();
    return trimmed.startsWith('{') && trimmed.endsWith('}');
  });

  parsedBlocks = computed(() => {
    const content = this.activeContent();
    if (!content || !content.text_content) return [];
    try {
      const data = JSON.parse(content.text_content);
      return data.blocks || [];
    } catch (e) {
      console.warn('Failed to parse text_content as JSON blocks, rendering as HTML instead.');
      return [];
    }
  });

  readingBlocks = computed(() => {
    return this.parsedBlocks().filter((b: any) => b.type !== 'activity');
  });

  totalPages = computed(() => {
    return Math.ceil(this.readingBlocks().length / this.pageSize);
  });

  paginatedReadingBlocks = computed(() => {
    const page = this.currentContentPage();
    const blocks = this.readingBlocks();
    const start = page * this.pageSize;
    return blocks.slice(start, start + this.pageSize);
  });

  activityBlocks = computed(() => {
    return this.parsedBlocks().filter((b: any) => b.type === 'activity');
  });

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      const cid = params['courseId'] ? +params['courseId'] : null;
      if (cid && cid !== this.courseId()) {
        this.courseId.set(cid);
        this.loadStructure();
      }
    });

    this.route.queryParams.subscribe(params => {
      const qid = params['id'] ? +params['id'] : null;
      if (qid && qid !== this.courseId()) {
        this.courseId.set(qid);
        this.loadStructure();
      }
    });
  }

  loadStructure(): void {
    if (!this.courseId()) return;

    // Check if we have pre-fetched structure data in the cache
    if (this.courseService.cachedStructure && this.courseService.cachedStructure.id === this.courseId()) {
      const structure = this.courseService.cachedStructure;
      this.courseService.cachedStructure = null; // Clear from cache
      this.initializeStructure(structure);
    } else {
      const url = `http://localhost:8000/api/courses/${this.courseId()}/player-structure`;
      this.http.get<CourseStructure>(url).subscribe({
        next: (structure) => {
          this.initializeStructure(structure);
        },
        error: (err) => console.error('Failed to load course structure:', err)
      });
    }
  }

  initializeStructure(structure: CourseStructure): void {
    // Initialize expansion states
    structure.levels.forEach((l, idx) => {
      l.is_expanded = idx === 0;
      l.chapters.forEach((c, cidx) => {
        c.is_expanded = idx === 0 && cidx === 0;
      });
    });
    this.courseStructure.set(structure);
    this.loadLocalProgress();
  }

  loadLocalProgress(): void {
    const cid = this.courseId();
    if (!cid) return;
    const uid = this.userId();
    try {
      const levelsKey = `lang_app_completed_levels_${uid}_${cid}`;
      const chaptersKey = `lang_app_completed_chapters_${uid}_${cid}`;
      const storedLevels = localStorage.getItem(levelsKey);
      const storedChapters = localStorage.getItem(chaptersKey);
      this.completedLevelIds.set(storedLevels ? JSON.parse(storedLevels) : []);
      this.completedChapterIds.set(storedChapters ? JSON.parse(storedChapters) : []);
    } catch (e) {
      console.error('Failed to load local progress:', e);
    }
  }

  saveLocalProgress(): void {
    const cid = this.courseId();
    if (!cid) return;
    const uid = this.userId();
    try {
      const levelsKey = `lang_app_completed_levels_${uid}_${cid}`;
      const chaptersKey = `lang_app_completed_chapters_${uid}_${cid}`;
      localStorage.setItem(levelsKey, JSON.stringify(this.completedLevelIds()));
      localStorage.setItem(chaptersKey, JSON.stringify(this.completedChapterIds()));
    } catch (e) {
      console.error('Failed to save local progress:', e);
    }
  }

  isLevelUnlocked(levelId: number): boolean {
    const structure = this.courseStructure();
    if (!structure) return false;
    const index = structure.levels.findIndex(l => l.id === levelId);
    if (index <= 0) return true;
    const prevLevel = structure.levels[index - 1];
    return prevLevel.chapters.every(c => this.isChapterCompleted(c.id));
  }

  isChapterUnlocked(chapterId: number): boolean {
    const level = this.selectedLevel();
    if (!level) return false;
    const index = level.chapters.findIndex(c => c.id === chapterId);
    if (index <= 0) return true;
    const prevChapter = level.chapters[index - 1];
    return this.isChapterCompleted(prevChapter.id);
  }

  isChapterCompleted(chapterId: number): boolean {
    return this.completedChapterIds().includes(chapterId);
  }

  completeChapter(chapterId: number): void {
    if (!this.completedChapterIds().includes(chapterId)) {
      this.completedChapterIds.update(ids => [...ids, chapterId]);
    }
    const level = this.selectedLevel();
    if (level) {
      const allDone = level.chapters.every(c => this.isChapterCompleted(c.id));
      if (allDone && !this.completedLevelIds().includes(level.id)) {
        this.completedLevelIds.update(lids => [...lids, level.id]);
      }
    }
    this.saveLocalProgress();
  }

  goBack() {
    if (this.currentView() === 'levels') {
      this.router.navigate(['/dashboard']);
    } else if (this.currentView() === 'map') {
      this.goToLevels();
    } else if (this.currentView() === 'content') {
      if (this.activeContentId() !== null) {
        this.activeContentId.set(null);
      } else {
        this.goToMap();
      }
    } else if (this.currentView() === 'activity') {
      this.currentView.set('content');
    }
  }

  selectLevel(id: number) {
    if (!this.isLevelUnlocked(id)) {
      this.triggerMascotWarning('🔒 Level is locked! Complete all chapters of the previous level to unlock.');
      return;
    }
    this.activeLevelId.set(id);
    this.currentView.set('map');
  }

  selectChapterNode(id: number) {
    if (!this.isChapterUnlocked(id)) {
      this.triggerMascotWarning('🔒 Chapter is locked! Complete preceding chapters to unlock.');
      return;
    }
    this.activeChapterId.set(id);
    this.activeContentId.set(null);
    this.currentView.set('content');
  }

  goToLevels() {
    this.currentView.set('levels');
  }

  selectTopic(id: number): void {
    this.activeContentId.set(id);
    this.fullContent.set(null); // Reset while loading
    this.currentContentPage.set(0); // Reset page number on selection

    // Fetch full content details
    const url = `http://localhost:8000/api/contents/${id}`;
    this.http.get<Content>(url).subscribe({
      next: (content) => {
        this.fullContent.set(content);
        this.currentView.set('content'); // Switch to content overlay
      },
      error: (err) => console.error('Failed to load topic content:', err)
    });
  }

  goToMap(): void {
    this.currentView.set('map');
  }

  goToActivity(): void {
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.currentActivityIndex.set(0);
    this.currentView.set('activity');
  }

  nextContentPage() {
    if (this.currentContentPage() < this.totalPages() - 1) {
      this.currentContentPage.update(p => p + 1);
    }
  }

  prevContentPage() {
    this.currentContentPage.update(p => Math.max(0, p - 1));
  }

  onActivityAnswered(event: any) {
    if (event && event.isCorrect !== undefined) {
      if (event.isCorrect) {
        this.coins.update(c => c + 5);
        this.xp.update(x => x + 10);
        this.showCorrectSplash.set(true);
        setTimeout(() => this.showCorrectSplash.set(false), 1200);
      } else {
        this.hearts.update(h => Math.max(0, h - 1));
        this.showIncorrectSplash.set(true);
        setTimeout(() => this.showIncorrectSplash.set(false), 1200);
        if (this.hearts() === 0) {
          this.showGameOver.set(true);
        }
      }
    }
  }

  retryActivity() {
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.currentActivityIndex.set(0);
  }

  finishLesson() {
    const activeChapId = this.activeChapterId();
    if (activeChapId) {
      this.completeChapter(activeChapId);
    }
    this.goBack();
  }

  completeActiveChapterAndGoToMap() {
    const activeChapId = this.activeChapterId();
    if (activeChapId) {
      this.completeChapter(activeChapId);
    }
    this.goToMap();
  }

  nextActivityPage(): void {
    this.currentActivityIndex.update(v => v + 1);
  }

  prevActivityPage(): void {
    this.currentActivityIndex.update(v => Math.max(0, v - 1));
  }

  toggleLevel(level: Level): void {
    level.is_expanded = !level.is_expanded;
  }

  toggleChapter(chapter: Chapter): void {
    chapter.is_expanded = !chapter.is_expanded;
  }

  toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => {
        this.isFullscreen.set(true);
      }).catch(err => {
        console.error(`Error attempting to enable fullscreen: ${err.message}`);
      });
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().then(() => {
          this.isFullscreen.set(false);
        });
      }
    }
  }
}
