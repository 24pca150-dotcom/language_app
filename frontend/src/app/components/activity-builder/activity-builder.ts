import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

interface BlockContent {
  id: string;
  type: 'text' | 'audio' | 'image' | 'video' | 'link';
  content?: string;
  url?: string;
}

interface ContainerNode {
  id: string;
  type: 'container';
  display: string;
  contents: BlockContent[];
}

@Component({
  selector: 'app-activity-builder',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './activity-builder.html',
  styleUrls: ['./activity-builder.css']
})
export class ActivityBuilder {
  // Main data structure
  nodes = signal<ContainerNode[]>([]);
  
  // Track which container is currently selected to add items into
  selectedContainerId = signal<string | null>(null);

  // Toggle for User Preview mode
  isPreviewMode = signal(false);

  // Generate a random ID
  private generateId(): string {
    return Math.random().toString(36).substring(2, 9);
  }

  // --- Actions ---

  addContainer() {
    const newContainer: ContainerNode = {
      id: 'container_' + this.generateId(),
      type: 'container',
      display: 'block',
      contents: []
    };
    
    this.nodes.update(current => [...current, newContainer]);
    
    // Automatically select the newly created container
    this.selectedContainerId.set(newContainer.id);
  }

  addBlock(type: 'text' | 'audio' | 'image' | 'video' | 'link') {
    const activeId = this.selectedContainerId();
    
    if (!activeId) {
      alert('Please select or create a container first!');
      return;
    }

    const newBlock: BlockContent = {
      id: 'block_' + this.generateId(),
      type: type,
      content: type === 'text' ? 'Enter text here...' : undefined,
      url: type !== 'text' ? 'assets/placeholder' : undefined
    };

    this.nodes.update(current => {
      return current.map(container => {
        if (container.id === activeId) {
          return {
            ...container,
            contents: [...container.contents, newBlock]
          };
        }
        return container;
      });
    });
  }

  selectContainer(id: string) {
    this.selectedContainerId.set(id);
  }

  removeContainer(id: string, event: Event) {
    event.stopPropagation();
    this.nodes.update(current => current.filter(c => c.id !== id));
    if (this.selectedContainerId() === id) {
      this.selectedContainerId.set(null);
    }
  }

  removeBlock(containerId: string, blockId: string, event: Event) {
    event.stopPropagation();
    this.nodes.update(current => {
      return current.map(container => {
        if (container.id === containerId) {
          return {
            ...container,
            contents: container.contents.filter(b => b.id !== blockId)
          };
        }
        return container;
      });
    });
  }

  togglePreview() {
    this.isPreviewMode.set(!this.isPreviewMode());
    if (this.isPreviewMode()) {
      this.selectedContainerId.set(null); // Clear selection in preview
    }
  }
}
