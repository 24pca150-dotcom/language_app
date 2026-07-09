import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { environment } from '../../../environments/environment';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { RouterModule, Router } from '@angular/router';
import { CourseService } from '../../services/course';
import { AuthService } from '../../services/auth';
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
  private authService = inject(AuthService);
  courses = signal<Course[]>([]);
  isLoading = signal(true);
  isFullscreen = signal(false);
  uiTheme = signal<'adventure' | 'classic'>('adventure');

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
    // Determine theme based on user's age from DOB
    const user = this.authService.getUser();
    console.log('[DEBUG] learner-dashboard ngOnInit user:', user);
    if (user) {
      const age = this.getAgeFromDob(user.dob);
      console.log('[DEBUG] learner-dashboard calculated age:', age);
      if (age !== null) {
        this.uiTheme.set(age <= 15 ? 'adventure' : 'classic');
      } else {
        // No DOB set — default to classic for non-student roles, adventure for students
        const role = (user.role || '').toLowerCase();
        this.uiTheme.set(role === 'student' ? 'adventure' : 'classic');
      }
      console.log('[DEBUG] learner-dashboard uiTheme set to:', this.uiTheme());

      // Auto-sync any locally completed chapters to backend database
      if (user.role === 'student') {
        const uid = user.id;
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i);
          if (key && key.startsWith(`lang_app_completed_chapters_${uid}_`)) {
            try {
              const chapterIds = JSON.parse(localStorage.getItem(key) || '[]');
              if (Array.isArray(chapterIds)) {
                chapterIds.forEach(id => {
                  this.http.post(`${environment.apiUrl}/chapters/${id}/complete`, {}).subscribe({
                    next: () => console.log(`Auto-synced chapter ${id} from dashboard`),
                    error: (err) => console.error(`Failed to sync chapter ${id}`, err)
                  });
                });
              }
            } catch (e) {
              console.error('Failed to parse localStorage key:', key, e);
            }
          }
        }
      }
    }
    this.fetchCourses();
  }

  getAgeFromDob(dob: string | null | undefined): number | null {
    if (!dob) return null;
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  fetchCourses() {
    this.http.get<Course[]>(`${environment.apiUrl}/courses`).subscribe({
      next: (data) => {
        const activeCourses = data.filter(c => c.is_active);
        this.courses.set(activeCourses);
        this.isLoading.set(false);

        // For classic UI (age > 15), skip this page and go directly to the course player
        if (this.uiTheme() === 'classic' && activeCourses.length > 0) {
          this.router.navigate(['/learn', activeCourses[0].id]);
        }
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
    const url = `${environment.apiUrl}/courses/${course.id}/player-structure`;
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

  logout() {
    this.authService.logout().subscribe({
      complete: () => {
        window.location.href = '/login';
      },
      error: () => {
        this.authService.clearSession();
        window.location.href = '/login';
      }
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
