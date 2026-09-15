import { Component, Input, Output, EventEmitter, OnInit, OnChanges, SimpleChanges, signal, inject, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AudioService } from '../../../services/audio.service';
import { MatchCloudComponent } from './match-cloud/match-cloud';
import { MatchStandardComponent } from './match-standard/match-standard';

export interface MatchPair {
  left: string;
  leftImage?: string;
  leftAudio?: string;
  right?: string;
  rightImage?: string;
  rightAudio?: string;
  result?: string;
}

export interface MatchData {
  id?: number;
  pairs: MatchPair[];
  theme?: 'cloud' | 'standard';
  allowDragDrop?: boolean;
  allowClickMatch?: boolean;
  enableAudio?: boolean;
  explanation?: string;
}

export interface ShuffledItem {
  id: string; // "left-0", "right-2", etc.
  text: string;
  originalIndex: number;
  image?: string;
  audio?: string;
}

interface MatchedPair {
  leftId: string;
  rightId: string;
  colorIndex: number;
}

@Component({
  selector: 'app-activity-match',
  standalone: true,
  imports: [CommonModule, MatchCloudComponent, MatchStandardComponent],
  templateUrl: './match.html',
  styleUrls: ['./match.css']
})
export class MatchComponent implements OnInit, OnChanges, OnDestroy {
  @Input() activity: MatchData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{ isCorrect: boolean }>();

  private audioService = inject(AudioService);

  leftItems = signal<ShuffledItem[]>([]);
  rightItems = signal<ShuffledItem[]>([]);

  selectedLeftId = signal<string | null>(null);
  selectedRightId = signal<string | null>(null);

  matchedPairs = signal<MatchedPair[]>([]);
  
  shakeLeftId = signal<string | null>(null);
  shakeRightId = signal<string | null>(null);

  isComplete = signal<boolean>(false);
  
  theme = signal<'cloud' | 'standard'>('standard');
  allowDragDrop = signal<boolean>(true);
  allowClickMatch = signal<boolean>(true);
  enableAudio = signal<boolean>(false);

  // Multi-color palette for matched pairs (CSS classes color-pair-0 to color-pair-5)
  private colorPairsCount = 6;

