import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth';

export const guestGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isLoggedIn()) {
    const role = authService.getUserRole();
    if (role === 'student') {
      return router.createUrlTree(['/learn']);
    } else if (role && ['super_admin', 'admin', 'staff'].includes(role)) {
      return router.createUrlTree(['/admin-dashboard']);
    } else {
      // Stale/corrupt session: clear and allow staying on login page
      authService.clearSession();
      return true;
    }
  }

  return true;
};
