import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CloudTransitionService } from '../../services/cloud-transition.service';

@Component({
  selector: 'app-cloud-transition',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './cloud-transition.html',
  styleUrls: ['./cloud-transition.css']
})
export class CloudTransitionComponent {
  protected transitionService = inject(CloudTransitionService);
}
