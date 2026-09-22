import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login';
import { Package } from './components/package/package';
import { Tenant } from './components/tenant/tenant';
import { Property } from './components/property/property';
import { Course } from './components/course/course';
import { Level } from './components/level/level';
import { CoursePackageLevel } from './components/course-package-level/course-package-level';
import { Chapter } from './components/chapter/chapter';
import { Content } from './components/content/content';
import { Assessment } from './components/assessment/assessment';
import { LearningMode } from './components/learning-mode/learning-mode';
import { CoursePlayer } from './components/course-player/course-player';
import { LearnerDashboard } from './components/learner-dashboard/learner-dashboard';
import { AssessmentPlayerComponent } from './components/activity-engine/assessment-player/assessment-player';
import { UserManagement } from './components/user-management/user-management';
import { StudentProgressComponent } from './components/student-progress/student-progress';
import { AdminDashboardComponent } from './components/admin-dashboard/admin-dashboard';
import { Announcements } from './components/announcements/announcements';
import { LiveClasses } from './components/live-classes/live-classes';
import { roleGuard } from './guards/role.guard';
import { guestGuard } from './guards/guest.guard';

import { ActivityBuilder } from './components/activity-builder/activity-builder';
import { UserActivity } from './components/user-activity/user-activity';
import { cloudTransitionGuard } from './guards/cloud-transition.guard';

export const routes: Routes = [
  // Public Login route
  { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
  
  // Safe Fallback redirect
  { path: '', redirectTo: 'login', pathMatch: 'full' },

  /*
   * 👑 Super Admin Only Pages
   */
  { 
    path: 'packages', 
    component: Package, 
    canActivate: [roleGuard(['super_admin']), cloudTransitionGuard] 
  },
  { 
    path: 'tenants', 
    component: Tenant, 
    canActivate: [roleGuard(['super_admin']), cloudTransitionGuard] 
  },


  /*
   * 🏢 Admins (Super Admin Only) Pages
   */
  { 
    path: 'properties', 
    component: Property, 
    canActivate: [roleGuard(['super_admin']), cloudTransitionGuard] 
  },

  /*
   * 🏫 Staff (Super Admin, Admin, Staff) Pages
   */
  { 
    path: 'admin-dashboard', 
    component: AdminDashboardComponent, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'live-classes', 
    component: LiveClasses, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff', 'student']), cloudTransitionGuard] 
  },
  { 
    path: 'announcements', 
    component: Announcements, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff', 'student']), cloudTransitionGuard] 
  },
  { 
    path: 'courses', 
    component: Course, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'users', 
    component: UserManagement, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'student-progress', 
    component: StudentProgressComponent, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'levels', 
    component: Level, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'course-package-levels', 
    component: CoursePackageLevel, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'chapters', 
    component: Chapter, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'contents', 
    component: Content, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'assessments', 
    component: Assessment, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learning-modes', 
    component: LearningMode, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'activity-builder', 
    component: ActivityBuilder, 
    canActivate: [roleGuard(['super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },

  /*
   * 🎓 Learning Workspace (Accessible by Students and Staff)
   */
  { 
    path: 'learn', 
    redirectTo: 'learn/dashboard', 
    pathMatch: 'full' 
  },
  { 
    path: 'learn/dashboard', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/courses', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/games', 
    component: UserActivity, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/games/:courseId', 
    component: UserActivity, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/games/:courseId/:chapterId', 
    component: UserActivity, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/game', 
    redirectTo: 'learn/games',
    pathMatch: 'full'
  },
  { 
    path: 'learn/activities', 
    redirectTo: 'learn/games',
    pathMatch: 'full'
  },
  { 
    path: 'learn/activities/:courseId', 
    redirectTo: 'learn/games/:courseId',
    pathMatch: 'full'
  },
  { 
    path: 'learn/activities/:courseId/:chapterId', 
    redirectTo: 'learn/games/:courseId/:chapterId',
    pathMatch: 'full'
  },
  { 
    path: 'learn/activity', 
    redirectTo: 'learn/games',
    pathMatch: 'full'
  },
  { 
    path: 'learn/practice', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/assessments', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/assessment', 
    redirectTo: 'learn/assessments',
    pathMatch: 'full'
  },
  { 
    path: 'learn/badges', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/achievements', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/progress', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/settings', 
    component: LearnerDashboard, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/play/:courseId', 
    component: CoursePlayer, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'learn/:courseId', 
    component: CoursePlayer, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },
  { 
    path: 'assessments/play/:assessmentId', 
    component: AssessmentPlayerComponent, 
    canActivate: [roleGuard(['student', 'super_admin', 'admin', 'staff']), cloudTransitionGuard] 
  },

  // Fallback for unauthorized pages
  { path: 'unauthorized', redirectTo: 'login' },
  { path: '**', redirectTo: 'login' }
];
