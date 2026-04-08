import { Routes } from '@angular/router';
import { Package } from './components/package/package';
import { Tenant } from './components/tenant/tenant';
import { Property } from './components/property/property';

export const routes: Routes = [
  { path: '', redirectTo: 'tenants', pathMatch: 'full' },
  { path: 'packages', component: Package },
  { path: 'tenants', component: Tenant },
  { path: 'properties', component: Property },
];
