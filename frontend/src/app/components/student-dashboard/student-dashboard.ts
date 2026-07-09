import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

interface Lesson {
  id: number;
  name: string;
}

interface Chapter {
  id: number;
  name: string;
  contents: Lesson[];
}

interface Level {
  id: number;
  name: string;
  chapters: Chapter[];
}

interface CourseStructure {
  id: number;
  name: string;
  description?: string;
  levels: Level[];
}

@Component({
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './student-dashboard.html',
  styleUrl: './student-dashboard.css'
})
export class StudentDashboard {
  @Input() structure: CourseStructure | null = null;
  @Input() completedChapters: number[] = [];
  @Output() selectChapter = new EventEmitter<number>();

  isChapterCompleted(chapterId: number): boolean {
    return this.completedChapters.includes(chapterId);
  }
}
