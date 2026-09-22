import { Component, signal, computed, inject, ViewChild, ElementRef, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { DragDropModule, CdkDragDrop, moveItemInArray, transferArrayItem } from '@angular/cdk/drag-drop';
import { environment } from '../../../environments/environment';
import { ActivityService, Activity } from '../../services/activity.service';
import { NotificationService } from '../../services/notification.service';
import { CourseService, CourseData } from '../../services/course';
import { ContentService, ContentData } from '../../services/content';
import { ActivityBlock } from '../../editor-plugins/activity-block';
import { ActivityRenderer } from '../activity-engine/activity-renderer/activity-renderer';

interface BlockContent {
  id: string;
  type: 'text' | 'audio' | 'image' | 'video' | 'link' | 'button' | 'input';
  content?: string;
  url?: string;
  imageUrl?: string;
  audioUrl?: string;
  isCorrect?: boolean;
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
  imports: [CommonModule, FormsModule, ActivityRenderer, DragDropModule],
  templateUrl: './activity-builder.html',
  styleUrls: ['./activity-builder.css']
})
export class ActivityBuilder {
  private activityService = inject(ActivityService);
  private notificationService = inject(NotificationService);
  private courseService = inject(CourseService);
  private contentService = inject(ContentService);
  private http = inject(HttpClient);

  // Mapping State
  linkingActivity = signal<Activity | null>(null);
  mappingContents = signal<any[]>([]);
  selectedLinkContentId = signal<number | null>(null);
  
  selectedContentDetail = signal<any | null>(null);
  isLoadingContentDetails = signal(false);
  isLinkingInProgress = signal(false);
  mappedLessonActivities = signal<any[]>([]);

  @ViewChild('standardFormContainer', { static: false }) standardFormContainer!: ElementRef;

  // View State
  isFormVisible = signal(false);
  isSaving = signal(false);
  isPreviewMode = signal(false);
  isTitleManuallyEdited = signal(false);
  viewMode = signal<'grid' | 'list'>('grid');
  isTemplatePickerVisible = signal(false);
  testingActivity = signal<Activity | null>(null);

  // Search & Filter State
  searchQuery = signal('');
  filterType = signal('all');
  selectedSkillTab = signal<'all' | 'listening' | 'speaking' | 'reading' | 'writing' | 'games'>('all');
  selectedCourseFilter = signal<number | 'all'>('all');
  selectedStatusFilter = signal<'all' | 'linked' | 'unassigned'>('all');

  // Pagination State
  currentPage = signal<number>(1);
  pageSize = signal<number>(12);

  // Data State
  savedActivities = signal<Activity[]>([]);

  // Skill categorization helper
  getActivitySkill(type: string): 'listening' | 'speaking' | 'reading' | 'writing' | 'games' {
    switch (type) {
      case 'mcq':
      case 'match':
        return 'listening';
      case 'speaking':
      case 'role_play':
        return 'speaking';
      case 'flashcard':
      case 'sequencing':
      case 'mind_map':
        return 'reading';
      case 'writing':
      case 'parts_of_speech':
      case 'word_arrange':
      case 'fill_blanks':
        return 'writing';
      case 'crossword':
      case 'custom':
        return 'games';
      default:
        return 'listening';
    }
  }

  // Dynamic Skill Counts
  skillCounts = computed(() => {
    const all = this.savedActivities();
    const counts = {
      all: all.length,
      listening: 0,
      speaking: 0,
      reading: 0,
      writing: 0,
      games: 0
    };
    for (const act of all) {
      const skill = this.getActivitySkill(act.type);
      if (counts[skill] !== undefined) {
        counts[skill]++;
      }
    }
    return counts;
  });

