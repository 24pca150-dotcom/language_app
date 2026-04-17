import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface SubChapterData {
  id?: number;
  chapter_id: number;
  name: string;
  content_type: 'text' | 'video' | 'file' | 'image' | 'slide_view';
  content?: string;
  content_meta?: any;
  sort_order?: number;
  is_active: boolean;
  chapter?: any;
  assessments?: any[];
  created_at?: string;
  updated_at?: string;
}

@Injectable({
  providedIn: 'root',
})
export class SubChapterService {
  private http = inject(HttpClient);
  private apiUrl = 'http://127.0.0.1:8000/api/sub-chapters';

  getAll(chapterId?: number): Observable<SubChapterData[]> {
    let params = new HttpParams();
    if (chapterId) {
      params = params.set('chapter_id', chapterId.toString());
    }
    return this.http.get<SubChapterData[]>(this.apiUrl, { params });
  }

  getById(id: number): Observable<SubChapterData> {
    return this.http.get<SubChapterData>(`${this.apiUrl}/${id}`);
  }

  create(data: SubChapterData): Observable<SubChapterData> {
    return this.http.post<SubChapterData>(this.apiUrl, data);
  }

  update(id: number, data: SubChapterData): Observable<SubChapterData> {
    return this.http.put<SubChapterData>(`${this.apiUrl}/${id}`, data);
  }

  delete(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
