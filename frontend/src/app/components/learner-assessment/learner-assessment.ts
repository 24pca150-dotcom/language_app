import { Component, OnInit, inject, signal, computed, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Router, RouterModule } from '@angular/router';
import { environment } from '../../../environments/environment';

export interface AssessmentItem {
  id: number;
  title: string;
  description?: string;
  level_id?: number;
  chapter_id?: number;
  pass_percentage: number;
  is_mandatory?: boolean;
  duration_minutes?: number;
  allow_restart?: boolean;
  review_mode?: string;
  activity_type?: string;
  is_active: boolean;
  level?: {
    id: number;
    name: string;
    course?: {
      id: number;
      name: string;
      code?: string;
    };
  };
  chapter?: {
    id: number;
    name?: string;
    title?: string;
  };
  questions?: any[];
  latest_attempt?: {
    id: number;
    score: number;
    passed: boolean;
    attempted_at: string;
  };
  best_score?: number;
  is_passed?: boolean;
  total_attempts_count?: number;
}

@Component({
  selector: 'app-learner-assessment',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './learner-assessment.html',
  styleUrls: ['./learner-assessment.css']
})
export class LearnerAssessmentComponent implements OnInit {
  private http = inject(HttpClient);
  private router = inject(Router);

  @Input() set initialAssessments(data: AssessmentItem[]) {
    if (data) {
      this.assessments.set(data);
      this.isLoading.set(false);
    }
  }

  assessments = signal<AssessmentItem[]>([]);
  isLoading = signal<boolean>(true);
  errorMessage = signal<string | null>(null);

  // Search & Filter signals
  searchQuery = signal<string>('');
  selectedCourseFilter = signal<string>('all');
  selectedStatusFilter = signal<'all' | 'passed' | 'pending'>('all');

  // Stats
  totalCount = computed(() => this.assessments().length);
  passedCount = computed(() => this.assessments().filter(a => a.is_passed).length);
  pendingCount = computed(() => this.assessments().filter(a => !a.is_passed).length);

  // Available courses for filter dropdown
  availableCourses = computed(() => {
    const list = this.assessments();
    const courseNames = new Set<string>();
    list.forEach(a => {
      if (a.level?.course?.name) {
        courseNames.add(a.level.course.name);
      }
    });
    return Array.from(courseNames);
  });

  // Filtered assessments computed
  filteredAssessments = computed(() => {
    let list = this.assessments();
    const q = this.searchQuery().trim().toLowerCase();
    const course = this.selectedCourseFilter();
    const status = this.selectedStatusFilter();

    if (q) {
      list = list.filter(a =>
        (a.title && a.title.toLowerCase().includes(q)) ||
        (a.description && a.description.toLowerCase().includes(q)) ||
        (a.level?.course?.name && a.level.course.name.toLowerCase().includes(q)) ||
        (a.chapter?.name && a.chapter.name.toLowerCase().includes(q)) ||
        (a.chapter?.title && a.chapter.title.toLowerCase().includes(q))
      );
    }

    if (course !== 'all') {
      list = list.filter(a => a.level?.course?.name === course);
    }

    if (status === 'passed') {
      list = list.filter(a => a.is_passed);
    } else if (status === 'pending') {
      list = list.filter(a => !a.is_passed);
    }

    return list;
  });

  ngOnInit(): void {
    this.fetchAssessments();
  }

  fetchAssessments(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.http.get<AssessmentItem[]>(`${environment.apiUrl}/assessments`).subscribe({
      next: (data) => {
        this.assessments.set(data || []);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load assessments:', err);
        this.errorMessage.set('Failed to load assessments. Please try again.');
        this.isLoading.set(false);
      }
    });
  }

  startAssessment(assessment: AssessmentItem): void {
    // Clear previous return course, assessment player defaults to returning to assessments tab
    localStorage.removeItem('lang_app_assessment_return_course');
    if (assessment.level?.course?.id) {
      localStorage.setItem('lang_app_assessment_return_course', assessment.level.course.id.toString());
    }
    this.router.navigate(['/assessments/play', assessment.id]);
  }

  getCourseBadge(item: AssessmentItem): string {
    if (item.level?.course?.name) {
      return item.level.course.name;
    }
    if (item.chapter?.name || item.chapter?.title) {
      return item.chapter.name || item.chapter.title || 'General';
    }
    return 'General Assessment';
  }
}