  // Filtered Activities
  filteredActivities = computed(() => {
    const query = this.searchQuery().toLowerCase().trim();
    const skill = this.selectedSkillTab();
    const type = this.filterType();
    const courseId = this.selectedCourseFilter();
    
    let list = this.savedActivities();
    
    // 1. Skill Tab Filter
    if (skill !== 'all') {
      list = list.filter(act => this.getActivitySkill(act.type) === skill);
    }

    // 2. Type Dropdown Filter
    if (type !== 'all') {
      list = list.filter(act => act.type === type);
    }
    
    // 3. Course Filter
    if (courseId !== 'all') {
      if (courseId === null) {
        list = list.filter(act => !act.course_id);
      } else {
        list = list.filter(act => act.course_id === courseId);
      }
    }

    // 4. Search Query Filter
    if (query) {
      list = list.filter(act => 
        act.title.toLowerCase().includes(query) ||
        (act.id && act.id.toString().includes(query)) ||
        (act.type && act.type.toLowerCase().includes(query)) ||
        (act.course?.name && act.course.name.toLowerCase().includes(query))
      );
    }
    
    return list;
  });

  // Total Pages
  totalPages = computed(() => {
    const total = this.filteredActivities().length;
    const size = this.pageSize();
    if (size === 0) return 1;
    return Math.ceil(total / size) || 1;
  });

  // Paginated Activities
  paginatedActivities = computed(() => {
    const list = this.filteredActivities();
    const size = this.pageSize();
    if (size === 0) return list;
    const page = this.currentPage();
    const start = (page - 1) * size;
    return list.slice(start, start + size);
  });

  // Display indices
  startIndex = computed(() => {
    if (this.filteredActivities().length === 0) return 0;
    return (this.currentPage() - 1) * this.pageSize() + 1;
  });

  endIndex = computed(() => {
    const total = this.filteredActivities().length;
    const size = this.pageSize();
    if (size === 0) return total;
    return Math.min(this.currentPage() * size, total);
  });

  // Smart Page Numbers for Pagination Bar
  pageNumbers = computed(() => {
    const total = this.totalPages();
    const current = this.currentPage();
    const pages: number[] = [];
    
    if (total <= 7) {
      for (let i = 1; i <= total; i++) pages.push(i);
    } else {
      if (current <= 4) {
        pages.push(1, 2, 3, 4, 5, -1, total);
      } else if (current >= total - 3) {
        pages.push(1, -1, total - 4, total - 3, total - 2, total - 1, total);
      } else {
        pages.push(1, -1, current - 1, current, current + 1, -1, total);
      }
    }
    return pages;
  });

  // Current Activity State
  activityId = signal<number | null>(null);
  activityTitle = signal<string>('');
  activityType = signal<string>('mcq');
  activityCourseId = signal<number | null>(null);
  coursesList = signal<CourseData[]>([]);

  // Custom Builder State
  nodes = signal<ContainerNode[]>([]);
  selectedContainerId = signal<string | null>(null);
  customQuestion = signal<string>('');

  // Standard Engine State
  engineData: any = {};
  activityBlockInstance: any = null;
  
  mockApi = { 
    styles: { block: '', inlineToolButton: '', input: 'form-control', settingsButton: '' },
    blocks: { getCurrentBlockIndex: () => Math.floor(Math.random() * 1000) }
  };

  constructor() {
    effect(() => {
      const type = this.activityType();
      // Reset preview mode when type changes
      this.isPreviewMode.set(false);
      if (this.isFormVisible() && type !== 'custom') {
        setTimeout(() => this.renderEngineForm(), 0);
      }
      
      // Automatically set next title if not manually edited and in creation mode
      if (this.isFormVisible() && !this.activityId() && !this.isTitleManuallyEdited()) {
        this.activityTitle.set(this.generateNextTitle(type));
      }
    });
  }

  ngOnInit() {
    this.loadActivities();
    this.loadCourses();
  }

  setSkillTab(tab: 'all' | 'listening' | 'speaking' | 'reading' | 'writing' | 'games') {
    this.selectedSkillTab.set(tab);
    this.currentPage.set(1);
  }

  onFilterChange() {
    this.currentPage.set(1);
  }

  setPage(page: number) {
    if (page >= 1 && page <= this.totalPages()) {
      this.currentPage.set(page);
    }
  }

  clearFilters() {
    this.searchQuery.set('');
    this.filterType.set('all');
    this.selectedSkillTab.set('all');
    this.selectedCourseFilter.set('all');
    this.currentPage.set(1);
  }

  openTemplatePicker() {
    this.isTemplatePickerVisible.set(true);
  }

