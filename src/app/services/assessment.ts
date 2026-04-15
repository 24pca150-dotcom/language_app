import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface QuestionOptionData {
  id?: number;
  question_id?: number;
  option_text: string;
  is_correct: boolean;
  sort_order?: number;
}

export interface AssessmentQuestionData {
  id?: number;
  assessment_id?: number;
  question_text: string;
  sort_order?: number;
  options: QuestionOptionData[];
}

export interface AssessmentData {
  id?: number;
  level_id: number;
  title: string;
  description?: string;
  pass_percentage: number;
  is_active: boolean;
  level?: any;
  questions?: AssessmentQuestionData[];
  created_at?: string;
  updated_at?: string;
}

export interface AttemptAnswer {
  question_id: number;
  selected_option_id: number;
}

export interface AttemptResult {
  attempt_id: number;
  score: number;
  passed: boolean;
  total_questions: number;
  correct_answers: number;
  pass_percentage: number;
}

@Injectable({
  providedIn: 'root',
})
export class AssessmentService {
  private http = inject(HttpClient);
  private apiUrl = 'http://127.0.0.1:8000/api/assessments';

  getAll(levelId?: number): Observable<AssessmentData[]> {
    let params = new HttpParams();
    if (levelId) {
      params = params.set('level_id', levelId.toString());
    }
    return this.http.get<AssessmentData[]>(this.apiUrl, { params });
  }

  getById(id: number): Observable<AssessmentData> {
    return this.http.get<AssessmentData>(`${this.apiUrl}/${id}`);
  }

  create(data: AssessmentData): Observable<AssessmentData> {
    return this.http.post<AssessmentData>(this.apiUrl, data);
  }

  update(id: number, data: AssessmentData): Observable<AssessmentData> {
    return this.http.put<AssessmentData>(`${this.apiUrl}/${id}`, data);
  }

  delete(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  submitAttempt(assessmentId: number, userId: number, answers: AttemptAnswer[]): Observable<AttemptResult> {
    return this.http.post<AttemptResult>(`${this.apiUrl}/${assessmentId}/submit`, {
      user_id: userId,
      answers,
    });
  }
}
