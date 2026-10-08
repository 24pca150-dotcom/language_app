import { Component, OnInit, OnDestroy, inject, signal, computed, effect } from '@angular/core';
import { environment } from '../../../environments/environment';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { forkJoin, of, Observable } from 'rxjs';
import { switchMap, map, catchError } from 'rxjs/operators';

import { CourseStructure, Level, Chapter, Content } from '../../models/course-structure.model';

export interface LessonStep {
  type: 'video' | 'pdf' | 'reading' | 'activity' | 'assessment';
  title: string;
  data: any;
}

import { RouterModule, Router } from '@angular/router';
import { ActivityRenderer } from '../activity-engine/activity-renderer/activity-renderer';
import { CourseService } from '../../services/course';
import { KidsDashboard } from '../kids-dashboard/kids-dashboard';
import { KidsLessonPlayer } from '../kids-lesson-player/kids-lesson-player';
import confetti from 'canvas-confetti';
import { gsap } from 'gsap';
import { AudioService } from '../../services/audio.service';
import { AuthService } from '../../services/auth';
import { CloudTransitionService } from '../../services/cloud-transition.service';

@Component({
  selector: 'app-course-player',
  standalone: true,
  imports: [CommonModule, RouterModule, KidsDashboard, KidsLessonPlayer],
  templateUrl: './course-player.html',
  styleUrls: ['./course-player.css']
})
export class CoursePlayer implements OnInit, OnDestroy {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private courseService = inject(CourseService);
  private audioService = inject(AudioService);
  private authService = inject(AuthService);
  private cloudTransition = inject(CloudTransitionService);

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

  completedLevelIds = signal<number[]>([]);
  completedChapterIds = signal<number[]>([]);

  lessonSequence = signal<LessonStep[]>([]);
  isLoadingLesson = signal<boolean>(true);
  currentStepIndex = signal<number>(0);
  highestStepIndex = signal<number>(0);
  learningMode = signal<'strict' | 'easy'>('easy'); // Strict mode prevents skipping activities
  isStepCompleted = signal<boolean>(false);
  isVideoCompleted = signal<boolean>(false);
  lessonFinished = signal<boolean>(false);

  hearts = signal<number>(5);
  coins = signal<number>(85);
  xp = signal<number>(1250);
  showGameOver = signal<boolean>(false);
  showCorrectSplash = signal<boolean>(false);
  showIncorrectSplash = signal<boolean>(false);
  activityFeedbackState = signal<'correct' | 'incorrect' | null>(null);

  // 🌿 Left Navigation Sidebar Sliding State (Auto-collapsed on course player page)
  isNavSidebarOpen = signal<boolean>(false);

  toggleNavSidebar() {
    this.isNavSidebarOpen.update(v => !v);
  }

  closeNavSidebar() {
    this.isNavSidebarOpen.set(false);
  }

  constructor() {
    // Keep highestStepIndex synchronized with the maximum reached index
    effect(() => {
      const idx = this.currentStepIndex();
      if (idx > this.highestStepIndex()) {
        this.highestStepIndex.set(idx);
      }
    });

    effect(() => {
      const idx = this.highestStepIndex();
      const chapterId = this.activeChapterId();
      const courseId = this.courseId();
      const userId = this.userId();
      if (chapterId && courseId) {
        const resumeKey = `lang_app_resume_step_${userId}_${courseId}_${chapterId}`;
        if (this.lessonFinished()) {
          localStorage.removeItem(resumeKey);
        } else {
          localStorage.setItem(resumeKey, idx.toString());
        }
      }
    });
  }

  mascotWarning = signal<string | null>(null);
  showMascotWarning = signal<boolean>(false);

  triggerMascotWarning(message: string) {
    this.mascotWarning.set(message);
    this.showMascotWarning.set(true);
    setTimeout(() => {
      this.showMascotWarning.set(false);
    }, 3000);
  }

  selectedLevel = computed(() => {
    const structure = this.courseStructure();
    const levId = this.activeLevelId();
    if (!structure || !levId) return null;
    return structure.levels.find(l => l.id === levId) || null;
  });

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