  closeTemplatePicker() {
    this.isTemplatePickerVisible.set(false);
  }

  selectTemplate(type: string) {
    this.isTemplatePickerVisible.set(false);
    this.showCreateForm(type);
  }

  openTestModal(activity: Activity) {
    this.testingActivity.set(activity);
  }

  closeTestModal() {
    this.testingActivity.set(null);
  }

  getSkillBadgeClass(skill: string): string {
    switch (skill) {
      case 'listening': return 'badge-listening';
      case 'speaking': return 'badge-speaking';
      case 'reading': return 'badge-reading';
      case 'writing': return 'badge-writing';
      case 'games': return 'badge-games';
      default: return 'bg-secondary';
    }
  }

  getSkillIcon(skill: string): string {
    switch (skill) {
      case 'listening': return 'bi-headphones';
      case 'speaking': return 'bi-mic-fill';
      case 'reading': return 'bi-book-half';
      case 'writing': return 'bi-pencil-fill';
      case 'games': return 'bi-controller';
      default: return 'bi-collection';
    }
  }

  loadCourses() {
    this.courseService.getAll().subscribe({
      next: (courses) => this.coursesList.set(courses || []),
      error: () => {}
    });
  }

  generateNextTitle(type: string): string {
    const list = this.savedActivities();
    const countOfType = list.filter(act => act.type === type).length;
    const nextNum = countOfType + 1;

    const names: { [key: string]: string } = {
      mcq: 'MCQ Question',
      fill_blanks: 'Fill in Blanks',
      flashcard: 'Flashcard',
      match: 'Match It',
      crossword: 'Crossword Puzzle',
      word_arrange: 'Word Arrangement',
      speaking: 'Speaking Test',
      role_play: 'Role Play Dialog',
      sequencing: 'Sequencing Event',
      parts_of_speech: 'Parts of Speech',
      mind_map: 'Mind Map',
      writing: 'Paragraph Writing',
      custom: 'Custom Activity'
    };

    const prefix = names[type] || 'Activity';
    return `${prefix} ${nextNum}`;
  }

  loadActivities() {
    this.activityService.getActivities().subscribe({
      next: (activities) => this.savedActivities.set(activities),
      error: (err) => console.error('Failed to load activities', err)
    });
  }

  showCreateForm(type: string = 'mcq') {
    this.activityId.set(null);
    this.isTitleManuallyEdited.set(false);
    this.activityType.set(type);
    this.activityCourseId.set(null);
    this.activityTitle.set(this.generateNextTitle(type));
    this.nodes.set([]);
    this.customQuestion.set('');
    this.selectedContainerId.set(null);
    this.engineData = { type: type };
    this.activityBlockInstance = null;
    this.isFormVisible.set(true);
  }

  editActivity(activity: Activity) {
    this.activityId.set(activity.id || null);
    this.activityTitle.set(activity.title);
    this.activityCourseId.set(activity.course_id || null);
    this.isTitleManuallyEdited.set(true);
    
    const type = activity.type;
    
    if (type === 'custom') {
      if (activity.data_json && activity.data_json.nodes) {
        this.nodes.set(activity.data_json.nodes);
      } else {
        this.nodes.set([]);
      }
      this.customQuestion.set(activity.data_json?.question || '');
      this.activityType.set('custom');
    } else {
      this.engineData = JSON.parse(JSON.stringify(activity.data_json || {}));
      this.engineData.type = type;
      this.activityType.set(type);
    }
    
    this.isFormVisible.set(true);
  }

  cancelForm() {
    this.isFormVisible.set(false);
  }

  deleteActivity(id: number) {
    if (confirm('Are you sure you want to delete this activity?')) {
      this.activityService.deleteActivity(id).subscribe({
        next: () => {
          this.notificationService.show('success', 'Activity deleted');
          this.loadActivities();
        },
        error: () => this.notificationService.show('error', 'Failed to delete activity')
      });
    }
  }

  renderEngineForm() {
    if (!this.standardFormContainer) return;
    const container = this.standardFormContainer.nativeElement;
    container.innerHTML = '';
    
    const type = this.activityType();
    
    if (this.engineData.type !== type) {
      this.engineData = { type };
    }

    this.activityBlockInstance = new ActivityBlock({
      data: this.engineData,
      api: this.mockApi,
      readOnly: false,
      inlineEdit: true
    });

    const element = this.activityBlockInstance.render();
    container.appendChild(element);
  }

