import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { RouterModule, Router } from '@angular/router';
import { CourseService } from '../../services/course';
import { LottieComponent, AnimationOptions } from 'ngx-lottie';
import { gsap } from 'gsap';
import confetti from 'canvas-confetti';

interface Course {
  id: number;
  name: string;
  description: string;
  is_active: boolean;
}

@Component({
  selector: 'app-learner-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, LottieComponent],
  templateUrl: './learner-dashboard.html',
  styleUrls: ['./learner-dashboard.css']
})
export class LearnerDashboard implements OnInit {
  private http = inject(HttpClient);
  private router = inject(Router);
  private courseService = inject(CourseService);
  courses = signal<Course[]>([]);
  isLoading = signal(true);
  isFullscreen = signal(false);

  // Search & Filtering Signals
  searchQuery = signal<string>('');
  selectedLanguage = signal<string>('All');

  groupedCourses = computed(() => {
    const query = this.searchQuery().toLowerCase().trim();
    const lang = this.selectedLanguage();
    const all = this.courses();

    const filtered = all.filter(c => {
      const matchesQuery = c.name.toLowerCase().includes(query) || (c.description && c.description.toLowerCase().includes(query));
      if (lang === 'All') return matchesQuery;
      return matchesQuery && c.name.toLowerCase().includes(lang.toLowerCase());
    });

    const categories: { title: string; courses: Course[] }[] = [];
    const french = filtered.filter(c => c.name.toLowerCase().includes('french'));
    const tamil = filtered.filter(c => c.name.toLowerCase().includes('tamil'));
    const english = filtered.filter(c => c.name.toLowerCase().includes('english'));
    const general = filtered.filter(c => !c.name.toLowerCase().includes('french') && !c.name.toLowerCase().includes('tamil') && !c.name.toLowerCase().includes('english'));

    if (french.length > 0) categories.push({ title: '🇫🇷 French Adventures', courses: french });
    if (tamil.length > 0) categories.push({ title: '🇮🇳 Tamil Adventures', courses: tamil });
    if (english.length > 0) categories.push({ title: '🇬🇧 English Adventures', courses: english });
    if (general.length > 0) categories.push({ title: '🌍 Global Quests', courses: general });

    return categories;
  });

  onSearchInput(event: Event) {
    const target = event.target as HTMLInputElement;
    this.searchQuery.set(target.value);
  }

  setLanguage(lang: string) {
    this.selectedLanguage.set(lang);
  }

  // Mascot Tip Messages
  mascotTip = signal<string>('Welcome back, adventurer! Click "Play" on a course to start your quest!');
  showMascotSpeech = signal(true);

  // Mascot Lottie Configuration (Selective Mascot)
  mascotLottieOptions: AnimationOptions = {
    path: '/assets/mascot.json', // Guiding mascot
    autoplay: true,
    loop: true
  };

  // Achievement Lottie Configuration (Selective Achievement Popup)
  achievementLottieOptions: AnimationOptions = {
    path: '/assets/trophy.json', // Golden winner trophy
    autoplay: false,
    loop: false
  };
  showAchievementModal = signal(false);

  ngOnInit() {
    this.fetchCourses();
  }

  fetchCourses() {
    this.http.get<Course[]>('http://localhost:8000/api/courses').subscribe({
      next: (data) => {
        this.courses.set(data.filter(c => c.is_active));
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load courses', err);
        this.isLoading.set(false);
      }
    });
  }

  playCourse(course: Course, event: MouseEvent) {
    event.preventDefault(); // Prevent immediate navigation

    // Pre-fetch the structure in the background
    const url = `http://localhost:8000/api/courses/${course.id}/player-structure`;
    this.http.get<any>(url).subscribe({
      next: (structure) => {
        // Cache the structure layout in the shared CourseService
        this.courseService.cachedStructure = structure;
        this.router.navigate(['/learn', course.id]);
      },
      error: (err) => {
        console.error('Failed to pre-fetch course structure:', err);
        // Fallback: navigate immediately
        this.router.navigate(['/learn', course.id]);
      }
    });
  }

  triggerAchievement() {
    this.showAchievementModal.set(true);
    confetti({
      particleCount: 150,
      spread: 90,
      origin: { y: 0.6 }
    });
  }

  toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => {
        this.isFullscreen.set(true);
      }).catch(err => {
        console.error(`Error attempting to enable fullscreen: ${err.message}`);
      });
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().then(() => {
          this.isFullscreen.set(false);
        });
      }
    }
  }
}
