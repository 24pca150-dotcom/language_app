import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

import { CourseStructure } from '../../models/course-structure.model';

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