  saveActivity() {
    if (!this.activityTitle().trim()) {
      this.notificationService.show('error', 'Please enter a title for this activity');
      return;
    }

    let type = this.activityType();
    let data_json: any = {};

    if (type === 'custom') {
      if (this.nodes().length === 0) {
        this.notificationService.show('error', 'Please add at least one container to the custom activity');
        return;
      }
      data_json = { 
        nodes: this.nodes(),
        question: this.customQuestion()
      };
    } else {
      if (this.activityBlockInstance) {
        data_json = this.activityBlockInstance.save();
        type = data_json.type; 
        this.activityType.set(type); 
      } else {
        data_json = this.engineData;
      }
    }

    this.isSaving.set(true);

    const payload: Partial<Activity> = {
      title: this.activityTitle(),
      type: type,
      course_id: this.activityCourseId(),
      data_json: data_json
    };

    if (this.activityId()) {
      this.activityService.updateActivity(this.activityId()!, payload).subscribe({
        next: (res) => {
          this.isSaving.set(false);
          this.notificationService.show('success', 'Activity updated successfully!');
          this.loadActivities();
          this.isFormVisible.set(false);
        },
        error: (err) => {
          this.isSaving.set(false);
          this.notificationService.show('error', 'Failed to update activity');
        }
      });
    } else {
      this.activityService.createActivity(payload).subscribe({
        next: (res) => {
          this.isSaving.set(false);
          this.notificationService.show('success', 'Activity saved successfully!');
          this.loadActivities();
          this.isFormVisible.set(false);
        },
        error: (err) => {
          this.isSaving.set(false);
          this.notificationService.show('error', 'Failed to save activity');
        }
      });
    }
  }

  private generateId(): string {
    return Math.random().toString(36).substring(2, 9);
  }

  addContainer() {
    const newContainer: ContainerNode = {
      id: 'container_' + this.generateId(),
      type: 'container',
      display: 'block',
      contents: []
    };
    this.nodes.update(current => [...current, newContainer]);
    this.selectedContainerId.set(newContainer.id);
  }

  addBlock(type: 'text' | 'audio' | 'image' | 'video' | 'link' | 'button' | 'input') {
    const activeId = this.selectedContainerId();
    if (!activeId) {
      alert('Please select or create a container first!');
      return;
    }

    const newBlock: BlockContent = {
      id: 'block_' + this.generateId(),
      type: type,
      content: type === 'text' ? 'Enter text here...' : (type === 'button' ? 'Option Text' : (type === 'input' ? 'Type your answer...' : undefined)),
      url: type === 'input' ? 'expected answer' : (type !== 'text' && type !== 'button' ? 'assets/placeholder' : undefined),
      isCorrect: type === 'button' ? false : undefined
    };

    this.nodes.update(current => {
      return current.map(container => {
        if (container.id === activeId) {
          return { ...container, contents: [...container.contents, newBlock] };
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
          return { ...container, contents: container.contents.filter(b => b.id !== blockId) };
        }
        return container;
      });
    });
  }

  onBlockDropped(event: CdkDragDrop<BlockContent[]>) {
    if (event.previousContainer === event.container) {
      moveItemInArray(event.container.data, event.previousIndex, event.currentIndex);
    } else {
      transferArrayItem(
        event.previousContainer.data,
        event.container.data,
        event.previousIndex,
        event.currentIndex
      );
    }
    this.nodes.update(current => [...current]);
  }

  setContainerDisplay(id: string, display: string) {
    this.nodes.update(current => {
      return current.map(container => {
        if (container.id === id) {
          return { ...container, display };
        }
        return container;
      });
    });
  }

