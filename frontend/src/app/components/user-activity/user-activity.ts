import { Component, OnInit, OnDestroy, inject, signal, computed } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router, ActivatedRoute } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { forkJoin, of, Observable } from 'rxjs';
import { switchMap, map, catchError } from 'rxjs/operators';
import confetti from 'canvas-confetti';

import { environment } from '../../../environments/environment';
import { ActivityRenderer } from '../activity-engine/activity-renderer/activity-renderer';
import { AudioService } from '../../services/audio.service';
import { AuthService } from '../../services/auth';
import { CloudTransitionService } from '../../services/cloud-transition.service';

export interface ExtractedActivityItem {
  id: string | number;
  contentId: number;
  contentTitle: string;
  chapterId: number;
  chapterName: string;
  courseId: number;
  courseName: string;
  title: string;
  type: string;
  typeName: string;
  data: any;
  difficulty?: string;
}

@Component({
  selector: 'app-user-activity',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, ActivityRenderer],
  templateUrl: './user-activity.html',
  styleUrls: ['./user-activity.css']
})
export class UserActivity implements OnInit, OnDestroy {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private location = inject(Location);
  private audioService = inject(AudioService);
  private authService = inject(AuthService);
  private cloudTransition = inject(CloudTransitionService);

  // User state
  userId = signal<number>(1);
  userName = signal<string>('Learner');

  // 3-Stage Navigation State: courses -> chapters -> player (User Request: Like Practice)
  stage = signal<'courses' | 'chapters' | 'player'>('courses');
  isLoadingStructure = signal<boolean>(false);

  // Courses & Hierarchy state
  courses = signal<any[]>([]);
  selectedCourseId = signal<number | null>(null);
  courseStructure = signal<any | null>(null);
  selectedChapterId = signal<number | null>(null);

  selectedCourse = computed(() => {
    const cid = this.selectedCourseId();
    return this.courses().find(c => c.id === cid) || null;
  });

  selectedChapter = computed(() => {
    const chid = this.selectedChapterId();
    return this.availableChapters().find(ch => ch.id === chid) || null;
  });

  // Activities state
  allActivities = signal<ExtractedActivityItem[]>([]);
  isLoading = signal<boolean>(true);
  searchQuery = signal<string>('');
  selectedTypeFilter = signal<string>('all');
  viewMode = signal<'play' | 'catalog'>('play');

  // Play Mode State
  currentPlayIndex = signal<number>(0);
  hearts = signal<number>(5);
  xpEarned = signal<number>(0);
  isAnswered = signal<boolean>(false);
  feedbackState = signal<'correct' | 'incorrect' | null>(null);
  showSuccessSplash = signal<boolean>(false);
  showFailureSplash = signal<boolean>(false);
  isSessionFinished = signal<boolean>(false);
  mascotCheer = signal<string>('You can do this! Keep going!');
  activityRenderKey = signal<number>(1);

  // Navigation sidebar sliding state
  isNavSidebarOpen = signal<boolean>(false);

  // Available chapters in currently selected course
  availableChapters = computed(() => {
    const structure = this.courseStructure();
    if (!structure || !structure.levels) return [];
    const chaps: Array<{ id: number; name: string; levelName: string; count: number }> = [];
    structure.levels.forEach((lvl: any) => {
      (lvl.chapters || []).forEach((ch: any) => {
        chaps.push({
          id: ch.id,
          name: ch.name,
          levelName: lvl.name,
          count: (ch.contents || []).length
        });
      });
    });
    return chaps;
  });

  // Filtered activities based on search and type filter
  filteredActivities = computed(() => {
    let list = this.allActivities();
    const filter = this.selectedTypeFilter();
    const query = this.searchQuery().toLowerCase().trim();

    if (filter !== 'all') {
      list = list.filter(a => a.type === filter);
    }

    if (query) {
      list = list.filter(a =>
        a.title.toLowerCase().includes(query) ||
        a.chapterName.toLowerCase().includes(query) ||
        a.contentTitle.toLowerCase().includes(query) ||
        a.typeName.toLowerCase().includes(query)
      );
    }

    return list;
  });

  // Current active activity in Play mode
  currentActivity = computed<ExtractedActivityItem | null>(() => {
    const list = this.filteredActivities();
    const idx = this.currentPlayIndex();
    if (list.length > 0 && idx >= 0 && idx < list.length) {
      return list[idx];
    }
    return null;
  });

