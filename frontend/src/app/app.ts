import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { LoaderService } from './services/loader.service';
import { NotificationService } from './services/notification.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive, TranslateModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  protected readonly title = signal('Language Management System');

  private translate = inject(TranslateService);
  private router = inject(Router);
  public loaderService = inject(LoaderService);
  public notificationService = inject(NotificationService);
  currentLang = signal('en');
  isSidebarOpen = signal(false);
  isAdventureView = signal(false);

  ngOnInit() {
    const savedLang = localStorage.getItem('userLang') || 'en';
    this.translate.setDefaultLang('en');
    this.translate.use(savedLang);
    this.currentLang.set(savedLang);

    // Initial check
    this.checkRoute(this.router.url);

    // Subscribe to future navigation events
    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        this.checkRoute(event.urlAfterRedirects || event.url);
      }
    });
  }

  private checkRoute(url: string) {
    const path = url.split('?')[0];
    const isAdv = (
      path === '/learn' || 
      path.startsWith('/learn/') || 
      path.startsWith('/assessments/play') ||
      path === '/dashboard' ||
      path.startsWith('/dashboard')
    );
    this.isAdventureView.set(isAdv);
    
    if (typeof document !== 'undefined') {
      if (isAdv) {
        document.body.classList.add('adventure-view');
      } else {
        document.body.classList.remove('adventure-view');
      }
    }
  }

  toggleSidebar() {
    this.isSidebarOpen.update(v => !v);
  }

  closeSidebar() {
    this.isSidebarOpen.set(false);
  }

  switchLanguage(event: Event) {
    const lang = (event.target as HTMLSelectElement).value;
    this.translate.use(lang);
    localStorage.setItem('userLang', lang);
    this.currentLang.set(lang);
  }
}