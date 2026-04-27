import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

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
  currentLang = signal('en');
  isSidebarOpen = signal(false);

  ngOnInit() {
    const savedLang = localStorage.getItem('userLang') || 'en';
    this.translate.setDefaultLang('en');
    this.translate.use(savedLang);
    this.currentLang.set(savedLang);
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