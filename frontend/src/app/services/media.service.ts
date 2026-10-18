import { Injectable, inject } from '@angular/core';
import { environment } from '../../environments/environment';
import { AuthService } from './auth';

@Injectable({
  providedIn: 'root',
})
export class MediaService {
  private authService = inject(AuthService);

  /**
   * Get a secure stream URL for any Cloudinary or remote media URL.
   * Cloudinary IP/domain will never be exposed to the user.
   */
  getSecureStreamUrl(rawUrl: string, fileName?: string, download = false): string {
    if (!rawUrl) return '';

    const token = this.authService.getToken();
    const params = new URLSearchParams();
    params.set('url', rawUrl);
    if (fileName) params.set('name', fileName);
    if (token) params.set('token', token);
    if (download) params.set('download', '1');

    return `${environment.apiUrl}/media/stream?${params.toString()}`;
  }

  /**
   * Get secure stream URL for a Content Attachment by ID.
   */
  getAttachmentStreamUrl(attachmentId: number, download = false): string {
    const token = this.authService.getToken();
    const downloadParam = download ? '&download=1' : '';
    const tokenParam = token ? `?token=${encodeURIComponent(token)}` : '';
    return `${environment.apiUrl}/media/attachment/${attachmentId}${tokenParam}${downloadParam}`;
  }

  /**
   * Get secure stream URL for a Live Class Attachment by ID.
   */
  getLiveClassAttachmentStreamUrl(attachmentId: number, download = false): string {
    const token = this.authService.getToken();
    const downloadParam = download ? '&download=1' : '';
    const tokenParam = token ? `?token=${encodeURIComponent(token)}` : '';
    return `${environment.apiUrl}/media/live-class-attachment/${attachmentId}${tokenParam}${downloadParam}`;
  }

  /**
   * Open the secure file directly in a new browser tab for inline viewing.
   */
  openInNewTab(rawUrl: string, fileName?: string): void {
    const streamUrl = this.getSecureStreamUrl(rawUrl, fileName, false);
    if (streamUrl) {
      window.open(streamUrl, '_blank', 'noopener,noreferrer');
    }
  }

  /**
   * Download the file securely through the proxy.
   */
  downloadFile(rawUrl: string, fileName?: string): void {
    const streamUrl = this.getSecureStreamUrl(rawUrl, fileName, true);
    if (streamUrl) {
      const a = document.createElement('a');
      a.href = streamUrl;
      a.download = fileName || 'download';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    }
  }
}
