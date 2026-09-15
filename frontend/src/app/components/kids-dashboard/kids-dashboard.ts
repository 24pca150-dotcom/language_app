import { Component, Input, Output, EventEmitter, computed, HostListener, OnChanges, SimpleChanges, AfterViewInit, Inject, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { gsap } from 'gsap';

interface Level {
  id: number;
  name: string;
  chapters: any[];
}

interface CourseStructure {
  id: number;
  name: string;
  levels: Level[];
}

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

  isBrowser: boolean;

  constructor(@Inject(PLATFORM_ID) platformId: Object) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnChanges(changes: SimpleChanges) {
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
    const struct = this.structure;
    const levId = this.activeLevelId;
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

  // Mock function to generate 1-3 stars for completed chapters
  getChapterStars(chapterId: number): number {
    if (!this.isChapterCompleted(chapterId)) return 0;
    // Generate a pseudo-random 1-3 stars based on chapterId so it's consistent
    return (chapterId % 3) + 1; 
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
    return this.completedChapters.includes(chapterId);
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
}