  // Distinct activity types present in current set
  availableActivityTypes = computed(() => {
    const types = new Set<string>();
    this.allActivities().forEach(a => types.add(a.type));
    return Array.from(types);
  });

  getChapterImage(name: string, idx: number): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('writing') || lower.includes('write') || lower.includes('noun')) return '/assets/images/level_writing.jpg';
    if (lower.includes('listening') || lower.includes('listen') || lower.includes('sound')) return '/assets/images/level_listening.jpg';
    if (lower.includes('reading') || lower.includes('read')) return '/assets/images/level_reading.jpg';
    if (lower.includes('speaking') || lower.includes('speak')) return '/assets/images/level_speaking.jpg';
    if (lower.includes('grammar') || lower.includes('vocab') || lower.includes('homophone')) return '/assets/images/level_grammar.jpg';
    if (lower.includes('interactive') || lower.includes('test') || lower.includes('demo') || lower.includes('game')) return '/assets/images/level_games.jpg';
    
    const fallbackBanners = [
      '/assets/images/level_writing.jpg',
      '/assets/images/level_listening.jpg',
      '/assets/images/level_reading.jpg',
      '/assets/images/level_speaking.jpg',
      '/assets/images/level_grammar.jpg',
      '/assets/images/level_games.jpg',
      '/assets/images/kid_adventure_banner.jpg',
      '/assets/images/kid_adventure_banner_2.jpg'
    ];
    return fallbackBanners[idx % fallbackBanners.length];
  }

  ngOnInit(): void {
    const user = this.authService.getUser();
    if (user) {
      this.userId.set(user.id);
      this.userName.set(user.name || user.username || 'Learner');
    }

    // Subscribe to route parameters
    this.route.params.subscribe(params => {
      const cid = params['courseId'] ? +params['courseId'] : null;
      const chid = params['chapterId'] ? +params['chapterId'] : null;

      this.loadCourses(cid, chid);
    });
  }

  ngOnDestroy(): void {
    this.audioService.stopAll();
  }

  toggleNavSidebar(): void {
    this.isNavSidebarOpen.update(v => !v);
  }

  closeNavSidebar(): void {
    this.isNavSidebarOpen.set(false);
  }

  goBack(): void {
    if (this.stage() === 'player') {
      this.cloudTransition.triggerTransition(() => {
        this.stage.set('chapters');
        if (this.selectedCourseId()) {
          this.location.replaceState(`/learn/games/${this.selectedCourseId()}`);
        }
      });
    } else if (this.stage() === 'chapters') {
      this.cloudTransition.triggerTransition(() => {
        this.stage.set('courses');
        this.location.replaceState('/learn/games');
      });
    } else {
      this.router.navigate(['/learn/dashboard']);
    }
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  loadCourses(targetCourseId: number | null, targetChapterId: number | null): void {
    this.isLoading.set(true);
    this.http.get<any[]>(`${environment.apiUrl}/courses`).subscribe({
      next: (courses) => {
        const activeCourses = (courses || []).filter(c => c.is_active !== false);
        this.courses.set(activeCourses);
        this.isLoading.set(false);

        if (targetCourseId && targetChapterId) {
          // Direct deep link: Stage 3 (Player)
          this.pickCourse(targetCourseId, false, targetChapterId);
        } else if (targetCourseId) {
          // Direct deep link: Stage 2 (Chapters)
          this.pickCourse(targetCourseId, false);
        } else {
          // Default: Stage 1 (Courses Grid)
          this.stage.set('courses');
        }
      },
      error: (err) => {
        console.error('Failed to load courses:', err);
        this.isLoading.set(false);
      }
    });
  }

  pickCourse(courseId: number, updateUrl: boolean = true, targetChapterId: number | null = null): void {
    const doPick = () => {
      this.selectedCourseId.set(courseId);
      this.isLoadingStructure.set(true);

      if (targetChapterId) {
        this.stage.set('player');
      } else {
        this.stage.set('chapters');
        if (updateUrl) {
          this.location.replaceState(`/learn/games/${courseId}`);
        }
      }

      this.http.get<any>(`${environment.apiUrl}/courses/${courseId}/player-structure`).subscribe({
        next: (structure) => {
          this.courseStructure.set(structure);
          this.isLoadingStructure.set(false);

          if (targetChapterId) {
            this.pickChapter(targetChapterId, false);
          }
        },
        error: (err) => {
          console.error('Failed to load course player structure:', err);
          this.isLoadingStructure.set(false);
        }
      });
    };

    if (updateUrl) {
      this.cloudTransition.triggerTransition(() => doPick());
    } else {
      doPick();
    }
  }

  pickChapter(chapterId: number, updateUrl: boolean = true): void {
    const doPick = () => {
      this.selectedChapterId.set(chapterId);
      this.stage.set('player');
      if (updateUrl && this.selectedCourseId()) {
        this.location.replaceState(`/learn/games/${this.selectedCourseId()}/${chapterId}`);
      }
      this.selectChapter(chapterId);
    };

    if (updateUrl) {
      this.cloudTransition.triggerTransition(() => doPick());
    } else {
      doPick();
    }
  }

  selectChapter(chapterId: number): void {
    this.selectedChapterId.set(chapterId);
    this.isLoading.set(true);
    this.currentPlayIndex.set(0);
    this.isAnswered.set(false);
    this.feedbackState.set(null);
    this.isSessionFinished.set(false);

    // Fetch full chapter details including contents and their text_content
    this.http.get<any>(`${environment.apiUrl}/chapters/${chapterId}`).pipe(
      switchMap(chapterData => {
        const contents = (chapterData.contents || [])
          .filter((c: any) => c.is_active !== false)
          .sort((a: any, b: any) => (a.sort_order || 0) - (b.sort_order || 0));

        return this.resolveActivityReferences(contents).pipe(
          map(resolvedContents => ({
            chapter: chapterData,
            contents: resolvedContents
          }))
        );
      })
    ).subscribe({
      next: (result) => {
        const course = this.courses().find(c => c.id === this.selectedCourseId());
        const extracted = this.extractActivitiesFromContents(
          result.contents,
          { id: result.chapter.id, name: result.chapter.name },
          { id: course?.id || 1, name: course?.name || 'Course' }
        );

        this.allActivities.set(extracted);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load chapter contents for activities:', err);
        this.isLoading.set(false);
      }
    });
  }

  resolveActivityReferences(contents: any[]): Observable<any[]> {
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

  extractActivitiesFromContents(
    contents: any[],
    chapterInfo: { id: number; name: string },
    courseInfo: { id: number; name: string }
  ): ExtractedActivityItem[] {
    const list: ExtractedActivityItem[] = [];

    contents.forEach(content => {
      if (!content.text_content) return;
      const trimmed = content.text_content.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return;

      try {
        const data = JSON.parse(trimmed);
        const blocks = data.blocks || [];

        blocks.forEach((block: any, idx: number) => {
          if (block.type === 'activity' && block.data) {
            let actType = block.data.type || 'mcq';
            if (actType === 'cloud_match') actType = 'match';

            let humanType = actType.split('-').map((w: string) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
            if (actType === 'mcq') humanType = 'Multiple Choice';
            if (actType === 'fill-blanks') humanType = 'Fill in the Blanks';

            const stepTitle = block.data.title || `${content.title || content.name} - ${humanType} ${idx + 1}`;
            const activityPayload = (block.data && typeof block.data === 'object')
              ? { ...block.data, type: block.data.type || actType, title: stepTitle }
              : block;

            list.push({
              id: `${content.id}_${idx}_${Date.now()}`,
              contentId: content.id,
              contentTitle: content.title || content.name,
              chapterId: chapterInfo.id,
              chapterName: chapterInfo.name,
              courseId: courseInfo.id,
              courseName: courseInfo.name,
              title: stepTitle,
              type: actType,
              typeName: humanType,
              data: activityPayload,
              difficulty: block.data.difficulty || 'Normal'
            });
          }
        });
      } catch (e) {
        console.error('Error parsing text_content blocks for activities:', e);
      }
    });

    return list;
  }

  setTypeFilter(type: string): void {
    this.selectedTypeFilter.set(type);
    this.currentPlayIndex.set(0);
    this.isAnswered.set(false);
    this.feedbackState.set(null);
    this.activityRenderKey.update(k => k + 1);
  }

  startActivityAt(index: number): void {
    this.currentPlayIndex.set(index);
    this.viewMode.set('play');
    this.isAnswered.set(false);
    this.feedbackState.set(null);
    this.activityRenderKey.update(k => k + 1);
  }

  onActivityAnswered(event: any): void {
    const isCorrect = event && (event.isCorrect || event.score > 0);
    this.isAnswered.set(true);

    if (isCorrect) {
      this.feedbackState.set('correct');
      this.xpEarned.update(x => x + 15);

      const isLastQuestion = (this.currentPlayIndex() + 1 >= this.filteredActivities().length);

      if (isLastQuestion) {
        // 🌟 Only at the very last when finished correctly: Cartoon says "Super!"
        this.showSuccessSplash.set(true);
        this.audioService.playSuccess("Super!");
        this.mascotCheer.set('Super! 🌟');
        confetti({
          particleCount: 60,
          spread: 70,
          origin: { y: 0.7 }
        });

        setTimeout(() => {
          this.showSuccessSplash.set(false);
        }, 1800);
      } else {
        // Intermediate question: cheerful success chime without interrupting popup speech
        this.audioService.playSuccessSoundOnly();
        this.mascotCheer.set('Good Job! 🌟');
      }

      // Record activity progress directly to backend
      const act = this.currentActivity();
      if (act) {
        this.http.post(`${environment.apiUrl}/dashboard/record-activity`, {
          activity_type: act.type === 'mcq' ? 'mcq' : (act.type === 'match' ? 'match' : (act.type === 'flashcard' ? 'flashcard' : 'mcq')),
          score: 100,
          total: 100
        }).subscribe({
          next: () => console.log('Activity progress recorded successfully'),
          error: (err) => console.warn('Could not record activity progress:', err)
        });
      }
    } else {
      this.feedbackState.set('incorrect');
      this.showFailureSplash.set(true);
      this.audioService.playError("Wrong!");
      this.mascotCheer.set("Wrong! Try again! 💡");
      this.hearts.update(h => Math.max(0, h - 1));

      setTimeout(() => {
        this.showFailureSplash.set(false);
      }, 1600);
    }
  }

  nextActivity(): void {
    const total = this.filteredActivities().length;
    if (this.currentPlayIndex() + 1 < total) {
      this.currentPlayIndex.update(i => i + 1);
      this.isAnswered.set(false);
      this.feedbackState.set(null);
      this.activityRenderKey.update(k => k + 1);
    } else {
      this.finishSession();
    }
  }

  prevActivity(): void {
    if (this.currentPlayIndex() > 0) {
      this.currentPlayIndex.update(i => i - 1);
      this.isAnswered.set(false);
      this.feedbackState.set(null);
      this.activityRenderKey.update(k => k + 1);
    }
  }

  retryCurrentActivity(): void {
    this.isAnswered.set(false);
    this.feedbackState.set(null);
    this.activityRenderKey.update(k => k + 1);
    if (this.hearts() === 0) {
      this.hearts.set(5);
    }
  }

  finishSession(): void {
    this.isSessionFinished.set(true);
    this.audioService.playSuccess();
    confetti({
      particleCount: 120,
      spread: 90,
      origin: { y: 0.5 }
    });
  }

  restartSession(): void {
    this.currentPlayIndex.set(0);
    this.isSessionFinished.set(false);
    this.isAnswered.set(false);
    this.feedbackState.set(null);
    this.hearts.set(5);
    this.activityRenderKey.update(k => k + 1);
  }

  goToReadingLesson(): void {
    const cid = this.selectedCourseId();
    if (cid) {
      this.router.navigate(['/learn', cid]);
    } else {
      this.router.navigate(['/learn/courses']);
    }
  }

  getTypeIcon(type: string): string {
    switch (type) {
      case 'mcq': return 'bi-check2-circle';
      case 'fill-blanks': return 'bi-pencil-square';
      case 'match': return 'bi-puzzle-fill';
      case 'flashcard': return 'bi-card-text';
      case 'speaking': return 'bi-mic-fill';
      case 'role-play': return 'bi-chat-dots-fill';
      case 'writing': return 'bi-pen-fill';
      case 'crossword': return 'bi-grid-3x3';
      case 'word-arrange': return 'bi-sort-alpha-down';
      default: return 'bi-lightning-charge-fill';
    }
  }

  getTypeBadgeClass(type: string): string {
    switch (type) {
      case 'mcq': return 'badge-type-mcq';
      case 'fill-blanks': return 'badge-type-blanks';
      case 'match': return 'badge-type-match';
      case 'flashcard': return 'badge-type-flashcard';
      case 'speaking': return 'badge-type-speaking';
      case 'writing': return 'badge-type-writing';
      default: return 'badge-type-default';
    }
  }
}
