import { Component, Input, Output, EventEmitter, OnInit, OnChanges, SimpleChanges, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface WritingPair {
  leftImage?: string;
  leftAnswer?: string;
  rightImage?: string;
  rightAnswer?: string;
}

export interface WritingData {
  id?: number;
  question?: string;
  text?: string; // Optional prompt passage or hints list
  starterText?: string; // Optional opening sentence/phrase
  modelAnswer?: string; // Correct/model response preview for feedback
  minWords?: number;
  maxWords?: number;
  explanation?: string;
  mode?: 'essay' | 'image_fill';
  pairs?: WritingPair[];
}

export interface ImageFillItem {
  id: string;
  image: string;
  correctAnswer: string;
  userAnswer: string;
  isCorrect?: boolean;
}

@Component({
  selector: 'app-activity-writing',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './writing.html',
  styleUrls: ['./writing.css']
})
export class WritingComponent implements OnInit, OnChanges {
  @Input() activity: WritingData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{ isCorrect: boolean; text: string; wordCount: number }>();

  userText = signal<string>('');
  hasSubmitted = signal<boolean>(false);
  
  leftItems = signal<ImageFillItem[]>([]);
  rightItems = signal<ImageFillItem[]>([]);

  wordCount = computed(() => {
    const text = this.userText().trim();
    if (!text) return 0;
    return text.split(/\s+/).filter(Boolean).length;
  });

  charCount = computed(() => {
    return this.userText().length;
  });

  ngOnInit(): void {
    this.initWriting();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['activity']) {
      this.initWriting();
    }
  }

  initWriting(): void {
    this.userText.set(this.activity?.starterText || '');
    this.hasSubmitted.set(false);

    if (this.activity?.mode === 'image_fill' && this.activity.pairs) {
      const left: ImageFillItem[] = [];
      const right: ImageFillItem[] = [];

      this.activity.pairs.forEach((pair, idx) => {
        if (pair.leftImage && pair.leftAnswer) {
          left.push({
            id: `left-${idx}`,
            image: pair.leftImage,
            correctAnswer: pair.leftAnswer,
            userAnswer: ''
          });
        }
        if (pair.rightImage && pair.rightAnswer) {
          right.push({
            id: `right-${idx}`,
            image: pair.rightImage,
            correctAnswer: pair.rightAnswer,
            userAnswer: ''
          });
        }
      });

      this.leftItems.set(left);
      this.rightItems.set(right);
    }
  }

  isValidLength(): boolean {
    const count = this.wordCount();
    const min = this.activity?.minWords || 1;
    const max = this.activity?.maxWords || 1000;
    return count >= min && count <= max;
  }

  submitWriting(): void {
    if (this.hasSubmitted()) return;

    if (this.activity?.mode === 'image_fill') {
      let allCorrect = true;

      // Check left items
      this.leftItems.update(items => items.map(item => {
        const isCorrect = item.userAnswer.trim().toLowerCase() === item.correctAnswer.trim().toLowerCase();
        if (!isCorrect) allCorrect = false;
        return { ...item, isCorrect };
      }));

      // Check right items
      this.rightItems.update(items => items.map(item => {
        const isCorrect = item.userAnswer.trim().toLowerCase() === item.correctAnswer.trim().toLowerCase();
        if (!isCorrect) allCorrect = false;
        return { ...item, isCorrect };
      }));

      this.hasSubmitted.set(true);

      this.answered.emit({
        isCorrect: allCorrect,
        text: 'Image fill answers',
        wordCount: 0
      });
    } else {
      if (!this.isValidLength()) return;

      this.hasSubmitted.set(true);

      this.answered.emit({
        isCorrect: true, // Completion counts as passing
        text: this.userText(),
        wordCount: this.wordCount()
      });
    }
  }

  reset(): void {
    this.initWriting();
  }
}