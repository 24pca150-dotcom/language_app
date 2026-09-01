import { Component, Input, Output, EventEmitter, OnChanges, SimpleChanges, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface CanvasBlock {
  id: string;
  type: 'text' | 'audio' | 'image' | 'video' | 'link';
  content?: string;
  url?: string;
}

export interface CanvasContainer {
  id: string;
  type: 'container';
  display: string; // 'block' | 'flex' | 'grid'
  contents: CanvasBlock[];
}

export interface CustomCanvasData {
  nodes: CanvasContainer[];
  question?: string;
}

@Component({
  selector: 'app-activity-custom-canvas',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './custom-canvas.html',
  styleUrls: ['./custom-canvas.css']
})
export class CustomCanvasComponent implements OnChanges, OnDestroy {
  @Input() activity: CustomCanvasData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{ correct: boolean; viewed: boolean }>();

  isViewed = signal<boolean>(false);
  playingAudioId = signal<string | null>(null);
  private audioRefs: { [id: string]: HTMLAudioElement } = {};

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.reset();
    }
  }

  get containers(): CanvasContainer[] {
    return this.activity?.nodes || [];
  }

  markAsViewed(): void {
    this.isViewed.set(true);
    this.answered.emit({ correct: true, viewed: true });
  }

  toggleAudio(block: CanvasBlock): void {
    if (!block.url) return;

    const currentId = this.playingAudioId();

    // Stop any currently playing audio
    if (currentId && this.audioRefs[currentId]) {
      this.audioRefs[currentId].pause();
      this.audioRefs[currentId].currentTime = 0;
      if (currentId === block.id) {
        this.playingAudioId.set(null);
        return;
      }
    }

    // Play new audio
    if (!this.audioRefs[block.id]) {
      const audio = new Audio(block.url);
      audio.onended = () => this.playingAudioId.set(null);
      this.audioRefs[block.id] = audio;
    }

    this.audioRefs[block.id].play().catch(() => {});
    this.playingAudioId.set(block.id);
  }

  isAudioPlaying(blockId: string): boolean {
    return this.playingAudioId() === blockId;
  }

  reset(): void {
    // Stop all audio
    Object.values(this.audioRefs).forEach(a => { a.pause(); a.currentTime = 0; });
    this.audioRefs = {};
    this.playingAudioId.set(null);
    this.isViewed.set(false);
  }

  ngOnDestroy(): void {
    this.reset();
  }
}
