import { Component, Input, Output, EventEmitter, signal, computed, HostListener, OnChanges, SimpleChanges, AfterViewInit, Inject, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { gsap } from 'gsap';

import { CourseStructure, Level } from '../../models/course-structure.model';

@Component({
  selector: 'app-kids-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './kids-dashboard.html',
  styleUrls: ['./kids-dashboard.css']
})
export class KidsDashboard implements OnChanges, AfterViewInit {
  @Input() structure: CourseStructure | null = null;
  @Input() currentView: string = 'levels';
  @Input() activeLevelId: number | null = null;
  @Input() activeChapterId: number | null = null;
  @Input() completedLevels: number[] = [];
  @Input() completedChapters: number[] = [];

  @Output() selectLevel = new EventEmitter<number>();
  @Output() selectChapterNode = new EventEmitter<number>();
  @Output() backToLevels = new EventEmitter<void>();
  @Output() backToCourses = new EventEmitter<void>();

  isBrowser: boolean;

  structureSignal = signal<CourseStructure | null>(null);
  activeLevelIdSignal = signal<number | null>(null);
  completedChaptersSignal = signal<number[]>([]);

  constructor(@Inject(PLATFORM_ID) platformId: Object) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['structure']) {
      this.structureSignal.set(this.structure);
    }
    if (changes['activeLevelId']) {
      this.activeLevelIdSignal.set(this.activeLevelId);
      if (this.currentView === 'map') {
        this.scrollToActiveNode();
      }
    }
    if (changes['completedChapters']) {
      this.completedChaptersSignal.set(this.completedChapters || []);
    }
    if (changes['currentView'] && changes['currentView'].currentValue === 'map') {
      this.scrollToActiveNode();
    }
  }

  ngAfterViewInit() {
    if (this.currentView === 'map') {
      this.scrollToActiveNode();
    }
  }

  scrollToActiveNode() {
    if (!this.isBrowser) return;
    setTimeout(() => {
      const mapContainer = document.querySelector('.map-container') as HTMLElement;
      const activeNode = document.querySelector('.active-btn, .angry-mascot-anchor, .active-node') as HTMLElement;

      if (mapContainer && activeNode) {
        const containerRect = mapContainer.getBoundingClientRect();
        const nodeRect = activeNode.getBoundingClientRect();
        const scrollTarget = mapContainer.scrollLeft + (nodeRect.left - containerRect.left) - (containerRect.width / 2) + (nodeRect.width / 2);

        mapContainer.scrollTo({ left: Math.max(0, scrollTarget), behavior: 'smooth' });
      }
    }, 150);
  }

  @HostListener('document:mousemove', ['$event'])
  onMouseMove(e: MouseEvent) {
    if (this.currentView !== 'map') return; // Only animate heavily if they are on the map

    const x = (e.clientX / window.innerWidth - 0.5) * 2; // Range -1 to 1
    const y = (e.clientY / window.innerHeight - 0.5) * 2; // Range -1 to 1

    gsap.to('.hill-bg-1', { x: x * -10, y: y * -5, duration: 1, ease: 'power2.out' });
    gsap.to('.hill-bg-2', { x: x * -20, y: y * -10, duration: 1, ease: 'power2.out' });
    gsap.to('.hill-bg-3', { x: x * -35, y: y * -15, duration: 1, ease: 'power2.out' });
    gsap.to('.cloud-1, .cloud-2, .cloud-3', { x: x * 40, y: y * 20, duration: 2, ease: 'power1.out' });
    gsap.to('.sparkles-container', { x: x * -30, y: y * -30, duration: 1.5, ease: 'power1.out' });
  }

  selectedLevel = computed(() => {
    const struct = this.structureSignal();
    const levId = this.activeLevelIdSignal();
    if (!struct || !levId) return null;
    return struct.levels.find((l: any) => l.id === levId) || null;
  });

  completedChaptersCount = computed(() => {
    const level = this.selectedLevel();
    if (!level) return 0;
    return level.chapters.filter((c: any) => this.isChapterCompleted(c.id)).length;
  });

  totalTrackWidth = computed(() => {
    const level = this.selectedLevel();
    const count = level ? level.chapters.length : 6;
    return Math.max(1400, 160 + (count - 1) * 240 + 200);
  });

  levelChaptersMap = computed(() => {
    const level = this.selectedLevel();
    const map = new Map<number, { globalNumber: number; globalIndex: number; x: number; y: number; yOffset: number }>();
    if (!level) return map;

    // Gentle natural hills undulating pattern for yOffset (like Angry Birds level terrain)
    const yPattern = [0, -42, 28, -36, 32, -22, 25, -30];
    const stepWidth = 240;
    const startX = 160;
    const baselineY = 190;

    level.chapters.forEach((chapter: any, idx: number) => {
      const x = startX + idx * stepWidth;
      const yOffset = yPattern[idx % yPattern.length];
      const y = baselineY + yOffset;

      map.set(chapter.id, {
        globalNumber: idx + 1,
        globalIndex: idx,
        x,
        y,
        yOffset
      });
    });

    return map;
  });

  // Dynamically generate horizontal SVG path string connecting the nodes like Angry Birds
  svgPathData = computed(() => {
    const level = this.selectedLevel();
    if (!level || level.chapters.length === 0) return '';

    const map = this.levelChaptersMap();
    let d = '';

    level.chapters.forEach((chapter: any, idx: number) => {
      const info = map.get(chapter.id);
      if (!info) return;

      if (idx === 0) {
        d += `M ${info.x} ${info.y} `;
      } else {
        const prevInfo = map.get(level.chapters[idx - 1].id);
        if (!prevInfo) return;

        const cp1x = prevInfo.x + 120;
        const cp1y = prevInfo.y;
        const cp2x = info.x - 120;
        const cp2y = info.y;

        d += `C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${info.x} ${info.y} `;
      }
    });

    return d;
  });

  // Always give 3 stars for a fully completed chapter
  getChapterStars(chapterId: number): number {
    if (!this.isChapterCompleted(chapterId)) return 0;
    return 3; // Full completion = full 3 stars
  }

  isLevelUnlocked(levelId: number): boolean {
    return true;
  }

  // Calculate which chapter should be the glowing "active" one (the next to play)
  currentPlayableChapterId = computed(() => {
    const level = this.selectedLevel();
    if (!level) return null;

    // Find first uncompleted chapter
    const uncompleted = level.chapters.find((c: any) => !this.isChapterCompleted(c.id));
    if (uncompleted) return uncompleted.id;

    // If all completed, return the last chapter
    return level.chapters.length > 0 ? level.chapters[level.chapters.length - 1].id : null;
  });

  isChapterUnlocked(chapterId: number): boolean {
    return true;
  }

  isChapterCompleted(chapterId: number): boolean {
    return this.completedChaptersSignal().includes(chapterId);
  }

  onLevelClick(id: number) {
    if (this.isLevelUnlocked(id)) {
      this.selectLevel.emit(id);
    }
  }

  onChapterClick(id: number) {
    if (this.isChapterUnlocked(id)) {
      this.selectChapterNode.emit(id);
    }
  }

  onBackToLevels() {
    this.backToLevels.emit();
  }

  onBackToCourses() {
    this.backToCourses.emit();
  }

  getLevelIcon(name: string): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('writing') || lower.includes('write')) return 'bi-pencil-fill';
    if (lower.includes('listening') || lower.includes('listen')) return 'bi-headphones';
    if (lower.includes('reading') || lower.includes('read')) return 'bi-book-half';
    if (lower.includes('speaking') || lower.includes('speak')) return 'bi-mic-fill';
    if (lower.includes('grammar') || lower.includes('vocab')) return 'bi-spellcheck';
    if (lower.includes('interactive') || lower.includes('test') || lower.includes('demo')) return 'bi-controller';
    return 'bi-journal-richtext';
  }

  getLevelGradient(name: string): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('writing') || lower.includes('write')) return 'linear-gradient(to bottom, #f59e0b, #d97706) !important';
    if (lower.includes('listening') || lower.includes('listen')) return 'linear-gradient(to bottom, #06b6d4, #0891b2) !important';
    if (lower.includes('reading') || lower.includes('read')) return 'linear-gradient(to bottom, #3b82f6, #1d4ed8) !important';
    if (lower.includes('speaking') || lower.includes('speak')) return 'linear-gradient(to bottom, #8b5cf6, #6d28d9) !important';
    if (lower.includes('grammar') || lower.includes('vocab')) return 'linear-gradient(to bottom, #10b981, #059669) !important';
    if (lower.includes('interactive') || lower.includes('test') || lower.includes('demo')) return 'linear-gradient(to bottom, #ec4899, #be185d) !important';
    return 'linear-gradient(to bottom, #4caf50, #2e7d32) !important';
  }

  getLevelBorder(name: string): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('writing') || lower.includes('write')) return '#b45309 !important';
    if (lower.includes('listening') || lower.includes('listen')) return '#0e7490 !important';
    if (lower.includes('reading') || lower.includes('read')) return '#1e40af !important';
    if (lower.includes('speaking') || lower.includes('speak')) return '#5b21b6 !important';
    if (lower.includes('grammar') || lower.includes('vocab')) return '#047857 !important';
    if (lower.includes('interactive') || lower.includes('test') || lower.includes('demo')) return '#9d174d !important';
    return '#1b5e20 !important';
  }

  getLevelImage(name: string, index: number = 0): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('writing') || lower.includes('write')) return '/assets/images/level_writing.jpg';
    if (lower.includes('listening') || lower.includes('listen')) return '/assets/images/level_listening.jpg';
    if (lower.includes('reading') || lower.includes('read')) return '/assets/images/level_reading.jpg';
    if (lower.includes('speaking') || lower.includes('speak')) return '/assets/images/level_speaking.jpg';
    if (lower.includes('grammar') || lower.includes('vocab')) return '/assets/images/level_grammar.jpg';
    if (lower.includes('interactive') || lower.includes('test') || lower.includes('demo') || lower.includes('game')) return '/assets/images/level_games.jpg';

    const fallbackList = [
      '/assets/images/level_writing.jpg',
      '/assets/images/level_listening.jpg',
      '/assets/images/level_reading.jpg',
      '/assets/images/level_speaking.jpg',
      '/assets/images/level_grammar.jpg',
      '/assets/images/level_games.jpg'
    ];
    return fallbackList[index % fallbackList.length];
  }

  scrollLevels(track: HTMLElement, delta: number) {
    if (track) {
      track.scrollBy({ left: delta, behavior: 'smooth' });
    }
  }
}
