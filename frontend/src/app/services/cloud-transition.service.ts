import { Injectable, inject, signal, computed } from '@angular/core';
import { Router, NavigationEnd, NavigationCancel, NavigationError, NavigationExtras } from '@angular/router';

export type TransitionPhase = 'idle' | 'enter' | 'covered' | 'reveal';

@Injectable({
  providedIn: 'root'
})
export class CloudTransitionService {
  private router = inject(Router);

  // Reactive state for the cloud transition
  readonly phase = signal<TransitionPhase>('idle');
  readonly isCovered = computed(() => this.phase() === 'covered' || this.phase() === 'enter');
  readonly isVisible = computed(() => this.phase() !== 'idle');

  // Lock to prevent concurrent or duplicate navigation requests
  private isLocked = false;
  private isInitialLoad = true;

  constructor() {
    // Check initial navigation - don't show full cloud entry on cold reload
    setTimeout(() => {
      this.isInitialLoad = false;
    }, 1200);

    // Watch for route navigation ends to automatically reveal the target page
    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        if (this.phase() === 'covered' || this.phase() === 'enter') {
          this.startRevealPhase();
        }
      } else if (event instanceof NavigationCancel || event instanceof NavigationError) {
        // Recovery if navigation was cancelled or failed
        this.reset();
      }
    });
  }

  /**
   * Checks if user prefers reduced motion
   */
  get prefersReducedMotion(): boolean {
    if (typeof window !== 'undefined' && window.matchMedia) {
      return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    }
    return false;
  }

  /**
   * Starts the enter animation - resolves immediately for instant page navigation
   */
  startEnterPhase(): Promise<void> {
    return Promise.resolve();
  }

  /**
   * Starts the reveal animation - resets immediately
   */
  startRevealPhase(): void {
    this.reset();
  }

  /**
   * Programmatic transition helper for internal view switches (Level -> Map, Chapter -> Lesson)
   */
  async triggerTransition(action?: () => void | Promise<any>): Promise<void> {
    if (action) {
      try {
        await action();
      } catch (err) {
        console.error('Error during transition action:', err);
      }
    }
    this.reset();
  }

  /**
   * Programmatic navigation with instant transition
   */
  async navigate(commands: any[], extras?: NavigationExtras): Promise<boolean> {
    return this.router.navigate(commands, extras);
  }

  /**
   * Resets transition state and unlocks interactions
   */
  reset(): void {
    this.phase.set('idle');
    this.isLocked = false;
  }
}
