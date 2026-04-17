import { Component, OnInit, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { AssessmentService, AssessmentData } from '../../services/assessment';
import { LevelService, LevelData } from '../../services/level';
import {
  McvInputField,
  McvTextArea,
  McvToggleField
} from 'mcv-ui-toolkit';

@Component({
  selector: 'app-assessment',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    McvInputField,
    McvTextArea,
    McvToggleField,
    TranslateModule
  ],
  templateUrl: './assessment.html',
  styleUrls: ['./assessment.css'],
})
export class Assessment implements OnInit {
  private fb = inject(FormBuilder);
  private assessmentService = inject(AssessmentService);
  private levelService = inject(LevelService);

  assessmentForm: FormGroup;
  assessments = signal<AssessmentData[]>([]);
  levels = signal<LevelData[]>([]);
  isEditMode = signal(false);
  isFormVisible = signal(false);
  currentAssessmentId = signal<number | null>(null);
  feedbackMessage = signal<{ type: 'success' | 'error', text: string } | null>(null);

  constructor() {
    this.assessmentForm = this.fb.group({
      level_id: ['', Validators.required],
      title: ['', Validators.required],
      description: [''],
      pass_percentage: [70, [Validators.required, Validators.min(0), Validators.max(100)]],
      is_active: [true],
      allow_restart: [false], // User can restart in-progress assessment
      duration_minutes: [null], // Optional fixed duration
      mode: ['instant', Validators.required], // Assessment Mode
      activity: ['plain', Validators.required], // Assessment Activity
      questions: this.fb.array([])
    });
  }

  get questions() {
    return this.assessmentForm.get('questions') as FormArray;
  }

  ngOnInit(): void {
    this.loadAssessments();
    this.loadLevels();
  }

  loadAssessments(): void {
    this.assessmentService.getAll().subscribe({
      next: (data) => this.assessments.set(data),
      error: () => this.showFeedback('error', 'Failed to load assessments'),
    });
  }

  loadLevels(): void {
    this.levelService.getAll().subscribe({
      next: (data) => this.levels.set(data),
      error: () => this.showFeedback('error', 'Failed to load levels for selection'),
    });
  }

  addQuestion() {
    const questionForm = this.fb.group({
      question_text: ['', Validators.required],
      sort_order: [this.questions.length],
      question_type: ['mcq', Validators.required], // Question Type
      options: this.fb.array([
        this.createOption(true),
        this.createOption(false)
      ])
    });
    this.questions.push(questionForm);
  }

  createOption(isCorrect: boolean = false) {
    return this.fb.group({
      option_text: ['', Validators.required],
      is_correct: [isCorrect],
      sort_order: [0]
    });
  }

  getOptions(questionIndex: number) {
    return this.questions.at(questionIndex).get('options') as FormArray;
  }

  addOption(questionIndex: number) {
    this.getOptions(questionIndex).push(this.createOption(false));
  }

  removeOption(questionIndex: number, optionIndex: number) {
    this.getOptions(questionIndex).removeAt(optionIndex);
  }

  removeQuestion(index: number) {
    this.questions.removeAt(index);
  }

  setCorrectOption(questionIndex: number, optionIndex: number) {
    const options = this.getOptions(questionIndex);
    options.controls.forEach((control, i) => {
      control.get('is_correct')?.setValue(i === optionIndex);
    });
  }

  showCreateForm(): void {
    this.resetForm();
    this.isFormVisible.set(true);
    this.addQuestion(); // Start with one question
  }

  onSubmit(): void {
    if (this.assessmentForm.invalid) {
      this.assessmentForm.markAllAsTouched();
      this.showFeedback('error', 'Please fill all required fields correctly.');
      return;
    }

    const assessmentData: AssessmentData = this.assessmentForm.value;

    if (this.isEditMode()) {
      const id = this.currentAssessmentId();
      if (id) {
        this.assessmentService.update(id, assessmentData).subscribe({
          next: () => {
            this.showFeedback('success', 'Assessment updated successfully');
            this.isFormVisible.set(false);
            this.loadAssessments();
          },
          error: (err) => this.showFeedback('error', err.error?.message || 'Failed to update assessment'),
        });
      }
    } else {
      this.assessmentService.create(assessmentData).subscribe({
        next: () => {
          this.showFeedback('success', 'Assessment created successfully');
          this.isFormVisible.set(false);
          this.loadAssessments();
        },
        error: (err) => this.showFeedback('error', err.error?.message || 'Failed to create assessment'),
      });
    }
  }

  editAssessment(assessment: AssessmentData): void {
    this.isEditMode.set(true);
    this.currentAssessmentId.set(assessment.id!);
    
    // Clear existing questions
    while (this.questions.length !== 0) {
      this.questions.removeAt(0);
    }

    this.assessmentForm.patchValue({
      level_id: assessment.level_id,
      title: assessment.title,
      description: assessment.description,
      pass_percentage: assessment.pass_percentage,
      is_active: assessment.is_active,
      allow_restart: assessment.allow_restart ?? false,
      duration_minutes: assessment.duration_minutes ?? null,
      mode: assessment.mode ?? 'instant',
      activity: assessment.activity ?? 'plain',
    });

    // Populate questions and options
    if (assessment.questions) {
      assessment.questions.forEach(q => {
        const qGroup = this.fb.group({
          id: [q.id],
          question_text: [q.question_text, Validators.required],
          sort_order: [q.sort_order],
          question_type: [q.question_type || 'mcq', Validators.required],
          options: this.fb.array([])
        });

        const oArray = qGroup.get('options') as FormArray;
        q.options.forEach(o => {
          oArray.push(this.fb.group({
            id: [o.id],
            option_text: [o.option_text, Validators.required],
            is_correct: [o.is_correct],
            sort_order: [o.sort_order]
          }));
        });

        this.questions.push(qGroup);
      });
    }

    this.isFormVisible.set(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteAssessment(id: number): void {
    if (confirm('Are you sure you want to delete this assessment?')) {
      this.assessmentService.delete(id).subscribe({
        next: () => {
          this.showFeedback('success', 'Assessment deleted successfully');
          this.loadAssessments();
        },
        error: () => this.showFeedback('error', 'Failed to delete assessment'),
      });
    }
  }

  resetForm(): void {
    this.assessmentForm.reset({ is_active: true, pass_percentage: 70 });
    while (this.questions.length !== 0) {
      this.questions.removeAt(0);
    }
    this.isEditMode.set(false);
    this.currentAssessmentId.set(null);
  }

  cancelForm(): void {
    this.resetForm();
    this.isFormVisible.set(false);
  }

  private showFeedback(type: 'success' | 'error', text: string): void {
    this.feedbackMessage.set({ type, text });
    setTimeout(() => this.feedbackMessage.set(null), 5000);
  }
}
