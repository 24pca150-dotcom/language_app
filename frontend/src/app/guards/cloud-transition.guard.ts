import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { CloudTransitionService } from '../services/cloud-transition.service';

/**
 * Functional Route Guard that seamlessly swoops cartoon clouds in
 * before any route activation, ensuring the target page is fully mounted
 * while the screen is completely covered by clouds.
 */
export const cloudTransitionGuard: CanActivateFn = async (route, state) => {
  const transitionService = inject(CloudTransitionService);
  await transitionService.startEnterPhase();
  return true;
};
