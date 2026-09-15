import { Component, Input, Output, EventEmitter, OnChanges, SimpleChanges, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface CanvasBlock {
  id: string;
  type: 'text' | 'audio' | 'image' | 'video' | 'link' | 'button' | 'input';
  content?: string;
  url?: string;
  imageUrl?: string;
  audioUrl?: string;
  isCorrect?: boolean;
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
  imports: [CommonModule, FormsModule],
  templateUrl: './custom-canvas.html',
  styleUrls: ['./custom-canvas.css']
})
export class CustomCanvasComponent implements OnChanges, OnDestroy {
  @Input() activity: CustomCanvasData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{ isCorrect: boolean; viewed: boolean }>();

  isViewed = signal<boolean>(false);
  playingAudioId = signal<string | null>(null);
  private audioRefs: { [id: string]: HTMLAudioElement } = {};

  // Q&A Block States
  answeredBlocksState = signal<{ [blockId: string]: 'correct' | 'incorrect' }>({});
  inputTextValues = signal<{ [blockId: string]: string }>({});

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.reset();
    }
  }

  get containers(): CanvasContainer[] {
    return this.activity?.nodes || [];
  }

  hasQuestions(): boolean {
    const allBlocks: CanvasBlock[] = [];
    this.containers.forEach(c => allBlocks.push(...c.contents));
    const hasInputs = allBlocks.some(b => b.type === 'input');
    const hasCorrectButtons = allBlocks.some(b => b.type === 'button' && (b.isCorrect === true || (b.isCorrect as any) === 'true'));
    return hasInputs || hasCorrectButtons;
  }

  hasAnswerBlocks(container: CanvasContainer): boolean {
    return container.contents.some(b => b.type === 'button' || b.type === 'input');
  }

  clickAnswerButton(block: CanvasBlock): void {
    const isCorrect = block.isCorrect === true || (block.isCorrect as any) === 'true';
    
    this.answeredBlocksState.update(state => ({
      ...state,
      [block.id]: isCorrect ? 'correct' : 'incorrect'
    }));

    if (isCorrect) {
      this.checkOverallCompletion();
    } else {
      this.answered.emit({ isCorrect: false, viewed: false });
    }
  }

  onTextInput(blockId: string, event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.inputTextValues.update(values => ({
      ...values,
      [blockId]: val
    }));
  }

  checkTextInput(block: CanvasBlock): void {
    const typed = (this.inputTextValues()[block.id] || '').trim().toLowerCase();
    const expected = (block.url || '').trim().toLowerCase();
    const isCorrect = typed === expected && expected !== '';

    this.answeredBlocksState.update(state => ({
      ...state,
      [block.id]: isCorrect ? 'correct' : 'incorrect'
    }));

    if (isCorrect) {
      this.checkOverallCompletion();
    } else {
      this.answered.emit({ isCorrect: false, viewed: false });
    }
  }

  checkOverallCompletion(): void {
    const allBlocks: CanvasBlock[] = [];
    this.containers.forEach(c => allBlocks.push(...c.contents));

    const inputBlocks = allBlocks.filter(b => b.type === 'input');
    const correctButtons = allBlocks.filter(b => b.type === 'button' && (b.isCorrect === true || (b.isCorrect as any) === 'true'));

    const inputsSolved = inputBlocks.every(b => this.answeredBlocksState()[b.id] === 'correct');
    const buttonsSolved = correctButtons.length === 0 || correctButtons.some(b => this.answeredBlocksState()[b.id] === 'correct');

    if (inputsSolved && buttonsSolved) {
      this.isViewed.set(true);
      this.answered.emit({ isCorrect: true, viewed: true });
    }
  }

  hasAnsweredBlock(blockId: string): 'correct' | 'incorrect' | null {
    return this.answeredBlocksState()[blockId] || null;
  }

  isInputBlockCorrect(blockId: string): boolean {
    return this.answeredBlocksState()[blockId] === 'correct';
  }

  markAsViewed(): void {
    this.isViewed.set(true);
    this.answered.emit({ isCorrect: true, viewed: true });
  }

  toggleAudio(block: CanvasBlock): void {
    const audioSrc = block.audioUrl || block.url;
    if (!audioSrc) return;

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
      const audio = new Audio(audioSrc);
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
    this.answeredBlocksState.set({});
    this.inputTextValues.set({});
  }

  ngOnDestroy(): void {
    this.reset();
  }
}
