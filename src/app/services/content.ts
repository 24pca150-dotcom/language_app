import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ContentData {
  id?: number;
  name: string;
  chapters?: any[];
  sort_order?: number;
  is_active: boolean;
  text_content?: string;
  image_url?: string;
  video_url?: string;
  pdf_url?: string;
  doc_url?: string;
  xlsx_url?: string;
  ppt_url?: string;
  external_url?: string;
  created_at?: string;
  updated_at?: string;
}

@Injectable({
  providedIn: 'root',
})
export class ContentService {
  private http = inject(HttpClient);
  private apiUrl = 'http://127.0.0.1:8000/api/contents';

  getAll(chapterId?: number): Observable<ContentData[]> {
    let params = new HttpParams();
    if (chapterId) {
      params = params.set('chapter_id', chapterId.toString());
    }
    return this.http.get<ContentData[]>(this.apiUrl, { params });
  }

  getById(id: number): Observable<ContentData> {
    return this.http.get<ContentData>(`${this.apiUrl}/${id}`);
  }

  create(data: any): Observable<ContentData> {
    return this.http.post<ContentData>(this.apiUrl, data);
  }

  update(id: number, data: any): Observable<ContentData> {
    return this.http.put<ContentData>(`${this.apiUrl}/${id}`, data);
  }

  delete(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  uploadFile(file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<{ url: string }>(`${this.apiUrl}/upload`, formData);
  }
}
