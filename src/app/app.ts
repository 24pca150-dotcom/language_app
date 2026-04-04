import { Component, signal } from '@angular/core';
import { Package } from './components/package/package';

@Component({
  selector: 'app-root',
  imports: [Package],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('language_app');
}
