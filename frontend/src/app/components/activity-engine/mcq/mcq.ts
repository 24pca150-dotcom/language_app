import { Component, Input, Output, EventEmitter, signal, OnChanges, SimpleChanges, inject, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AudioService } from '../../../services/audio.service';

export interface MCQOption {
  id: number;
  text: string;
  isCorrect: boolean;
  imageUrl?: string;
  audioUrl?: string;
}

export interface MCQData {
  id?: number;
  question: string;
  options: MCQOption[];
  explanation?: string;
  audioUrl?: string;
  imageUrl?: string;
}

@Component({
  selector: 'app-activity-mcq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './mcq.html',
  styleUrls: ['./mcq.css']
})
export class MCQComponent implements OnChanges, OnDestroy {
  @Input() activity: MCQData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{ selectedOptionId: number; isCorrect: boolean }>();

  selectedOptionId = signal<number | null>(null);
  hasSubmitted = signal<boolean>(false);
  isPlaying = signal<boolean>(false);

  private audioService = inject(AudioService);

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.reset();
    }
  }

  selectOption(option: MCQOption): void {
    if (this.showFeedback && this.hasSubmitted()) return;

    this.selectedOptionId.set(option.id);

    if (this.showFeedback) {
      this.hasSubmitted.set(true);
    }

    this.answered.emit({
      selectedOptionId: option.id,
      isCorrect: option.isCorrect
    });
  }

  playAudio(): void {
    if (!this.activity || !this.activity.audioUrl) return;

    if (this.isPlaying()) {
      this.audioService.stopAll();
      this.isPlaying.set(false);
      return;
    }

    this.isPlaying.set(true);
    this.audioService.playAudioUrl(this.activity.audioUrl);
  }

  playOptionAudio(option: MCQOption, event?: Event): void {
    if (event) {
      event.stopPropagation(); // Prevent selecting the option if only the speaker is clicked
    }

    if (option.audioUrl) {
      this.audioService.playAudioUrl(option.audioUrl, option.text);
    } else {
      this.audioService.speak(option.text);
    }
  }

  getLetter(index: number): string {
    return String.fromCharCode(65 + index); // A, B, C, D...
  }

  reset(): void {
    this.selectedOptionId.set(null);
    this.hasSubmitted.set(false);
    this.audioService.stopAll();
    this.isPlaying.set(false);
  }

  ngOnDestroy(): void {
    this.audioService.stopAll();
  }
}
