import { CanActivateFn } from '@angular/router';

/**
 * Route Guard - returns true immediately for instant, zero-latency navigation.
 */
export const cloudTransitionGuard: CanActivateFn = () => true;