  onBlockFileSelected(block: BlockContent, event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    const formData = new FormData();
    formData.append('file', file);

    const uploadUrl = `${environment.apiUrl}/contents/upload`;
    this.http.post<any>(uploadUrl, formData).subscribe({
      next: (res) => {
        if (res && res.url) {
          block.url = res.url;
          this.notificationService.show('success', 'File uploaded successfully!');
        } else {
          this.notificationService.show('error', 'Upload failed: Invalid response');
        }
      },
      error: (err) => {
        console.error('Upload error', err);
        this.notificationService.show('error', 'File upload failed');
      }
    });
  }

  onBlockImageSelected(block: BlockContent, event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    const formData = new FormData();
    formData.append('file', file);

    const uploadUrl = `${environment.apiUrl}/contents/upload`;
    this.http.post<any>(uploadUrl, formData).subscribe({
      next: (res) => {
        if (res && res.url) {
          block.imageUrl = res.url;
          this.notificationService.show('success', 'Image uploaded successfully!');
        } else {
          this.notificationService.show('error', 'Upload failed: Invalid response');
        }
      },
      error: (err) => {
        console.error('Upload error', err);
        this.notificationService.show('error', 'Image upload failed');
      }
    });
  }

  onBlockAudioSelected(block: BlockContent, event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    const formData = new FormData();
    formData.append('file', file);

    const uploadUrl = `${environment.apiUrl}/contents/upload`;
    this.http.post<any>(uploadUrl, formData).subscribe({
      next: (res) => {
        if (res && res.url) {
          block.audioUrl = res.url;
          if (block.type !== 'input') {
            block.url = res.url;
          }
          this.notificationService.show('success', 'Audio uploaded successfully!');
        } else {
          this.notificationService.show('error', 'Upload failed: Invalid response');
        }
      },
      error: (err) => {
        console.error('Upload error', err);
        this.notificationService.show('error', 'Audio upload failed');
      }
    });
  }

  togglePreview() {
    if (!this.isPreviewMode() && this.activityType() !== 'custom') {
      if (this.activityBlockInstance) {
        this.engineData = this.activityBlockInstance.save();
      }
    }
    this.isPreviewMode.set(!this.isPreviewMode());
    if (this.isPreviewMode()) {
      this.selectedContainerId.set(null);
    } else {
      if (this.activityType() !== 'custom') {
        setTimeout(() => this.renderEngineForm(), 0);
      }
    }
  }

  getPreviewActivityData() {
    if (this.activityType() === 'custom') {
      return {
        type: 'custom',
        nodes: this.nodes()
      };
    }
    if (this.activityBlockInstance) {
      const data = this.activityBlockInstance.save();
      return {
        type: this.activityType(),
        ...data
      };
    }
    return {
      type: this.activityType(),
      ...this.engineData
    };
  }

  duplicateActivity(activity: Activity) {
    if (!activity.id) return;
    const payload = {
      title: `${activity.title} (Copy)`,
      type: activity.type,
      data_json: activity.data_json
    };
    this.isSaving.set(true);
    this.activityService.createActivity(payload).subscribe({
      next: () => {
        this.isSaving.set(false);
        this.notificationService.show('success', 'Activity duplicated successfully!');
        this.loadActivities();
      },
      error: (err) => {
        this.isSaving.set(false);
        this.notificationService.show('error', 'Failed to duplicate activity');
      }
    });
  }

  getActivityIcon(type: string): string {
    switch (type) {
      case 'mcq': return 'bi-question-circle';
      case 'fill_blanks': return 'bi-file-earmark-text';
      case 'flashcard': return 'bi-card-text';
      case 'match': return 'bi-columns-gap';
      case 'crossword': return 'bi-grid-3x3';
      case 'word_arrange': return 'bi-arrow-left-right';
      case 'speaking': return 'bi-mic';
      case 'role_play': return 'bi-chat-quote';
      case 'sequencing': return 'bi-list-ol';
      case 'parts_of_speech': return 'bi-tags';
      case 'mind_map': return 'bi-diagram-3';
      case 'writing': return 'bi-pencil';
      case 'custom': return 'bi-palette';
      default: return 'bi-gear';
    }
  }

