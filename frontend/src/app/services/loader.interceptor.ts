import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { LoaderService } from './loader.service';
import { finalize } from 'rxjs/operators';

export const loaderInterceptor: HttpInterceptorFn = (req, next) => {
  const loaderService = inject(LoaderService);
  
  // Don't show loader for background requests like chat streams if they exist
  loaderService.show();
  
  return next(req).pipe(
    finalize(() => {
      loaderService.hide();
    })
  );
};
