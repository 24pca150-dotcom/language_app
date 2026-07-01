import { Component, OnInit, OnDestroy, inject, signal, computed, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { forkJoin } from 'rxjs';

export interface LessonStep {
  type: 'video' | 'pdf' | 'reading' | 'activity' | 'assessment';
  title: string;
  data: any;
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
import { KidsDashboard } from '../kids-dashboard/kids-dashboard';
import { StudentDashboard } from '../student-dashboard/student-dashboard';
import confetti from 'canvas-confetti';
import { gsap } from 'gsap';
import { AudioService } from '../../services/audio.service';

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

@Component({
  selector: 'app-course-player',
  standalone: true,
  imports: [CommonModule, RouterModule, ActivityRenderer, KidsDashboard, StudentDashboard],
  templateUrl: './course-player.html',
  styleUrls: ['./course-player.css']
})
export class CoursePlayer implements OnInit, OnDestroy {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private courseService = inject(CourseService);
  private audioService = inject(AudioService);

  courseId = signal<number | null>(null);
  userId = signal<number>(1);

  courseStructure = signal<CourseStructure | null>(null);
  activeContentId = signal<number | null>(null);
  fullContent = signal<Content | null>(null);
  isFullscreen = signal(false);
  currentView = signal<'levels' | 'map' | 'content' | 'activity'>('levels');
  theme = signal<'kids' | 'student'>('kids'); // New theme signal
  currentActivityIndex = signal<number>(0);
  activeLevelId = signal<number | null>(null);
  activeChapterId = signal<number | null>(null);

  // Local progress mapping
  completedLevelIds = signal<number[]>([]);
  completedChapterIds = signal<number[]>([]);

  // Interactive Lesson State
  lessonSequence = signal<LessonStep[]>([]);
  currentStepIndex = signal<number>(0);
  learningMode = signal<'strict' | 'easy'>('easy'); // Strict mode prevents skipping activities
  isStepCompleted = signal<boolean>(false);
  isVideoCompleted = signal<boolean>(false);
  lessonFinished = signal<boolean>(false);

  // Slide pagination for reading blocks (inside reading step)
  currentContentPage = signal<number>(0);
  pageSize = 2;

  // Gamification stats
  hearts = signal<number>(5);
  coins = signal<number>(85);
  xp = signal<number>(1250);
  showGameOver = signal<boolean>(false);
  showCorrectSplash = signal<boolean>(false);
  showIncorrectSplash = signal<boolean>(false);
  activityFeedbackState = signal<'correct' | 'incorrect' | null>(null);

  // Typewriter State for Reading
  typedContent = signal<string>('');
  typingTimeout: any;
  activeUtterances: SpeechSynthesisUtterance[] = [];
  speechStartTimeout: any;

  rawReadingHtml = computed(() => {
    const step = this.currentStep();
    if (step && step.type === 'reading') {
      if (step.data.isJson) {
        const pageData = step.data.blocks[this.currentContentPage()];
        if (!pageData) return '';

        const renderBlock = (block: any) => {
          if (block.type === 'paragraph') return `<div class="opacity-75 mb-4">${block.data.text}</div>`;
          else if (block.type === 'header') return `<h3 class="fw-bold text-primary mb-3" style="font-size: 1.7rem;">${block.data.text}</h3>`;
          else if (block.type === 'list') {
            const tag = block.data.style === 'ordered' ? 'ol' : 'ul';
            const listItems = block.data.items.map((i: any) => {
              const text = typeof i === 'object' && i !== null ? (i.content || '') : i;
              return `<li class="mb-2">${text}</li>`;
            }).join('');
            return `<${tag} class="mb-4 ps-4 opacity-75 text-start d-inline-block">${listItems}</${tag}>`;
          }
          else if (block.type === 'image') {
            const url = block.data.file?.url || block.data.url || '';
            const caption = block.data.caption || '';
            return `<div class="text-center mb-4"><img src="${url}" alt="${caption}" class="img-fluid rounded shadow-sm" style="max-height: 350px; object-fit: contain;">${caption ? `<div class="text-muted small mt-2">${caption}</div>` : ''}</div>`;
          }
          else if (block.type === 'table') {
            const withHeadings = block.data.withHeadings;
            const rows = block.data.content || [];
            let html = `<div class="table-responsive w-100 mb-4"><table class="table table-bordered shadow-sm" style="border-radius: 12px; overflow: hidden; background: white;">`;
            rows.forEach((row: string[], index: number) => {
              if (index === 0 && withHeadings) {
                html += `<thead style="background: #fef08a;"><tr>` + row.map(cell => `<th class="p-2 text-dark fs-5 fw-bold border-bottom-0">${cell}</th>`).join('') + `</tr></thead><tbody>`;
              } else {
                if (index === 0 && !withHeadings) html += `<tbody>`;
                html += `<tr>` + row.map(cell => `<td class="p-2 fs-6 opacity-75">${cell}</td>`).join('') + `</tr>`;
              }
            });
            if (rows.length > 0) html += `</tbody>`;
            html += `</table></div>`;
            return html;
          }
          return '';
        };

        if (Array.isArray(pageData)) {
          return pageData.map((b: any) => renderBlock(b)).join('');
        } else {
          return renderBlock(pageData);
        }
      } else {
        return `<div class="fw-bold opacity-75" style="font-size: 1.8rem; line-height: 1.6; font-family: 'Nunito', 'Comic Sans MS', sans-serif;">${step.data.text}</div>`;
      }
    }
    return '';
  });

  constructor() {
    effect(() => {
      const html = this.rawReadingHtml();
      if (html) {
        this.speakText(html);
      } else {
        this.stopSpeech();
        this.typedContent.set('');
      }
    }, { allowSignalWrites: true });

    // Initialize/warm-up speech synthesis voices
    if (typeof window !== 'undefined' && window.speechSynthesis) {
      window.speechSynthesis.getVoices();
      window.speechSynthesis.onvoiceschanged = () => {
        window.speechSynthesis.getVoices();
      };
    }
  }

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

  // Computed properties for the new Lesson Player
  currentStep = computed(() => {
    const seq = this.lessonSequence();
    const idx = this.currentStepIndex();
    if (seq.length > 0 && idx >= 0 && idx < seq.length) {
      return seq[idx];
    }
    return null;
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
    this.startLesson(id);
  }

  startLesson(chapterId: number) {
    this.activeChapterId.set(chapterId);
    this.currentView.set('content'); // Using 'content' view for the new Full-Screen Lesson Player
    this.lessonSequence.set([]);
    this.currentStepIndex.set(0);
    this.isVideoCompleted.set(false);
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.lessonFinished.set(false);
    this.activityFeedbackState.set(null);

    const chapter = this.selectedChapter();
    if (!chapter) return;

    const contentIds = chapter.contents.map(c => c.id);
    if (contentIds.length === 0) {
      this.generateLessonSequence([], chapter.assessments || []);
      return;
    }

    const requests = contentIds.map(id => this.http.get<Content>(`http://localhost:8000/api/contents/${id}`));
    forkJoin(requests).subscribe({
      next: (fullContents) => {
        this.generateLessonSequence(fullContents, chapter.assessments || []);
      },
      error: (err) => console.error('Failed to load chapter contents', err)
    });
  }

  generateLessonSequence(contents: Content[], chapterAssessments: any[]) {
    const steps: LessonStep[] = [];

    contents.forEach(content => {
      // Temporary Fix: Inject Homophones Video if it's content ID 1
      if (content.id === 1) {
        steps.push({
          type: 'video',
          title: 'Homophones Lesson',
          data: 'assets/Homophones video .mp4'
        });
      }

      // 1. External Media (Video)
      if (content.external_url && content.external_url.length > 0) {
        steps.push({
          type: 'video',
          title: content.title || content.name,
          data: content.external_url[0] // Assume first URL is the video link
        });
      }

      // 2. Document (PDF)
      if (content.attachments && content.attachments.length > 0) {
        steps.push({
          type: 'pdf',
          title: content.title || content.name + ' - Document',
          data: content.attachments
        });
      }

      // 3. Text Content (Reading & Activities)
      if (content.text_content) {
        let isJson = false;
        let blocks = [];
        const trimmed = content.text_content.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          try {
            const data = JSON.parse(trimmed);
            blocks = data.blocks || [];
            isJson = true;
          } catch (e) { }
        }

        if (isJson) {
          const videoBlocks = blocks.filter((b: any) => b.type === 'video' || b.type === 'embed');
          const readingBlocks = blocks.filter((b: any) => b.type !== 'activity' && b.type !== 'video' && b.type !== 'embed');
          const activityBlocks = blocks.filter((b: any) => b.type === 'activity');

          if (videoBlocks.length > 0) {
            videoBlocks.forEach((block: any, idx: number) => {
              steps.push({
                type: 'video',
                title: (content.title || content.name) + (videoBlocks.length > 1 ? ` - Video ${idx + 1}` : ' - Video'),
                data: block.data.url || block.data.embed
              });
            });
          }

          if (readingBlocks.length > 0) {
            let groupedBlocks = [];
            let currentGroup = [];
            for (let i = 0; i < readingBlocks.length; i++) {
              let b = readingBlocks[i];
              currentGroup.push(b);
              if (currentGroup.length >= 3 && b.type !== 'header') {
                groupedBlocks.push(currentGroup);
                currentGroup = [];
              }
            }
            if (currentGroup.length > 0) {
              groupedBlocks.push(currentGroup);
            }

            steps.push({
              type: 'reading',
              title: content.title || content.name,
              data: { isJson: true, blocks: groupedBlocks }
            });
          }
          if (activityBlocks.length > 0) {
            activityBlocks.forEach((block: any, idx: number) => {
              let actName = 'Unknown';
              if (block.data && block.data.type) {
                actName = block.data.type.split('-').map((w: string) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
                if (block.data.type === 'mcq') actName = 'Multiple Choice';
              }

              steps.push({
                type: 'activity',
                title: `${idx + 1}. Activity - ${actName}`,
                data: block
              });
            });
          }
        } else {
          steps.push({
            type: 'reading',
            title: content.title || content.name,
            data: { isJson: false, text: content.text_content }
          });
        }
      }

      // 4. Content Assessments
      if (content.assessments && content.assessments.length > 0) {
        steps.push({
          type: 'assessment',
          title: content.title || content.name + ' - Quiz',
          data: content.assessments
        });
      }
    });

    if (chapterAssessments.length > 0) {
      steps.push({
        type: 'assessment',
        title: 'Chapter Quiz',
        data: chapterAssessments
      });
    }

    this.lessonSequence.set(steps);
    this.evaluateStepCompletion();
  }

  evaluateStepCompletion() {
    const step = this.currentStep();
    if (!step) return;

    if (this.learningMode() === 'easy') {
      this.isStepCompleted.set(true); // Easy mode allows skipping anything
      return;
    }

    if (step.type === 'pdf') {
      this.isStepCompleted.set(true);
    } else if (step.type === 'reading') {
      if (step.data.isJson && step.data.blocks && step.data.blocks.length > 0) {
        this.isStepCompleted.set(this.currentContentPage() >= step.data.blocks.length - 1);
      } else {
        this.isStepCompleted.set(true);
      }
    } else if (step.type === 'video') {
      this.isStepCompleted.set(this.isVideoCompleted());
    } else {
      // Activities and assessments MUST be completed
      this.isStepCompleted.set(false);
    }
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
    const step = this.currentStep();
    if (step && step.type === 'reading' && step.data.isJson && step.data.blocks) {
      if (this.currentContentPage() < step.data.blocks.length - 1) {
        this.currentContentPage.update(p => p + 1);
        this.evaluateStepCompletion();
      }
    }
  }

  prevContentPage() {
    this.currentContentPage.update(p => Math.max(0, p - 1));
    this.evaluateStepCompletion();
  }

  onActivityAnswered(event: any) {
    if (event && event.isCorrect !== undefined) {
      this.activityFeedbackState.set(event.isCorrect ? 'correct' : 'incorrect');
      if (event.isCorrect) {
        this.audioService.playSuccess();
        confetti({
          particleCount: 100,
          spread: 70,
          origin: { y: 0.8 },
          colors: ['#4ade80', '#fcd34d', '#3b82f6']
        });

        this.coins.update(c => c + 5);
        this.xp.update(x => x + 10);
        this.isStepCompleted.set(true);

        // GSAP Micro-interaction: Pop the stats in the HUD & Animate Mascot
        setTimeout(() => {
          gsap.fromTo('.stat-badge',
            { scale: 1.3, boxShadow: '0 0 20px #fcd34d' },
            { scale: 1, boxShadow: 'none', duration: 0.8, ease: 'elastic.out(1, 0.3)', stagger: 0.1 }
          );

          // Joyful mascot jump
          gsap.fromTo('.mascot-happy',
            { y: 50, scaleY: 0.7, rotation: -15 },
            { y: 0, scaleY: 1.1, rotation: 10, duration: 0.6, ease: 'back.out(1.7)' }
          );
          // Continuous floating joy
          gsap.to('.mascot-happy', {
            y: -8, rotation: 0, scaleY: 1, duration: 1.5, repeat: -1, yoyo: true, ease: 'sine.inOut', delay: 0.6
          });
        }, 50);
      } else {
        this.audioService.playError();
        this.hearts.update(h => Math.max(0, h - 1));

        // GSAP Mascot Shake & Dizzy
        setTimeout(() => {
          gsap.fromTo('.mascot-sad',
            { x: -15, rotation: -20 },
            { x: 15, rotation: 20, duration: 0.1, repeat: 5, yoyo: true, ease: 'sine.inOut' }
          );
          gsap.to('.mascot-sad', { x: 0, rotation: 0, duration: 0.3, delay: 0.6 });
        }, 50);
        if (this.hearts() === 0) {
          this.showGameOver.set(true);
        }
      }
    }
  }

  continueFromFeedback() {
    const state = this.activityFeedbackState();
    this.activityFeedbackState.set(null);

    if (state === 'correct') {
      this.nextLessonStep();
    }
  }

  retryActivity() {
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.activityFeedbackState.set(null);
    // Restart current step
    this.evaluateStepCompletion();
  }

  onVideoEnded() {
    this.isVideoCompleted.set(true);
    this.isStepCompleted.set(true);
    // Auto progress to next step
    this.nextLessonStep();
  }

  nextLessonStep() {
    const currentIdx = this.currentStepIndex();
    if (currentIdx < this.lessonSequence().length - 1) {
      this.currentStepIndex.set(currentIdx + 1);
      this.isVideoCompleted.set(false);
      this.evaluateStepCompletion();
      this.currentContentPage.set(0);
      this.activityFeedbackState.set(null);
      // Cancel speech if they move to next step
      this.stopSpeech();
    } else {
      this.lessonFinished.set(true);
    }
  }

  prevLessonStep() {
    const currentIdx = this.currentStepIndex();
    if (currentIdx > 0) {
      this.currentStepIndex.set(currentIdx - 1);
      this.evaluateStepCompletion();
      this.currentContentPage.set(0);
      this.lessonFinished.set(false);
      this.activityFeedbackState.set(null);
      this.stopSpeech();
    }
  }

  stopSpeech() {
    if (typeof window !== 'undefined' && window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }
    this.activeUtterances = [];
    clearTimeout(this.speechStartTimeout);
  }

  speakText(text: string) {
    if (!text) return;

    // Cancel any ongoing speech
    this.stopSpeech();

    // Parse HTML to clean speech text with proper punctuation/pauses
    let cleanText = '';
    try {
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = text;

      const parts: string[] = [];
      const traverse = (node: Node) => {
        if (node.nodeType === Node.TEXT_NODE) {
          const content = node.textContent?.trim();
          if (content) {
            parts.push(content);
          }
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          const tagName = (node as Element).tagName.toLowerCase();

          if (tagName === 'li') {
            parts.push(', ');
          }

          for (let i = 0; i < node.childNodes.length; i++) {
            traverse(node.childNodes[i]);
          }

          if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'li', 'tr'].includes(tagName)) {
            parts.push('. ');
          }
        }
      };

      traverse(tempDiv);
      cleanText = parts.join(' ')
        .replace(/\s+/g, ' ')
        .replace(/\.\s*\./g, '.')
        .replace(/,\s*\./g, '.')
        .trim();
    } catch (e) {
      // Fallback to regex if DOM parsing fails
      cleanText = text.replace(/<[^>]*>?/gm, '');
    }

    if (!cleanText) return;

    // Check if the text is Tamil
    const isTamil = /[\u0B80-\u0BFF]/.test(cleanText);

    // Setup safe starting logic for the typewriter
    let typewriterStarted = false;
    const startTypewriterSafely = () => {
      if (typewriterStarted) return;
      typewriterStarted = true;
      this.startTypewriter(text, isTamil);
    };

    // Fallback: If voice speech start event is delayed/blocked, start typing after 800ms
    this.speechStartTimeout = setTimeout(startTypewriterSafely, 800);

    // Split cleanText into sentences for natural rhythm/pauses
    const rawSentences = cleanText.split(/([.?!:;]+)/);
    const sentences: string[] = [];
    for (let i = 0; i < rawSentences.length; i += 2) {
      const textPart = rawSentences[i]?.trim();
      const delim = rawSentences[i + 1] || '';
      if (textPart) {
        sentences.push(textPart + (delim ? delim + ' ' : ''));
      }
    }

    if (sentences.length === 0) return;

    // Helper to score Tamil voices for naturalness, quality, and clarity
    const getTamilVoiceScore = (name: string): number => {
      let score = 0;
      const lower = name.toLowerCase();
      // Prioritize kid/girl voices
      if (lower.includes('kid') || lower.includes('child') || lower.includes('junior') || lower.includes('girl') || lower.includes('young')) score += 150;
      if (lower.includes('natural') || lower.includes('neural')) score += 100;
      if (lower.includes('online')) score += 50;
      if (lower.includes('google')) score += 40;
      if (lower.includes('lekha')) score += 30;
      if (lower.includes('heera')) score += 25;
      if (lower.includes('female') || lower.includes('girl') || lower.includes('woman') || lower.includes('pallavi') || lower.includes('kalpana') || lower.includes('siri')) score += 20;
      if (lower.includes('valluvar')) score += 15;
      if (lower.includes('microsoft')) score += 10;
      return score;
    };

    // Helper to score English voices
    const getEnglishVoiceScore = (name: string): number => {
      let score = 0;
      const lower = name.toLowerCase();
      // Prioritize kid/girl voices
      if (lower.includes('kid') || lower.includes('child') || lower.includes('junior') || lower.includes('girl') || lower.includes('young')) score += 150;
      if (lower.includes('natural') || lower.includes('neural')) score += 100;
      if (lower.includes('online')) score += 50;
      if (lower.includes('google')) score += 40;
      if (lower.includes('female') || lower.includes('girl') || lower.includes('woman') || lower.includes('zira') || lower.includes('samantha') || lower.includes('aria') || lower.includes('jenny') || lower.includes('siri')) score += 30;
      if (lower.includes('microsoft') || lower.includes('david')) score += 10;
      return score;
    };

    // Queue each sentence as a separate utterance for natural pause intervals
    sentences.forEach((sentence, idx) => {
      const utterance = new SpeechSynthesisUtterance(sentence);

      if (isTamil) {
        utterance.lang = 'ta-IN';
        const voices = window.speechSynthesis.getVoices();
        const tamilVoices = voices.filter(v => v.lang.startsWith('ta') || v.name.toLowerCase().includes('tamil'));
        if (tamilVoices.length > 0) {
          const bestTamilVoice = tamilVoices.reduce((prev, curr) => {
            return getTamilVoiceScore(curr.name) > getTamilVoiceScore(prev.name) ? curr : prev;
          });
          utterance.voice = bestTamilVoice;
        }
      } else {
        utterance.lang = 'en-US';
        const voices = window.speechSynthesis.getVoices();
        const englishVoices = voices.filter(v => v.lang.startsWith('en'));
        if (englishVoices.length > 0) {
          const bestEnglishVoice = englishVoices.reduce((prev, curr) => {
            return getEnglishVoiceScore(curr.name) > getEnglishVoiceScore(prev.name) ? curr : prev;
          });
          utterance.voice = bestEnglishVoice;
        }
      }

      // Extremely natural rates for learning
      utterance.rate = isTamil ? 0.82 : 0.85;
      utterance.pitch = 1.35; // Higher pitch simulating a kid female voice

      // Keep reference to prevent garbage collection in Chromium browsers
      this.activeUtterances.push(utterance);

      // Trigger typewriter only when speech actually starts
      if (idx === 0) {
        utterance.onstart = () => {
          clearTimeout(this.speechStartTimeout);
          startTypewriterSafely();
        };
      }

      utterance.onend = () => {
        this.activeUtterances = this.activeUtterances.filter(u => u !== utterance);
      };
      utterance.onerror = () => {
        clearTimeout(this.speechStartTimeout);
        startTypewriterSafely();
        this.activeUtterances = this.activeUtterances.filter(u => u !== utterance);
      };

      window.speechSynthesis.speak(utterance);
    });
  }

  ngOnDestroy() {
    this.stopSpeech();
    clearTimeout(this.typingTimeout);
  }

  startTypewriter(htmlContent: string, isTamil: boolean = false) {
    this.typedContent.set('');
    clearTimeout(this.typingTimeout);

    let i = 0;
    let isTag = false;
    let currentText = '';

    // Calculate typing speed to match spoken voice rate
    const charDelay = isTamil ? Math.random() * 30 + 55 : Math.random() * 20 + 35;
    const sentenceDelay = isTamil ? 900 : 600;
    const commaDelay = isTamil ? 450 : 300;

    const type = () => {
      if (i < htmlContent.length) {
        let char = htmlContent.charAt(i);
        if (char === '<') isTag = true;

        currentText += char;
        i++;

        if (isTag) {
          while (i < htmlContent.length && htmlContent.charAt(i - 1) !== '>') {
            currentText += htmlContent.charAt(i);
            i++;
          }
          isTag = false;
          this.typedContent.set(currentText);
          this.typingTimeout = setTimeout(type, 0);
        } else {
          this.typedContent.set(currentText);
          const delay = char === '.' || char === '!' || char === '?' ? sentenceDelay : (char === ',' ? commaDelay : charDelay);
          this.typingTimeout = setTimeout(type, delay);
        }
      }
    };

    type();
  }

  finishLesson() {
    this.audioService.playSuccess();

    // Mega Confetti Burst!
    const duration = 3 * 1000;
    const end = Date.now() + duration;

    const frame = () => {
      confetti({
        particleCount: 5,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: ['#4ade80', '#fcd34d', '#3b82f6', '#ec4899', '#8b5cf6']
      });
      confetti({
        particleCount: 5,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: ['#4ade80', '#fcd34d', '#3b82f6', '#ec4899', '#8b5cf6']
      });

      if (Date.now() < end) {
        requestAnimationFrame(frame);
      }
    };
    frame();

    const activeChapId = this.activeChapterId();
    if (activeChapId) {
      this.completeChapter(activeChapId);
    }

    // Wait for confetti to finish before navigating away
    setTimeout(() => {
      this.goToMap();
    }, 3500);
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