  getActivityTypeName(type: string): string {
    switch (type) {
      case 'mcq': return 'MCQ';
      case 'fill_blanks': return 'Fill Blanks';
      case 'flashcard': return 'Flashcard';
      case 'match': return 'Match It';
      case 'crossword': return 'Crossword';
      case 'word_arrange': return 'Word Arrange';
      case 'speaking': return 'Speaking';
      case 'role_play': return 'Role Play';
      case 'sequencing': return 'Sequencing';
      case 'parts_of_speech': return 'Parts of Speech';
      case 'mind_map': return 'Mind Map';
      case 'writing': return 'Writing';
      case 'custom': return 'Custom Canvas';
      default: return type;
    }
  }

  getActivityDetailsSummary(activity: Activity): string {
    const data = activity.data_json || {};
    switch (activity.type) {
      case 'mcq':
        return `Question: "${data.question || ''}" | Options: ${data.options?.length || 0}`;
      case 'fill_blanks':
        return `Sentence: "${data.text || ''}"`;
      case 'flashcard':
        return `Front: "${data.front || ''}" | Back: "${data.back || ''}"`;
      case 'match':
        return `Pairs to match: ${data.pairs?.length || 0}`;
      case 'crossword':
        return `Grid: ${data.gridSize || 10}x${data.gridSize || 10} | Words: ${data.words?.length || 0}`;
      case 'word_arrange':
        return `Sentence: "${data.text || ''}"`;
      case 'speaking':
        return `Target Speech: "${data.targetText || ''}"`;
      case 'role_play':
        return `Role play with ${data.dialogue?.length || 0} lines of dialogue`;
      case 'sequencing':
        return `Steps to order: ${data.events?.length || 0}`;
      case 'parts_of_speech':
        return `Sentence: "${data.text || ''}"`;
      case 'mind_map':
        return `Concept nodes: ${data.nodes?.length || 0}`;
      case 'writing':
        return `Topic: "${data.question || ''}"`;
      case 'custom':
        return `Custom nodes layout containing ${data.nodes?.length || 0} items`;
      default:
        return 'No details available';
    }
  }

