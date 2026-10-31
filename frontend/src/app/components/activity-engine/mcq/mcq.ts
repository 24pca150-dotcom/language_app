import { Component, Input, Output, EventEmitter, OnInit, OnChanges, SimpleChanges, OnDestroy, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AudioService } from '../../../services/audio.service';

export interface MCQOption {
  id: number;
  text: string;
  isCorrect?: boolean;
  audioUrl?: string;
  imageUrl?: string;
}

export interface MCQActivity {
  id: number;
  type: 'mcq';
  question: string;
  audioUrl?: string;
  imageUrl?: string;
  options: MCQOption[];
  explanation?: string;
}

export type MCQData = MCQActivity;

@Component({
  selector: 'app-activity-mcq, app-mcq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './mcq.html',
  styleUrls: ['./mcq.css']
})
export class MCQComponent implements OnInit, OnChanges, OnDestroy {
  @Input() activity: MCQActivity | null = null;
  @Input() showFeedback: boolean = true;
  @Input() disabled: boolean = false;

  @Output() answered = new EventEmitter<{
    selectedOptionId: number;
    isCorrect?: boolean;
  }>();

  selectedOptionId = signal<number | null>(null);
  hasSubmitted = signal<boolean>(false);
  isPlaying = signal<boolean>(false);
  playingOptionId = signal<number | null>(null);
  isQuestionSpeaking = signal<boolean>(false);

  private audioService = inject(AudioService);

  ngOnInit(): void {
    this.reset();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.reset();
    }
  }

  getLetter(index: number): string {
    return String.fromCharCode(65 + (index % 26));
  }

  selectOption(option: MCQOption): void {
    if (this.showFeedback && this.hasSubmitted()) return;

    this.selectedOptionId.set(option.id);

    if (this.showFeedback) {
      this.hasSubmitted.set(true);
      if (option.isCorrect) {
        this.audioService.playMcqCorrectSound();
      } else {
        this.audioService.playWrongAnswerSound();
      }
    } else {
      if (option.isCorrect) {
        this.audioService.playMcqCorrectSound();
      }
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

    this.audioService.stopAll();
    this.isPlaying.set(true);

    this.audioService.playAudioUrl(this.activity.audioUrl, this.activity.question, () => {
      this.isPlaying.set(false);
    });
  }

  speakQuestion(): void {
    if (this.isQuestionSpeaking()) {
      this.audioService.stopAll();
      this.isQuestionSpeaking.set(false);
      return;
    }

    this.audioService.stopAll();
    this.isQuestionSpeaking.set(true);

    const raw = this.activity?.question || '';
    const readable = raw
      .replace(/_{2,}/g, ' blank ')
      .replace(/[^\w\s.,?!'-]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    this.audioService.speak(readable, {
      rate: 0.88,
      pitch: 1.0,
      onEnd: () => this.isQuestionSpeaking.set(false),
      onError: () => this.isQuestionSpeaking.set(false)
    });
  }

  playOptionAudio(option: MCQOption, event?: Event): void {
    if (event) {
      event.stopPropagation();
    }

    if (this.playingOptionId() === option.id) {
      this.audioService.stopAll();
      this.playingOptionId.set(null);
      return;
    }

    this.audioService.stopAll();
    this.playingOptionId.set(option.id);

    const onDone = () => {
      if (this.playingOptionId() === option.id) {
        this.playingOptionId.set(null);
      }
    };

    if (option.audioUrl) {
      this.audioService.playAudioUrl(option.audioUrl, option.text, onDone);
    } else {
      this.audioService.speakWordWithSpelling(option.text, onDone, onDone);
    }
  }

  getOptionClass(option: MCQOption): string {
    if (!this.showFeedback || !this.hasSubmitted()) {
      return this.selectedOptionId() === option.id ? 'selected' : '';
    }

    if (option.isCorrect) {
      return 'correct';
    }

    if (this.selectedOptionId() === option.id && !option.isCorrect) {
      return 'incorrect';
    }

    return '';
  }

  reset(): void {
    this.selectedOptionId.set(null);
    this.hasSubmitted.set(false);
    this.audioService.stopAll();
    this.isPlaying.set(false);
    this.playingOptionId.set(null);
    this.isQuestionSpeaking.set(false);
  }

  ngOnDestroy(): void {
    this.audioService.stopAll();
  }
}
