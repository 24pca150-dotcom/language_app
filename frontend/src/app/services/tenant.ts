import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface TenantData {
  id?: number;
  tenant_code: string;
  tenant_name: string;
  contact_person?: string;
  email?: string;
  phone?: string;
  address?: string;
  is_active: boolean;
  logo_path?: string | null;
  primary_color?: string | null;
  secondary_color?: string | null;
  created_at?: string;
  updated_at?: string;
}

@Injectable({
  providedIn: 'root',
})
export class TenantService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/tenants`;

  getAll(): Observable<TenantData[]> {
    return this.http.get<TenantData[]>(this.apiUrl);
  }

  getById(id: number): Observable<TenantData> {
    return this.http.get<TenantData>(`${this.apiUrl}/${id}`);
  }

  create(data: TenantData): Observable<TenantData> {
    return this.http.post<TenantData>(this.apiUrl, data);
  }

  update(id: number, data: TenantData): Observable<TenantData> {
    return this.http.put<TenantData>(`${this.apiUrl}/${id}`, data);
  }

  uploadLogo(id: number, file: File): Observable<any> {
    const formData = new FormData();
    formData.append('logo', file);
    return this.http.post<any>(`${this.apiUrl}/${id}/upload-logo`, formData);
  }

  delete(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