  onCsvFileSelected(event: any) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e: any) => {
      const text = e.target.result;
      this.importActivitiesFromCsvText(text);
    };
    reader.readAsText(file);
    event.target.value = ''; // Reset file input
  }

  private importActivitiesFromCsvText(text: string) {
    const lines = text.split(/\r?\n/);
    if (lines.length <= 1) {
      this.notificationService.show('error', 'CSV file is empty or only has headers');
      return;
    }

    const parseCsvLine = (line: string): string[] => {
      const result = [];
      let current = '';
      let inQuotes = false;
      for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
          inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
          result.push(current.trim());
          current = '';
        } else {
          current += char;
        }
      }
      result.push(current.trim());
      return result.map(val => val.replace(/^"|"$/g, '').replace(/""/g, '"').trim());
    };

    const headers = parseCsvLine(lines[0]);
    const titleIdx = headers.findIndex(h => h.toLowerCase() === 'title');
    const typeIdx = headers.findIndex(h => h.toLowerCase() === 'type');
    const questionIdx = headers.findIndex(h => h.toLowerCase() === 'question');
    const optionsIdx = headers.findIndex(h => h.toLowerCase() === 'options');
    const explanationIdx = headers.findIndex(h => h.toLowerCase() === 'explanation');

    if (titleIdx === -1 || typeIdx === -1 || questionIdx === -1 || optionsIdx === -1) {
      this.notificationService.show('error', 'CSV must contain columns: Title, Type, Question, Options');
      return;
    }

    this.isSaving.set(true);
    let successCount = 0;
    let failCount = 0;
    const createPromises = [];

    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;
      const cols = parseCsvLine(lines[i]);
      if (cols.length < 3) continue;

      const title = cols[titleIdx];
      const type = cols[typeIdx]?.toLowerCase();
      const question = cols[questionIdx] || '';
      const rawOptions = cols[optionsIdx] || '';
      const explanation = (explanationIdx !== -1 && cols[explanationIdx]) ? cols[explanationIdx] : '';

      if (!title || !type) continue;
      const questionRequiredTypes = ['mcq', 'fill_blanks', 'flashcard', 'word_arrange', 'speaking', 'parts_of_speech', 'writing'];
      if (questionRequiredTypes.includes(type) && !question) continue;

      let data_json: any = {};
      if (type === 'mcq') {
        const optionParts = rawOptions.split(';');
        const options = optionParts.map(opt => {
          const isCorrect = opt.endsWith('*');
          const text = isCorrect ? opt.slice(0, -1) : opt;
          return { text, isCorrect };
        });
        data_json = {
          type: 'mcq',
          question,
          options,
          explanation
        };
      } else if (type === 'fill_blanks') {
        data_json = {
          type: 'fill_blanks',
          text: question,
          explanation
        };
      } else if (type === 'flashcard') {
        data_json = {
          type: 'flashcard',
          front: question,
          back: rawOptions,
          explanation
        };
      } else if (type === 'match') {
        const pairParts = rawOptions.split(';');
        const pairs = pairParts.map(pair => {
          const [left, right] = pair.split('=');
          return { left: (left || '').trim(), right: (right || '').trim() };
        });
        data_json = {
          type: 'match',
          pairs,
          explanation
        };
      } else if (type === 'crossword') {
        const wordParts = rawOptions.split(';');
        const words = wordParts.map(w => {
          const [word, clue] = w.split('=');
          return { word: (word || '').trim(), clue: (clue || '').trim() };
        });
        data_json = {
          type: 'crossword',
          gridSize: 10,
          words,
          explanation
        };
      } else if (type === 'word_arrange') {
        data_json = {
          type: 'word_arrange',
          text: question,
          explanation
        };
      } else if (type === 'speaking') {
        data_json = {
          type: 'speaking',
          targetText: question,
          explanation
        };
      } else if (type === 'role_play') {
        const lineParts = rawOptions.split(';');
        const dialogue = lineParts.map(line => {
          const [role, text] = line.split('=');
          return { role: (role || '').trim(), text: (text || '').trim() };
        });
        data_json = {
          type: 'role_play',
          dialogue,
          explanation
        };
      } else if (type === 'sequencing') {
        const stepParts = rawOptions.split(';');
        const events = stepParts.map(text => ({ text: text.trim() }));
        data_json = {
          type: 'sequencing',
          events,
          explanation
        };
      } else if (type === 'parts_of_speech') {
        data_json = {
          type: 'parts_of_speech',
          text: question,
          explanation
        };
      } else if (type === 'mind_map') {
        const nodeParts = rawOptions.split(';');
        const nodes = nodeParts.map(text => ({ text: text.trim() }));
        data_json = {
          type: 'mind_map',
          nodes,
          explanation
        };
      } else if (type === 'writing') {
        data_json = {
          type: 'writing',
          question,
          explanation
        };
      } else {
        data_json = {
          type,
          question,
          explanation
        };
      }

      const payload = {
        title,
        type,
        data_json
      };

      createPromises.push(new Promise<void>((resolve) => {
        this.activityService.createActivity(payload).subscribe({
          next: () => {
            successCount++;
            resolve();
          },
          error: () => {
            failCount++;
            resolve();
          }
        });
      }));
    }

    Promise.all(createPromises).then(() => {
      this.isSaving.set(false);
      this.notificationService.show('success', `Import complete: ${successCount} imported, ${failCount} failed.`);
      this.loadActivities();
    });
  }

  // --- Linking & Mapping Methods ---

  openLinkingModal(activity: Activity) {
    this.linkingActivity.set(activity);
    this.contentService.getAll().subscribe({
      next: (contents) => {
        this.mappingContents.set(contents);
      },
      error: () => {
        this.notificationService.show('error', 'Failed to load lesson content pages');
      }
    });
  }

  closeLinkingModal() {
    this.linkingActivity.set(null);
    this.mappingContents.set([]);
    this.selectedLinkContentId.set(null);
    this.selectedContentDetail.set(null);
    this.mappedLessonActivities.set([]);
  }

  onLinkContentSelected(event: any) {
    const contentIdVal = event.target.value;
    if (!contentIdVal) {
      this.selectedLinkContentId.set(null);
      this.selectedContentDetail.set(null);
      this.mappedLessonActivities.set([]);
      return;
    }

    const contentId = Number(contentIdVal);
    this.selectedLinkContentId.set(contentId);
    this.loadContentDetails(contentId);
  }

  loadContentDetails(contentId: number) {
    this.isLoadingContentDetails.set(true);
    this.contentService.getById(contentId).subscribe({
      next: (content) => {
        this.selectedContentDetail.set(content);
        this.parseContentActivities(content);
        this.isLoadingContentDetails.set(false);
      },
      error: () => {
        this.isLoadingContentDetails.set(false);
        this.notificationService.show('error', 'Failed to load content details');
      }
    });
  }

  parseContentActivities(content: ContentData) {
    const list: any[] = [];
    if (!content.text_content) {
      this.mappedLessonActivities.set([]);
      return;
    }
    
    try {
      const data = typeof content.text_content === 'string' ? JSON.parse(content.text_content) : content.text_content;
      if (data && Array.isArray(data.blocks)) {
        data.blocks.forEach((block: any, index: number) => {
          if (block.type === 'activity') {
            const actData = block.data || {};
            if (actData.type === 'activity_reference') {
              list.push({
                blockIndex: index,
                id: actData.activityReferenceId,
                title: actData.activityReferenceTitle || `Activity Reference #${actData.activityReferenceId}`,
                type: actData.activityReferenceType || 'Unknown'
              });
            } else {
              list.push({
                blockIndex: index,
                id: null,
                title: `Manual Inline Activity`,
                type: actData.type || 'Unknown'
              });
            }
          }
        });
      }
    } catch (e) {
      console.error('Error parsing text_content json', e);
    }
    
    this.mappedLessonActivities.set(list);
  }

  isActivityAlreadyMapped(): boolean {
    const act = this.linkingActivity();
    if (!act) return false;
    return this.mappedLessonActivities().some(item => item.id === act.id);
  }

  linkActivityToContent() {
    const content = this.selectedContentDetail();
    const act = this.linkingActivity();
    if (!content || !act || this.isLinkingInProgress()) return;

    this.isLinkingInProgress.set(true);

    let textContentObj: any = { blocks: [] };
    if (content.text_content) {
      try {
        textContentObj = typeof content.text_content === 'string' ? JSON.parse(content.text_content) : content.text_content;
      } catch (e) {
        textContentObj = { blocks: [] };
      }
    }

    if (!textContentObj.blocks) {
      textContentObj.blocks = [];
    }

    // Append new activity reference block
    textContentObj.blocks.push({
      type: 'activity',
      data: {
        type: 'activity_reference',
        activityReferenceId: act.id,
        activityReferenceTitle: act.title,
        activityReferenceType: act.type
      }
    });

    const updatedData = {
      ...content,
      text_content: JSON.stringify(textContentObj)
    };

    this.contentService.update(content.id!, updatedData).subscribe({
      next: (newContent) => {
        this.selectedContentDetail.set(newContent);
        this.parseContentActivities(newContent);
        this.isLinkingInProgress.set(false);
        this.notificationService.show('success', 'Activity mapped successfully');
      },
      error: () => {
        this.isLinkingInProgress.set(false);
        this.notificationService.show('error', 'Failed to map activity');
      }
    });
  }

  unmapActivityFromContent(blockIndex: number) {
    const content = this.selectedContentDetail();
    if (!content || blockIndex === undefined) return;
    
    if (!confirm('Are you sure you want to remove this activity from the lesson?')) {
      return;
    }

    let textContentObj: any = { blocks: [] };
    if (content.text_content) {
      try {
        textContentObj = typeof content.text_content === 'string' ? JSON.parse(content.text_content) : content.text_content;
      } catch (e) {
        textContentObj = { blocks: [] };
      }
    }

    if (textContentObj.blocks && Array.isArray(textContentObj.blocks)) {
      // Remove the block at blockIndex
      textContentObj.blocks.splice(blockIndex, 1);
    }

    const updatedData = {
      ...content,
      text_content: JSON.stringify(textContentObj)
    };

    this.contentService.update(content.id!, updatedData).subscribe({
      next: (newContent) => {
        this.selectedContentDetail.set(newContent);
        this.parseContentActivities(newContent);
        this.notificationService.show('success', 'Activity unmapped successfully');
      },
      error: () => {
        this.notificationService.show('error', 'Failed to unmap activity');
      }
    });
  }
}
