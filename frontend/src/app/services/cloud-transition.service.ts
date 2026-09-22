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
   * Starts the enter animation (clouds swoop in to cover the screen)
   * Used by router guards and programmatic transitions
   */
  startEnterPhase(): Promise<void> {
    if (this.isInitialLoad) {
      return Promise.resolve();
    }

    if (this.isLocked) {
      return Promise.resolve();
    }

    this.isLocked = true;

    if (this.prefersReducedMotion) {
      this.phase.set('covered');
      return new Promise(resolve => setTimeout(resolve, 150));
    }

    this.phase.set('enter');

    return new Promise(resolve => {
      // 550ms allows clouds to swoop in from all 4 corners and firmly seal the viewport
      setTimeout(() => {
        this.phase.set('covered');
        resolve();
      }, 550);
    });
  }

  /**
   * Starts the reveal animation (clouds part smoothly to reveal new page)
   */
  startRevealPhase(): void {
    if (this.prefersReducedMotion) {
      setTimeout(() => {
        this.reset();
      }, 150);
      return;
    }

    // Brief 50ms pause to ensure Angular has attached the new view
    setTimeout(() => {
      this.phase.set('reveal');

      // 650ms for clouds to gracefully glide away offscreen
      setTimeout(() => {
        this.reset();
      }, 650);
    }, 60);
  }

  /**
   * Programmatic transition helper for internal view switches (Level -> Map, Chapter -> Lesson)
   */
  async triggerTransition(action?: () => void | Promise<any>): Promise<void> {
    if (this.isLocked) return;

    await this.startEnterPhase();

    if (action) {
      try {
        await action();
      } catch (err) {
        console.error('Error during transition action:', err);
      }
    }

    this.startRevealPhase();
  }

  /**
   * Programmatic navigation with cloud transition
   */
  async navigate(commands: any[], extras?: NavigationExtras): Promise<boolean> {
    if (this.isLocked) return false;

    await this.startEnterPhase();
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