    if (full && full.id === id) {
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


  currentStep = computed(() => {
    const seq = this.lessonSequence();
    const idx = this.currentStepIndex();
    if (seq.length > 0 && idx >= 0 && idx < seq.length) {
      return seq[idx];
    }
    return null;
  });

  ngOnInit(): void {
    // Determine theme based on user's age from DOB
    const user = this.authService.getUser();
    console.log('[DEBUG] course-player ngOnInit user:', user);
    if (user) {
      this.userId.set(user.id);
    }
    // Always use the kids theme (green game world map with winding path line)
    this.theme.set('kids');

    this.route.params.subscribe(params => {
      const cid = params['courseId'] ? +params['courseId'] : null;
      const returningFromAssessment = !!localStorage.getItem('lang_app_assessment_done');
      if (cid && cid !== this.courseId()) {
        this.courseId.set(cid);
        this.loadStructure();
      } else if (cid && cid === this.courseId() && returningFromAssessment) {
        // Same course, returning from assessment — just refresh DB progress
        localStorage.removeItem('lang_app_assessment_done');
        this.loadDatabaseProgress();
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

  getAgeFromDob(dob: string | null | undefined): number | null {
    if (!dob) return null;
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  loadStructure(): void {
    if (!this.courseId()) return;

    if (this.courseService.cachedStructure && this.courseService.cachedStructure.id === this.courseId()) {
      const structure = this.courseService.cachedStructure;
      this.courseService.cachedStructure = null; // Clear from cache
      this.initializeStructure(structure);
    } else {
      const url = `${environment.apiUrl}/courses/${this.courseId()}/player-structure`;
      this.http.get<CourseStructure>(url).subscribe({
        next: (structure) => {
          this.initializeStructure(structure);
        },
        error: (err) => console.error('Failed to load course structure:', err)
      });
    }
  }

  initializeStructure(structure: CourseStructure): void {
    structure.levels.forEach((l, idx) => {
      l.is_expanded = idx === 0;
      l.chapters.forEach((c, cidx) => {
        c.is_expanded = idx === 0 && cidx === 0;
      });
    });
    this.courseStructure.set(structure);
    if (structure.levels && structure.levels.length > 0) {
      this.activeLevelId.set(structure.levels[0].id);
      this.currentView.set('levels');
    }
    this.loadDatabaseProgress();
  }

  loadDatabaseProgress(): void {
    this.http.get<any>(`${environment.apiUrl}/student/dashboard`).subscribe({
      next: (stats) => {
        if (stats) {
          if (stats.xp_points !== undefined) this.xp.set(stats.xp_points);
          if (stats.gems !== undefined) this.coins.set(stats.gems);

          if (stats.completed_chapter_ids) {
            this.completedChapterIds.set(stats.completed_chapter_ids);
            console.log('[DEBUG] loaded completed chapters 100% from DB:', stats.completed_chapter_ids);
          }
        }
      },
      error: (err) => console.error('Failed to load progress from backend database:', err)
    });
  }

  isLevelUnlocked(levelId: number): boolean {
    return true;
  }

  isChapterUnlocked(chapterId: number): boolean {
    return true;
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

    // Persist progress directly to the backend database
    this.http.post(`${environment.apiUrl}/chapters/${chapterId}/complete`, {}).subscribe({
      next: (res) => {
        console.log('Backend database progress updated successfully:', res);
        this.loadDatabaseProgress(); // Refresh stats (XP, gems, completed chapters) from database!
      },
      error: (err) => console.error('Failed to sync progress to backend database:', err)
    });
  }

  completeContent(chapterId: number, contentId: number): void {
    if (!chapterId || !contentId) return;
    this.http.post(`${environment.apiUrl}/chapters/${chapterId}/contents/${contentId}/complete`, {}).subscribe({
      next: (res) => {
        console.log(`Content ${contentId} in Chapter ${chapterId} completed:`, res);
        this.loadDatabaseProgress();
      },
      error: (err) => console.error('Failed to mark content as completed:', err)
    });
  }


  goBack() {
    if (this.currentView() === 'content') {
      if (this.activeContentId() !== null) {
        this.activeContentId.set(null);
      }
      this.goToMap();
    } else if (this.currentView() === 'activity') {
      this.currentView.set('content');
    } else if (this.currentView() === 'map') {
      this.goToLevels();
    } else {
      this.router.navigate(['/learn/courses']);
    }
  }

  selectLevel(id: number) {
    if (!this.isLevelUnlocked(id)) {
      this.triggerMascotWarning('🔒 Level is locked! Complete all chapters of the previous level to unlock.');
      return;
    }
    this.cloudTransition.triggerTransition(() => {
      this.activeLevelId.set(id);
      this.currentView.set('map');
    });
  }

  selectChapterNode(id: number) {
    if (!this.isChapterUnlocked(id)) {
      this.triggerMascotWarning('🔒 Chapter is locked! Complete preceding chapters to unlock.');
      return;
    }
    this.cloudTransition.triggerTransition(() => {
      this.startLesson(id);
    });
  }

  resolveActivityReferences(contents: Content[]): Observable<Content[]> {
    const referencePositions: Array<{ contentIdx: number, blockIdx: number, refId: number }> = [];
    const uniqueIds = new Set<number>();

    contents.forEach((content, contentIdx) => {
      if (content.text_content) {
        const trimmed = content.text_content.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          try {
            const parsed = JSON.parse(trimmed);
            const blocks = parsed.blocks || [];
            blocks.forEach((block: any, blockIdx: number) => {
              if (block.type === 'activity' && block.data && block.data.type === 'activity_reference') {
                const refId = block.data.activityReferenceId;
                if (refId) {
                  referencePositions.push({ contentIdx, blockIdx, refId });
                  uniqueIds.add(refId);
                }
              }
            });
          } catch (e) { }
        }
      }
    });

    if (uniqueIds.size === 0) {
      return of(contents);
    }

    const idsArray = Array.from(uniqueIds);
    return this.http.get<any[]>(`${environment.apiUrl}/activities`, { params: { ids: idsArray.join(',') } }).pipe(
      map(activities => {
        const activityMap = new Map<number, any>();
        activities.forEach(act => {
          activityMap.set(act.id, act);
        });

        referencePositions.forEach(pos => {
          const act = activityMap.get(pos.refId);
          if (!act) return;
          const content = contents[pos.contentIdx];
          if (!content.text_content) return;
          try {
            const parsed = JSON.parse(content.text_content);
            const block = parsed.blocks[pos.blockIdx];
            const realData = typeof act.data_json === 'string' ? JSON.parse(act.data_json) : act.data_json;

            block.data = {
              ...realData,
              type: act.type,
              title: act.title
            };
            content.text_content = JSON.stringify(parsed);
          } catch (e) { }
        });
        return contents;
      }),
      catchError(err => {
        console.error('Failed to resolve activity references', err);
        return of(contents);
      })
    );
  }

  startLesson(chapterId: number) {
    this.activeChapterId.set(chapterId);
    this.currentView.set('content'); // Using 'content' view for the new Full-Screen Lesson Player
    this.lessonSequence.set([]);
    this.isLoadingLesson.set(true);

    const resumeKey = `lang_app_resume_step_${this.userId()}_${this.courseId()}_${chapterId}`;
    const savedIndex = localStorage.getItem(resumeKey);
    const startIndex = savedIndex ? parseInt(savedIndex, 10) : 0;
    this.currentStepIndex.set(startIndex);
    this.highestStepIndex.set(startIndex);

    this.isVideoCompleted.set(false);
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.lessonFinished.set(false);
    this.activityFeedbackState.set(null);

    // Fetch the full chapter details including contents and assessments in a single request
    this.http.get<any>(`${environment.apiUrl}/chapters/${chapterId}`).pipe(
      switchMap(chapterData => {
        const contents: Content[] = (chapterData.contents || [])
          .filter((c: any) => c.is_active !== false)
          .sort((a: any, b: any) => (a.sort_order || 0) - (b.sort_order || 0));

        return this.resolveActivityReferences(contents).pipe(
          map(resolvedContents => ({
            contents: resolvedContents,
            assessments: chapterData.assessments || []
          }))
        );
      })
    ).subscribe({
      next: (result) => {
        this.generateLessonSequence(result.contents, result.assessments);
      },
      error: (err) => {
        console.error('Failed to load chapter contents', err);
        this.isLoadingLesson.set(false);
      }
    });
  }

  generateLessonSequence(contents: Content[], chapterAssessments: any[]) {
    const steps: LessonStep[] = [];

    contents.forEach(content => {
      if (content.id === 1) {
        steps.push({
          type: 'video',
          title: 'Homophones Lesson',
          data: 'assets/Homophones video .mp4'
        });
      }

      if (content.external_url && content.external_url.length > 0) {
        steps.push({
          type: 'video',
          title: content.title || content.name,
          data: content.external_url[0] // Assume first URL is the video link
        });
      }

      if (content.attachments && content.attachments.length > 0) {
        steps.push({
          type: 'pdf',
          title: content.title || content.name + ' - Document',
          data: content.attachments
        });
      }

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
          // Note: Activity blocks added in admin content page are intentionally separated
          // and displayed in the dedicated UserActivity component (/learn/activities)
        } else {
          steps.push({
            type: 'reading',
            title: content.title || content.name,
            data: { isJson: false, text: content.text_content }
          });
        }
      }
    });

    this.lessonSequence.set(steps);
    if (this.currentStepIndex() >= steps.length) {
      this.currentStepIndex.set(0);
    }
    this.evaluateStepCompletion();
    this.isLoadingLesson.set(false);
  }

  handleStepCompleted(isCompleted: boolean) {
    this.isStepCompleted.set(isCompleted);
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
        this.isStepCompleted.set(false); // KidsLessonPlayer emits stepCompleted
      } else {
        this.isStepCompleted.set(true);
      }
    } else if (step.type === 'video') {
      this.isStepCompleted.set(this.isVideoCompleted());
    } else {
      this.isStepCompleted.set(false);
    }
  }

  goToLevels() {
    this.cloudTransition.triggerTransition(() => {
      this.currentView.set('levels');
    });
  }

  selectTopic(id: number): void {
    this.activeContentId.set(id);
    this.fullContent.set(null); // Reset while loading

    const url = `${environment.apiUrl}/contents/${id}`;
    this.http.get<Content>(url).subscribe({
      next: (content) => {
        this.fullContent.set(content);
        this.cloudTransition.triggerTransition(() => {
          this.currentView.set('content'); // Switch to content overlay
        });
      },
      error: (err) => console.error('Failed to load topic content:', err)
    });
  }

  goToMap(): void {
    this.cloudTransition.triggerTransition(() => {
      this.currentView.set('map');
    });
  }

  goToActivity(): void {
    this.cloudTransition.triggerTransition(() => {
      this.hearts.set(5);
      this.showGameOver.set(false);
      this.currentActivityIndex.set(0);
      this.currentView.set('activity');
    });
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

        setTimeout(() => {
          gsap.fromTo('.stat-badge',
            { scale: 1.3, boxShadow: '0 0 20px #fcd34d' },
            { scale: 1, boxShadow: 'none', duration: 0.8, ease: 'elastic.out(1, 0.3)', stagger: 0.1 }
          );

          gsap.fromTo('.mascot-happy',
            { y: 50, scaleY: 0.7, rotation: -15 },
            { y: 0, scaleY: 1.1, rotation: 10, duration: 0.6, ease: 'back.out(1.7)' }
          );
          gsap.to('.mascot-happy', {
            y: -8, rotation: 0, scaleY: 1, duration: 1.5, repeat: -1, yoyo: true, ease: 'sine.inOut', delay: 0.6
          });
        }, 50);
      } else {
        this.audioService.playError();
        this.hearts.update(h => Math.max(0, h - 1));

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

    if (state === 'incorrect' && this.hearts() > 0) {
      const currentStep = this.currentStep();
      if (currentStep) {
        this.lessonSequence.update(seq => [...seq, currentStep]);
      }
    }

    if (this.hearts() > 0) {
      this.nextLessonStep();
    }
  }

  retryActivity() {
    this.hearts.set(5);
    this.showGameOver.set(false);
    this.activityFeedbackState.set(null);
    this.evaluateStepCompletion();

    // Reset the active activity content reference to trigger component reset via ngOnChanges
    const currentIdx = this.currentStepIndex();
    const seq = this.lessonSequence();
    if (seq.length > 0 && currentIdx >= 0 && currentIdx < seq.length) {
      const step = seq[currentIdx];
      if (step && step.type === 'activity' && step.data) {
        const clonedStep = {
          ...step,
          data: {
            ...step.data,
            data: step.data.data ? { ...step.data.data } : null
          }
        };
        const newSeq = [...seq];
        newSeq[currentIdx] = clonedStep;
        this.lessonSequence.set(newSeq);
      }
    }
  }



  nextLessonStep() {
    const currentIdx = this.currentStepIndex();
    const activeChapId = this.activeChapterId();
    const chapter = this.selectedChapter();

    if (activeChapId && chapter && chapter.contents && chapter.contents.length > 0) {
      const content = chapter.contents[Math.min(currentIdx, chapter.contents.length - 1)];
      if (content) {
        this.completeContent(activeChapId, content.id);
      }
    }

    if (currentIdx < this.lessonSequence().length - 1) {
      this.currentStepIndex.set(currentIdx + 1);
      this.isVideoCompleted.set(false);
      this.evaluateStepCompletion();
      this.activityFeedbackState.set(null);
    } else {
      // ✅ Auto-complete the chapter NOW — don't wait for FINISH button click
      if (activeChapId) {
        this.completeChapter(activeChapId);
      }
      this.lessonFinished.set(true);
    }
  }

  prevLessonStep() {
    const currentIdx = this.currentStepIndex();
    if (currentIdx > 0) {
      this.currentStepIndex.set(currentIdx - 1);
      this.evaluateStepCompletion();
      this.lessonFinished.set(false);
      this.activityFeedbackState.set(null);
    }
  }

  logout() {
    this.authService.logout().subscribe({
      complete: () => {
        window.location.href = '/login';
      },
      error: () => {
        this.authService.clearSession();
        window.location.href = '/login';
      }
    });
  }


  ngOnDestroy() { }

  finishLesson() {
    // Chapter is already completed in nextLessonStep() when all steps are done.
    // This method only handles celebration and navigation.
    this.audioService.playSuccess();

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