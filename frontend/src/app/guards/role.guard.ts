import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth';

export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    if (!authService.isLoggedIn()) {
      return router.createUrlTree(['/login']);
    }

    if (authService.hasRole(allowedRoles)) {
      return true;
    }

    // Role is not allowed. Send student to /learn, or back to login
    const userRole = authService.getUserRole();
    if (userRole === 'student') {
      return router.createUrlTree(['/learn']);
    }

    return router.createUrlTree(['/login']);
  };
};