  ngOnInit(): void {
    this.initializeMatchGame();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.initializeMatchGame();
    }
  }

  initializeMatchGame(): void {
    if (!this.activity || !this.activity.pairs) return;

    // Apply configuration inputs or defaults
    this.theme.set(this.activity.theme || 'standard');
    this.allowDragDrop.set(this.activity.allowDragDrop !== false);
    this.allowClickMatch.set(this.activity.allowClickMatch !== false);
    this.enableAudio.set(!!this.activity.enableAudio);

    const left: ShuffledItem[] = [];
    const right: ShuffledItem[] = [];

    this.activity.pairs.forEach((pair, idx) => {
      left.push({
        id: `left-${idx}`,
        text: pair.left,
        originalIndex: idx,
        image: pair.leftImage,
        audio: pair.leftAudio
      });
      right.push({
        id: `right-${idx}`,
        text: pair.right || '',
        originalIndex: idx,
        image: pair.rightImage,
        audio: pair.rightAudio
      });
    });

    // Scramble right column until no item aligns directly with its left pair (if pairs.length > 1)
    let shuffledRight = this.shuffleArray(right);
    if (right.length > 1) {
      let attempts = 0;
      while (attempts < 100 && shuffledRight.some((item, idx) => item.originalIndex === idx)) {
        shuffledRight = this.shuffleArray(right);
        attempts++;
      }
    }

    this.leftItems.set(left); // Keep left column in original order
    this.rightItems.set(shuffledRight); // Scramble right column to prevent straight matches
    
    this.matchedPairs.set([]);
    this.selectedLeftId.set(null);
    this.selectedRightId.set(null);
    this.isComplete.set(false);
  }

  private shuffleArray<T>(array: T[]): T[] {
    const copy = [...array];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  }

  // Speak left word using browser TTS API
  speak(text: string): void {
    this.audioService.speak(text);
  }

  // --- Click to Match Logic ---
  selectLeft(item: ShuffledItem): void {
    if (this.isItemMatched(item.id) || this.isComplete()) return;
    
    // Play speech/audio if enabled
    if (this.enableAudio()) {
      this.playItemAudio(item);
    }

    if (this.allowClickMatch()) {
      this.selectedLeftId.set(item.id);
      this.checkMatch();
    }
  }

  selectRight(item: ShuffledItem): void {
    if (this.isItemMatched(item.id) || this.isComplete()) return;

    // Play speech/audio if enabled
    if (this.enableAudio()) {
      this.playItemAudio(item);
    }

    if (this.allowClickMatch()) {
      this.selectedRightId.set(item.id);
      this.checkMatch();
    }
  }

  checkMatch(): void {
    const leftId = this.selectedLeftId();
    const rightId = this.selectedRightId();

    if (!leftId || !rightId) return;

    const leftItem = this.leftItems().find(i => i.id === leftId);
    const rightItem = this.rightItems().find(i => i.id === rightId);

    if (leftItem && rightItem) {
      if (leftItem.originalIndex === rightItem.originalIndex) {
        // MATCH DETECTED!
        const nextColorIdx = this.matchedPairs().length % this.colorPairsCount;
        
        this.matchedPairs.update(pairs => [
          ...pairs,
          { leftId, rightId, colorIndex: nextColorIdx }
        ]);

        this.selectedLeftId.set(null);
        this.selectedRightId.set(null);

        // Speak the match explanation with a small delay to let the selection sound finish
        setTimeout(() => {
          if (this.matchedPairs().some(p => p.leftId === leftId && p.rightId === rightId)) {
            const pair = this.activity?.pairs[leftItem.originalIndex];
            const leftText = leftItem.text || '';
            const rightText = rightItem.text || '';
            const resultText = pair?.result || '';
            if (resultText) {
              this.speak(`${leftText} and ${rightText} match to ${resultText}`);
            } else {
              this.speak(`${leftText} and ${rightText} match`);
            }
          }
        }, 800);

        // Check completion
        if (this.matchedPairs().length === this.activity?.pairs.length) {
          this.isComplete.set(true);
          this.answered.emit({ isCorrect: true });
        }
      } else {
        // MISMATCH!
        this.shakeLeftId.set(leftId);
        this.shakeRightId.set(rightId);

        const currentLeft = leftId;
        const currentRight = rightId;
        
        setTimeout(() => {
          if (this.shakeLeftId() === currentLeft) this.shakeLeftId.set(null);
          if (this.shakeRightId() === currentRight) this.shakeRightId.set(null);
          
          this.selectedLeftId.set(null);
          this.selectedRightId.set(null);
        }, 1200);
      }
    }
  }

  // --- Drag and Drop Logic ---
  onDragStart(event: DragEvent, item: ShuffledItem): void {
    if (this.isItemMatched(item.id) || !this.allowDragDrop() || this.isComplete()) {
      event.preventDefault();
      return;
    }
    
    // Play speech if enabled
    if (this.enableAudio()) {
      this.speak(item.text);
    }

    event.dataTransfer?.setData('text/plain', item.id);
    this.selectedLeftId.set(item.id);
  }

  onDragOver(event: DragEvent): void {
    if (!this.allowDragDrop() || this.isComplete()) return;
    event.preventDefault(); // Required to allow drop
  }

  onDrop(event: DragEvent, targetItem: ShuffledItem): void {
    if (!this.allowDragDrop() || this.isComplete()) return;
    event.preventDefault();

    const draggedId = event.dataTransfer?.getData('text/plain');
    if (!draggedId) return;

    if (draggedId.startsWith('left-') && targetItem.id.startsWith('right-')) {
      if (this.isItemMatched(targetItem.id)) return;
      this.selectedLeftId.set(draggedId);
      this.selectedRightId.set(targetItem.id);
      this.checkMatch();
    } else {
      this.selectedLeftId.set(null);
      this.selectedRightId.set(null);
    }
  }

  // Helper status checkers
  isItemMatched(itemId: string): boolean {
    return this.matchedPairs().some(p => p.leftId === itemId || p.rightId === itemId);
  }

  getLeftItemText(id: string): string {
    return this.leftItems().find(i => i.id === id)?.text || '';
  }

  getRightItemText(id: string): string {
    return this.rightItems().find(i => i.id === id)?.text || '';
  }

  getRightItemImage(id: string): string {
    return this.rightItems().find(i => i.id === id)?.image || '';
  }

  getItemImage(id: string): string {
    if (id.startsWith('left-')) {
      return this.leftItems().find(i => i.id === id)?.image || '';
    } else {
      return this.rightItems().find(i => i.id === id)?.image || '';
    }
  }

  getItemAudio(id: string): string {
    if (id.startsWith('left-')) {
      return this.leftItems().find(i => i.id === id)?.audio || '';
    } else {
      return this.rightItems().find(i => i.id === id)?.audio || '';
    }
  }

  getMatchedPairResult(pair: MatchedPair): string {
    const leftItem = this.leftItems().find(i => i.id === pair.leftId);
    if (leftItem && this.activity?.pairs[leftItem.originalIndex]) {
      return this.activity.pairs[leftItem.originalIndex].result || '';
    }
    return '';
  }

  playItemAudio(item: ShuffledItem, event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    if (item.audio) {
      this.audioService.playAudioUrl(item.audio, item.text);
    } else {
      this.audioService.speak(item.text);
    }
  }

  reset(): void {
    this.selectedLeftId.set(null);
    this.selectedRightId.set(null);
    this.audioService.stopAll();
    this.initializeMatchGame();
  }

  ngOnDestroy(): void {
    this.audioService.stopAll();
  }
}
