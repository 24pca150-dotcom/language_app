import { Component, OnInit, inject, signal } from '@angular/core';
import { environment } from '../../../environments/environment';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { CourseService } from '../../services/course';
import { AuthService } from '../../services/auth';
import { AudioService } from '../../services/audio.service';
import { ActivityService, Activity } from '../../services/activity.service';
import { LottieComponent, AnimationOptions } from 'ngx-lottie';
import confetti from 'canvas-confetti';

interface Course {
  id: number;
  name: string;
  code?: string;
  description: string;
  no_of_levels?: number;
  is_active: boolean;
}

export interface MatchPairItem {
  id: number;
  leftText: string;
  leftHint?: string;
  rightText: string;
  rightHint?: string;
}

export interface MatchSet {
  id: number;
  title: string;
  category: string;
  icon: string;
  pairs: MatchPairItem[];
}

export interface PracticeTopicItem {
  id: 'match' | 'flashcards' | 'quiz' | 'scramble' | 'blanks';
  title: string;
  badge: string;
  description: string;
  icon: string;
  color: string;
  countLabel: string;
}

export interface FlashcardItem {
  id: number;
  front: string;
  frontLanguage: string;
  back: string;
  backLanguage: string;
  pronunciation: string;
}

export interface WordScrambleItem {
  id: number;
  englishMeaning: string;
  sentenceWords: string[];
  correctSentence: string;
}

export interface BlankQuestionItem {
  id: number;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export interface LiveClassAttachment {
  id: number;
  live_class_id: number;
  title?: string;
  file_type: string;
  file_path: string;
  original_name: string;
  file_extension: string;
  file_size: string;
  file_url: string;
}

export interface WeeklyDay {
  dayName: string;
  label: string;
  isToday: boolean;
  isCompleted: boolean;
  activityCount: number;
}

export interface LiveClassItem {
  id: number;
  title: string;
  description?: string;
  meeting_link: string;
  platform: string;
  instructor_name?: string;
  start_time: string;
  duration_minutes: number;
  status: 'scheduled' | 'live' | 'completed' | 'cancelled';
  attachments?: LiveClassAttachment[];
}

@Component({
  selector: 'app-learner-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, LottieComponent],
  templateUrl: './learner-dashboard.html',
  styleUrls: ['./learner-dashboard.css']
})
export class LearnerDashboard implements OnInit {
  private http = inject(HttpClient);
  private router = inject(Router);
  private courseService = inject(CourseService);
  protected authService = inject(AuthService);
  private audioService = inject(AudioService);
  private activityService = inject(ActivityService);

  courses = signal<Course[]>([]);
  allDynamicActivities = signal<Activity[]>([]);
  isLoadingActivities = signal<boolean>(false);
  isLoading = signal(true);
  upcomingLiveClass = signal<LiveClassItem | null>(null);
  allUpcomingClasses = signal<LiveClassItem[]>([]);
  isLoadingLiveClass = signal<boolean>(false);
  isFullscreen = signal(false);
  uiTheme = signal<'adventure' | 'classic'>('adventure');
  xp = signal<number>(0);
  streakDays = signal<number>(0);
  wordsMastered = signal<number>(0);
  studyTimeMinutes = signal<number>(0);
  lessonsFinished = signal<number>(0);
  quizzesPassed = signal<number>(0);
  accuracyRate = signal<number>(0);
  listeningScore = signal<number>(0);
  readingScore = signal<number>(0);
  grammarScore = signal<number>(0);
  speakingScore = signal<number>(0);

  // Weekly Consistency & Daily Goal State
  weeklyDays = signal<WeeklyDay[]>([]);
  daysMetCount = signal<number>(0);
  todayProgressMinutes = signal<number>(0);
  todayProgressPercent = signal<number>(0);

  activeTab = signal<'home' | 'learn' | 'practice' | 'badges' | 'progress' | 'settings'>('home');
  selectedCourseNotice = signal<string | null>(null);

  // Settings State
  learnerName = signal<string>('Learner');
  targetLanguage = signal<string>('English');
  dailyGoal = signal<string>('15');
  soundEnabled = signal<boolean>(true);
  notificationsEnabled = signal<boolean>(true);
  settingsSavedNotice = signal<boolean>(false);

  // =========================================================================
  // ⚡ PRACTICE HIERARCHY STATE (Courses -> Topics -> Inside Activity)
  // =========================================================================
  practiceStage = signal<'courses' | 'topics' | 'activity'>('courses');
  selectedPracticeCourse = signal<Course | null>(null);
  selectedPracticeTopic = signal<'match' | 'flashcards' | 'quiz' | 'scramble' | 'blanks'>('match');

  // 🧩 Match It State (5 Diverse Rounds with 5 Pairs Each)
  currentMatchSetIndex = signal<number>(0);
  selectedLeftPair = signal<number | null>(null);
  selectedRightPair = signal<number | null>(null);
  matchedPairIds = signal<number[]>([]);
  shuffledRightItems = signal<{ id: number; text: string; hint?: string }[]>([]);
  matchScore = signal<number>(0);
  matchStreak = signal<number>(0);
  isSetComplete = signal<boolean>(false);
  isAllSetsComplete = signal<boolean>(false);
  shakeLeftId = signal<number | null>(null);
  shakeRightId = signal<number | null>(null);
  matchFeedback = signal<string | null>(null);

  // 🗂️ Interactive Flashcard State
  flashcardIndex = signal<number>(0);
  isCardFlipped = signal<boolean>(false);

  // ⚡ Speed Quiz Challenge State
  quizStep = signal<number>(0);
  quizScore = signal<number>(0);
  quizAnswered = signal<boolean>(false);
  quizFeedback = signal<string | null>(null);

  // 🔤 Word Scramble State
  scrambleIndex = signal<number>(0);
  scrambleSelectedWords = signal<string[]>([]);
  scrambleAvailableWords = signal<string[]>([]);
  scrambleAnswered = signal<boolean>(false);
  scrambleIsCorrect = signal<boolean>(false);

  // ✍️ Fill in Blanks State
  blankIndex = signal<number>(0);
  blankAnswered = signal<boolean>(false);
  selectedBlankOption = signal<number | null>(null);
  blankIsCorrect = signal<boolean>(false);

  // Practice Topics List
  practiceTopics: PracticeTopicItem[] = [
    {
      id: 'match',
      title: 'Match It',
      badge: '5 Sets Available • +50 XP',
      description: 'Match words with their translations and meanings across 5 interactive sets. Fast and engaging vocabulary pairing!',
      icon: 'bi-puzzle-fill',
      color: '#F59E0B',
      countLabel: '5 Interactive Sets'
    },
    {
      id: 'flashcards',
      title: 'Interactive Flashcards',
      badge: '5 Cards Deck • +30 XP',
      description: 'Flip 3D memory cards with pronunciation guides and English translations to train your memory.',
      icon: 'bi-card-text',
      color: '#3B82F6',
      countLabel: '5 Flip Cards'
    },
    {
      id: 'quiz',
      title: 'Speed Quiz Challenge',
      badge: '5 Questions • +50 XP',
      description: 'Rapid-fire multiple choice questions. Pick the right answer quickly to earn bonus XP and sharpen recall!',
      icon: 'bi-lightning-charge-fill',
      color: '#10B981',
      countLabel: '5 MCQ Drills'
    },
    {
      id: 'scramble',
      title: 'Word Scramble',
      badge: 'Sentence Builder • +40 XP',
      description: 'Tap jumbled words in the correct grammatical order to form meaningful everyday sentences.',
      icon: 'bi-sort-alpha-down',
      color: '#8B5CF6',
      countLabel: '5 Word Puzzles'
    },
    {
      id: 'blanks',
      title: 'Fill in the Blanks',
      badge: 'Grammar Drills • +40 XP',
      description: 'Select the missing words in essential conversations to master sentence structures and grammar.',
      icon: 'bi-input-cursor-text',
      color: '#EC4899',
      countLabel: '5 Context Sentences'
    }
  ];

  // 5 Complete Match It Sets (5 Pairs Each)
  matchSets: MatchSet[] = [
    {
      id: 1,
      title: 'Set 1: Everyday Greetings & Manners',
      category: 'Greetings & Etiquette',
      icon: 'bi-hand-thumbs-up-fill',
      pairs: [
        { id: 101, leftText: 'Hello / Hi', leftHint: 'Universal friendly greeting', rightText: 'வணக்கம் (Vanakkam)', rightHint: 'Spanish: Hola' },
        { id: 102, leftText: 'Good morning', leftHint: 'Early morning greeting', rightText: 'காலை வணக்கம் (Kaalai Vanakkam)', rightHint: 'Spanish: Buenos días' },
        { id: 103, leftText: 'Thank you', leftHint: 'Expression of gratitude', rightText: 'நன்றி (Nandri)', rightHint: 'Spanish: Gracias' },
        { id: 104, leftText: 'Please', leftHint: 'Polite request word', rightText: 'தயவுசெய்து (Thayavu Seithu)', rightHint: 'Spanish: Por favor' },
        { id: 105, leftText: 'Goodbye', leftHint: 'Parting farewell', rightText: 'சென்று வருகிறேன் (Sendru Varugiren)', rightHint: 'Spanish: Adiós' }
      ]
    },
    {
      id: 2,
      title: 'Set 2: Food, Drinks & Dining',
      category: 'Food & Meals',
      icon: 'bi-cup-hot-fill',
      pairs: [
        { id: 201, leftText: 'Water', leftHint: 'Essential clear fluid', rightText: 'தண்ணீர் (Thanneer)', rightHint: 'Spanish: Agua' },
        { id: 202, leftText: 'Bread', leftHint: 'Baked food staple', rightText: 'ரொட்டி (Rotti)', rightHint: 'Spanish: Pan' },
        { id: 203, leftText: 'Apple', leftHint: 'Crisp sweet fruit', rightText: 'ஆப்பிள் பழம் (Apple)', rightHint: 'Spanish: Manzana' },
        { id: 204, leftText: 'Coffee', leftHint: 'Warm brewed beverage', rightText: 'காபி (Coffee)', rightHint: 'Spanish: Café' },
        { id: 205, leftText: 'Milk', leftHint: 'Nutritious dairy drink', rightText: 'பால் (Paal)', rightHint: 'Spanish: Leche' }
      ]
    },
    {
      id: 3,
      title: 'Set 3: Family, People & Relations',
      category: 'Family & Relations',
      icon: 'bi-people-fill',
      pairs: [
        { id: 301, leftText: 'Father', leftHint: 'Male parent', rightText: 'அப்பா (Appa)', rightHint: 'Spanish: Padre' },
        { id: 302, leftText: 'Mother', leftHint: 'Female parent', rightText: 'அம்மா (Amma)', rightHint: 'Spanish: Madre' },
        { id: 303, leftText: 'Brother', leftHint: 'Male sibling', rightText: 'சகோதரன் (Sagodharan)', rightHint: 'Spanish: Hermano' },
        { id: 304, leftText: 'Sister', leftHint: 'Female sibling', rightText: 'சகோதரி (Sagodhari)', rightHint: 'Spanish: Hermana' },
        { id: 305, leftText: 'Friend', leftHint: 'Close companion', rightText: 'நண்பர் (Nanbar)', rightHint: 'Spanish: Amigo' }
      ]
    },
    {
      id: 4,
      title: 'Set 4: Colors, Nature & Environment',
      category: 'Colors & Nature',
      icon: 'bi-palette-fill',
      pairs: [
        { id: 401, leftText: 'Red', leftHint: 'Warm vibrant color', rightText: 'சிவப்பு (Sivappu)', rightHint: 'Spanish: Rojo' },
        { id: 402, leftText: 'Blue', leftHint: 'Color of deep ocean', rightText: 'நீலம் (Neelam)', rightHint: 'Spanish: Azul' },
        { id: 403, leftText: 'Green', leftHint: 'Color of lush grass', rightText: 'பச்சை (Pachai)', rightHint: 'Spanish: Verde' },
        { id: 404, leftText: 'Sun', leftHint: 'Bright daytime star', rightText: 'சூரியன் (Sooriyan)', rightHint: 'Spanish: Sol' },
        { id: 405, leftText: 'Moon', leftHint: 'Nighttime celestial light', rightText: 'நிலா (Nila)', rightHint: 'Spanish: Luna' }
      ]
    },
    {
      id: 5,
      title: 'Set 5: Everyday Actions & Common Verbs',
      category: 'Action Verbs',
      icon: 'bi-activity',
      pairs: [
        { id: 501, leftText: 'To eat', leftHint: 'Consume food', rightText: 'சாப்பிடு (Saapidu)', rightHint: 'Spanish: Comer' },
        { id: 502, leftText: 'To drink', leftHint: 'Swallow liquids', rightText: 'குடி (Kudi)', rightHint: 'Spanish: Beber' },
        { id: 503, leftText: 'To speak', leftHint: 'Talk or converse', rightText: 'பேசு (Pesu)', rightHint: 'Spanish: Hablar' },
        { id: 504, leftText: 'To read', leftHint: 'Look at written words', rightText: 'படி (Padi)', rightHint: 'Spanish: Leer' },
        { id: 505, leftText: 'To sleep', leftHint: 'Rest at night', rightText: 'தூங்கு (Thoongu)', rightHint: 'Spanish: Dormir' }
      ]
    }
  ];

  // Flashcards Deck
  flashcardDeck: FlashcardItem[] = [
    { id: 1, front: 'Buenos Días', frontLanguage: 'Spanish', back: 'Good Morning!', backLanguage: 'English', pronunciation: '[bwe-nos dee-as]' },
    { id: 2, front: 'Por favor', frontLanguage: 'Spanish', back: 'Please', backLanguage: 'English', pronunciation: '[por fah-vor]' },
    { id: 3, front: 'Muchas Gracias', frontLanguage: 'Spanish', back: 'Thank You Very Much!', backLanguage: 'English', pronunciation: '[moo-chas grah-syahs]' },
    { id: 4, front: '¿Cómo estás?', frontLanguage: 'Spanish', back: 'How are you?', backLanguage: 'English', pronunciation: '[koh-moh eh-stahs]' },
    { id: 5, front: 'Hasta luego', frontLanguage: 'Spanish', back: 'See you later / Goodbye!', backLanguage: 'English', pronunciation: '[ahs-tah lweh-goh]' }
  ];

  // Word Scramble Sentences
  wordScrambleSets: WordScrambleItem[] = [
    {
      id: 1,
      englishMeaning: 'I want to learn English every day.',
      sentenceWords: ['I', 'want', 'to', 'learn', 'English', 'every', 'day'],
      correctSentence: 'I want to learn English every day'
    },
    {
      id: 2,
      englishMeaning: 'Where is the nearest train station?',
      sentenceWords: ['Where', 'is', 'the', 'nearest', 'train', 'station?'],
      correctSentence: 'Where is the nearest train station?'
    },
    {
      id: 3,
      englishMeaning: 'Can you help me please?',
      sentenceWords: ['Can', 'you', 'help', 'me', 'please?'],
      correctSentence: 'Can you help me please?'
    },
    {
      id: 4,
      englishMeaning: 'This coffee is very delicious.',
      sentenceWords: ['This', 'coffee', 'is', 'very', 'delicious'],
      correctSentence: 'This coffee is very delicious'
    },
    {
      id: 5,
      englishMeaning: 'Have a wonderful and happy day.',
      sentenceWords: ['Have', 'a', 'wonderful', 'and', 'happy', 'day'],
      correctSentence: 'Have a wonderful and happy day'
    }
  ];

  // Fill in the Blanks Drills
  blankQuestions: BlankQuestionItem[] = [
    {
      id: 1,
      prompt: 'Good _____! How was your weekend?',
      options: ['Morning', 'Water', 'Sleep', 'Table'],
      correctIndex: 0,
      explanation: '"Good morning" is the polite morning greeting.'
    },
    {
      id: 2,
      prompt: 'Could you please _____ me a cup of tea?',
      options: ['bring', 'run', 'sing', 'jump'],
      correctIndex: 0,
      explanation: '"bring" is the correct verb for requesting an item.'
    },
    {
      id: 3,
      prompt: 'I am practicing a new _____ with LangNest today.',
      options: ['language', 'sandwich', 'chair', 'cloud'],
      correctIndex: 0,
      explanation: '"language" is the correct noun for what you study in LangNest.'
    },
    {
      id: 4,
      prompt: 'She speaks conversational English very _____.',
      options: ['fluently', 'blue', 'yesterday', 'quiet'],
      correctIndex: 0,
      explanation: '"fluently" is the adverb describing smooth speaking.'
    },
    {
      id: 5,
      prompt: 'Thank you _____ much for your helpful assistance.',
      options: ['so', 'how', 'when', 'under'],
      correctIndex: 0,
      explanation: '"so much" is the common intensifying phrase for gratitude.'
    }
  ];

  quizQuestions = [
    {
      question: 'What is the Spanish word for "Hello"?',
      options: ['Hola', 'Adiós', 'Gracias', 'Por favor'],
      correct: 0
    },
    {
      question: 'Which of the following means "Thank You" in French?',
      options: ['Bonjour', 'Merci', 'S\'il vous plaît', 'Oui'],
      correct: 1
    },
    {
      question: 'How do you say "Good Morning" in German?',
      options: ['Guten Tag', 'Gute Nacht', 'Guten Morgen', 'Tschüss'],
      correct: 2
    },
    {
      question: 'What is the Spanish word for "Water"?',
      options: ['Fuego', 'Agua', 'Tierra', 'Viento'],
      correct: 1
    },
    {
      question: 'Which word expresses "Please" in Spanish?',
      options: ['De nada', 'Por favor', 'Perdón', 'Hasta pronto'],
      correct: 1
    }
  ];

  // Dynamic practice courses list
  get practiceCoursesList(): Course[] {
    const list = this.courses();
    if (list && list.length > 0) {
      return list;
    }
    return [
      {
        id: 7,
        name: 'English for Beginners',
        code: 'CRS-00001',
        description: 'Master everyday conversational English, greetings, vocabulary, and practical sentences.',
        no_of_levels: 1,
        is_active: true
      },
      {
        id: 8,
        name: 'Spanish Fundamentals',
        code: 'CRS-00002',
        description: 'Explore essential Spanish phrases, pronunciation drills, and conversational expressions.',
        no_of_levels: 1,
        is_active: true
      },
      {
        id: 9,
        name: 'French for Everyday Life',
        code: 'CRS-00003',
        description: 'Build confidence in French pronunciation, cafe dialogues, and cultural etiquette.',
        no_of_levels: 1,
        is_active: true
      }
    ];
  }

  // Achievement Lottie Configuration
  achievementLottieOptions: AnimationOptions = {
    path: '/assets/trophy.json',
    autoplay: false,
    loop: false
  };
  showAchievementModal = signal(false);

  ngOnInit() {
    const user = this.authService.getUser();
    if (user && user.name) {
      this.learnerName.set(user.name);
    }

    this.detectRouteTab(this.router.url);

    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        this.detectRouteTab(event.urlAfterRedirects || event.url);
      }
    });

    this.initWeeklyConsistency();

    // Load student stats
    this.http.get<any>(`${environment.apiUrl}/student/dashboard`).subscribe({
      next: (stats) => {
        if (stats) {
          if (stats.xp_points !== undefined) this.xp.set(stats.xp_points);
          if (stats.streak_days !== undefined) this.streakDays.set(stats.streak_days);
          if (stats.average_score !== undefined) this.accuracyRate.set(Math.round(stats.average_score));
          if (stats.completed_chapters !== undefined) this.lessonsFinished.set(stats.completed_chapters);
          if (stats.monthly_study_hours && stats.monthly_study_hours.length > 0) {
            const latest = stats.monthly_study_hours[stats.monthly_study_hours.length - 1];
            if (latest && latest.hours) this.studyTimeMinutes.set(Math.round(latest.hours * 60));
          }
          if (stats.weekly_activity && Array.isArray(stats.weekly_activity)) {
            this.initWeeklyConsistency(stats.weekly_activity);
          }
        }
      },
      error: () => {}
    });

    this.fetchCourses();
    this.loadUpcomingLiveClasses();
    this.fetchDynamicActivities();
  }

  initWeeklyConsistency(weeklyActivity?: number[]) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const now = new Date();
    // Monday = 0, Tuesday = 1, Wednesday = 2, Thursday = 3, Friday = 4, Saturday = 5, Sunday = 6
    const todayIndex = (now.getDay() + 6) % 7;

    let met = 0;
    const days: WeeklyDay[] = dayNames.map((name, index) => {
      const count = (weeklyActivity && weeklyActivity[index]) ? weeklyActivity[index] : 0;
      const isToday = index === todayIndex;
      const isCompleted = count > 0;
      if (isCompleted) met++;

      return {
        dayName: name,
        label: isToday ? 'Today' : name,
        isToday,
        isCompleted,
        activityCount: count
      };
    });

    this.weeklyDays.set(days);
    this.daysMetCount.set(met);

    // Dynamic Daily Goal progress
    const todayCount = (weeklyActivity && weeklyActivity[todayIndex]) ? weeklyActivity[todayIndex] : 0;
    const goalMins = parseInt(this.dailyGoal(), 10) || 15;
    const progressMins = Math.min(todayCount * 5, goalMins);
    this.todayProgressMinutes.set(progressMins);
    this.todayProgressPercent.set(goalMins > 0 ? Math.min(Math.round((progressMins / goalMins) * 100), 100) : 0);
  }

  loadUpcomingLiveClasses() {
    this.isLoadingLiveClass.set(true);
    this.http.get<LiveClassItem[]>(`${environment.apiUrl}/live-classes/upcoming`).subscribe({
      next: (classes) => {
        this.allUpcomingClasses.set(classes || []);
        if (classes && classes.length > 0) {
          this.upcomingLiveClass.set(classes[0]);
        } else {
          this.upcomingLiveClass.set(null);
        }
        this.isLoadingLiveClass.set(false);
      },
      error: () => {
        this.isLoadingLiveClass.set(false);
      }
    });
  }

  getPlatformBadgeInfo(platform?: string): { name: string; icon: string } {
    switch (platform) {
      case 'google_meet': return { name: 'Google Meet', icon: 'bi-google' };
      case 'zoom': return { name: 'Zoom Meeting', icon: 'bi-camera-video-fill' };
      case 'teams': return { name: 'Microsoft Teams', icon: 'bi-microsoft' };
      case 'youtube': return { name: 'YouTube Live', icon: 'bi-youtube' };
      default: return { name: 'Live Session', icon: 'bi-broadcast' };
    }
  }

  getMaterialIcon(fileType: string): string {
    switch (fileType) {
      case 'pdf': return 'bi-file-earmark-pdf-fill text-danger';
      case 'video': return 'bi-film text-info';
      case 'audio': return 'bi-music-note-beamed text-success';
      case 'image': return 'bi-file-earmark-image-fill text-warning';
      default: return 'bi-file-earmark-text-fill text-white';
    }
  }

  private detectRouteTab(url: string) {
    const path = url.split('?')[0];
    if (path.includes('/courses')) {
      this.activeTab.set('learn');
    } else if (path.includes('/practice')) {
      this.activeTab.set('practice');
      if (!this.selectedPracticeCourse()) {
        this.practiceStage.set('courses');
      }
      this.fetchDynamicActivities();
    } else if (path.includes('/badges') || path.includes('/achievements')) {
      this.activeTab.set('badges');
    } else if (path.includes('/progress')) {
      this.activeTab.set('progress');
    } else if (path.includes('/settings')) {
      this.activeTab.set('settings');
    } else {
      this.activeTab.set('home');
    }
  }

  fetchCourses() {
    this.http.get<Course[]>(`${environment.apiUrl}/courses`).subscribe({
      next: (data) => {
        const activeCourses = data.filter(c => c.is_active);
        this.courses.set(activeCourses);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  setTab(tab: 'home' | 'learn' | 'practice' | 'badges' | 'progress' | 'settings') {
    this.activeTab.set(tab);
    let routePath = 'dashboard';
    if (tab === 'learn') routePath = 'courses';
    else if (tab === 'practice') {
      routePath = 'practice';
      // Always reset back to course selection when clicking practice from menu
      this.practiceStage.set('courses');
      this.fetchDynamicActivities();
    }
    else if (tab === 'badges') routePath = 'badges';
    else if (tab === 'progress') routePath = 'progress';
    else if (tab === 'settings') routePath = 'settings';

    this.router.navigate(['/learn', routePath]);

    if (tab === 'badges') {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 }
      });
    }
  }

  playCourse(course: Course, event: MouseEvent) {
    event.preventDefault();
    const url = `${environment.apiUrl}/courses/${course.id}/player-structure`;
    this.http.get<any>(url).subscribe({
      next: (structure) => {
        this.courseService.cachedStructure = structure;
        this.router.navigate(['/learn', course.id]);
      },
      error: () => {
        this.router.navigate(['/learn', course.id]);
      }
    });
  }

  getCourseImage(name: string): string {
    const lower = (name || '').toLowerCase();
    if (lower.includes('english')) return '/assets/images/landmark_london.jpg';
    if (lower.includes('spanish') || lower.includes('espanol')) return '/assets/images/landmark_spain.jpg';
    if (lower.includes('french') || lower.includes('francais')) return '/assets/images/landmark_france.jpg';
    if (lower.includes('german') || lower.includes('deutsch')) return '/assets/images/landmark_germany.jpg';
    return '/assets/images/landmark_london.jpg';
  }

  // =========================================================================
  // ⚡ PRACTICE INTERACTION & NAVIGATION METHODS
  // =========================================================================
  selectPracticeCourse(course: Course) {
    this.selectedPracticeCourse.set(course);
    this.practiceStage.set('topics');
    this.fetchDynamicActivities(course.id);
  }

  backToPracticeCourses() {
    this.practiceStage.set('courses');
    this.fetchDynamicActivities();
  }

  fetchDynamicActivities(courseId?: number) {
    this.isLoadingActivities.set(true);
    const targetCourseId = courseId || this.selectedPracticeCourse()?.id;
    this.activityService.getActivities(undefined, targetCourseId).subscribe({
      next: (activities) => {
        this.isLoadingActivities.set(false);
        if (activities && activities.length > 0) {
          this.allDynamicActivities.set(activities);
          this.processDynamicActivities(activities);
        }
      },
      error: (err) => {
        this.isLoadingActivities.set(false);
        console.error('Failed to fetch dynamic activities:', err);
      }
    });
  }

  processDynamicActivities(activities: Activity[]) {
    if (!activities || activities.length === 0) return;

    const currentCourseId = this.selectedPracticeCourse()?.id;

    // Filter by current course if selected, otherwise prioritize matching course or generic (null course_id)
    const relevant = currentCourseId
      ? activities.filter(a => a.course_id === currentCourseId || !a.course_id)
      : activities;

    // 1. MATCH IT ACTIVITIES
    const matchActs = relevant.filter(a => a.type === 'match' || a.type === 'cloud_match');
    if (matchActs.length > 0) {
      const parsedMatchSets: MatchSet[] = matchActs.map((act, sIdx) => {
        const data = act.data_json || {};
        let pairs: MatchPairItem[] = [];
        if (Array.isArray(data.pairs) && data.pairs.length > 0) {
          pairs = data.pairs.map((p: any, pIdx: number) => ({
            id: p.id ? Number(p.id) : ((act.id || sIdx + 1) * 100 + pIdx + 1),
            leftText: p.left || p.leftText || `Item ${pIdx + 1}`,
            leftHint: p.leftHint || '',
            rightText: p.right || p.rightText || `Match ${pIdx + 1}`,
            rightHint: p.rightHint || (p.rightImage ? 'Image' : '')
          }));
        } else {
          pairs = [
            { id: (act.id || sIdx + 1) * 100 + 1, leftText: 'Hello', rightText: 'வணக்கம்' },
            { id: (act.id || sIdx + 1) * 100 + 2, leftText: 'Thank you', rightText: 'நன்றி' }
          ];
        }

        return {
          id: act.id || (sIdx + 1),
          title: act.title || `Set ${sIdx + 1}: Match Drill`,
          category: data.explanation || 'Vocabulary Match',
          icon: sIdx % 2 === 0 ? 'bi-puzzle-fill' : 'bi-hand-thumbs-up-fill',
          pairs: pairs
        };
      });

      if (parsedMatchSets.length > 0) {
        this.matchSets = parsedMatchSets;
      }
    }

    // 2. FLASHCARD ACTIVITIES
    const flashActs = relevant.filter(a => a.type === 'flashcard');
    if (flashActs.length > 0) {
      const parsedCards: FlashcardItem[] = flashActs.map((act, cIdx) => {
        const d = act.data_json || {};
        return {
          id: act.id || (cIdx + 1),
          front: d.front || act.title,
          frontLanguage: d.frontLanguage || 'Target Term',
          back: d.back || 'Translation',
          backLanguage: d.backLanguage || 'English',
          pronunciation: d.pronunciation || d.audioUrl || '[tap to listen]'
        };
      });

      if (parsedCards.length > 0) {
        this.flashcardDeck = parsedCards;
      }
    }

    // 3. SPEED QUIZ (MCQ) ACTIVITIES
    const mcqActs = relevant.filter(a => a.type === 'mcq');
    if (mcqActs.length > 0) {
      const parsedQuizzes = mcqActs.map((act, qIdx) => {
        const d = act.data_json || {};
        let options: string[] = [];
        let correct = 0;

        if (Array.isArray(d.options) && d.options.length > 0) {
          if (typeof d.options[0] === 'object') {
            options = d.options.map((o: any) => o.text || '');
            const cIdx = d.options.findIndex((o: any) => o.isCorrect);
            correct = cIdx >= 0 ? cIdx : 0;
          } else {
            options = d.options.map(String);
            correct = d.correctIndex !== undefined ? Number(d.correctIndex) : (d.correct !== undefined ? Number(d.correct) : 0);
          }
        } else {
          options = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
        }

        return {
          question: d.question || act.title,
          options: options,
          correct: correct
        };
      });

      if (parsedQuizzes.length > 0) {
        this.quizQuestions = parsedQuizzes;
      }
    }

    // 4. WORD SCRAMBLE (WORD_ARRANGE) ACTIVITIES
    const scrambleActs = relevant.filter(a => a.type === 'word_arrange');
    if (scrambleActs.length > 0) {
      const parsedScramble: WordScrambleItem[] = scrambleActs.map((act, sIdx) => {
        const d = act.data_json || {};
        let words: string[] = [];
        const raw = (d.targetText || d.correctSentence || d.text || '').trim();

        if (Array.isArray(d.sentenceWords) && d.sentenceWords.length > 0) {
          words = [...d.sentenceWords];
        } else if (raw) {
          words = raw.includes('/')
            ? raw.split('/').map((w: string) => w.trim()).filter(Boolean)
            : raw.split(/\s+/).map((w: string) => w.trim()).filter(Boolean);
        } else {
          words = ['Practice', 'daily', 'with', 'LangNest'];
        }

        return {
          id: act.id || (sIdx + 1),
          englishMeaning: d.englishMeaning || d.question || act.title,
          sentenceWords: words,
          correctSentence: raw || words.join(' ')
        };
      });

      if (parsedScramble.length > 0) {
        this.wordScrambleSets = parsedScramble;
      }
    }

    // 5. FILL IN THE BLANKS ACTIVITIES
    const blankActs = relevant.filter(a => a.type === 'fill_blanks');
    if (blankActs.length > 0) {
      const parsedBlanks: BlankQuestionItem[] = blankActs.map((act, bIdx) => {
        const d = act.data_json || {};
        let prompt = d.prompt || '';
        let options: string[] = Array.isArray(d.options) ? [...d.options] : [];
        let correctIndex = d.correctIndex !== undefined ? Number(d.correctIndex) : 0;
        let explanation = d.explanation || act.title;

        // Support bracketed format: "Good [morning|evening] everyone" or "Good [morning]"
        if (!prompt && d.text) {
          const match = d.text.match(/\[(.*?)\]/);
          if (match) {
            prompt = d.text.replace(/\[.*?\]/, '_____');
            const choices = match[1].split('|').map((s: string) => s.trim()).filter(Boolean);
            if (choices.length > 1) {
              options = choices;
              correctIndex = 0;
            } else if (choices.length === 1) {
              options = [choices[0], 'Other', 'Extra', 'None'];
              correctIndex = 0;
            }
          } else {
            prompt = d.text;
          }
        }

        if (options.length === 0) {
          options = ['Correct', 'Alternative 1', 'Alternative 2', 'Alternative 3'];
        }

        return {
          id: act.id || (bIdx + 1),
          prompt: prompt || act.title,
          options: options,
          correctIndex: Math.max(0, Math.min(correctIndex, options.length - 1)),
          explanation: explanation
        };
      });

      if (parsedBlanks.length > 0) {
        this.blankQuestions = parsedBlanks;
      }
    }

    // Dynamic Topic Badges update
    this.practiceTopics = [
      {
        id: 'match',
        title: 'Match It',
        badge: `${this.matchSets.length} Sets Available • +50 XP`,
        description: 'Match words with their translations and meanings across dynamic interactive sets. Fast and engaging vocabulary pairing!',
        icon: 'bi-puzzle-fill',
        color: '#F59E0B',
        countLabel: `${this.matchSets.length} Interactive Sets`
      },
      {
        id: 'flashcards',
        title: 'Interactive Flashcards',
        badge: `${this.flashcardDeck.length} Cards Deck • +30 XP`,
        description: 'Flip 3D memory cards with pronunciation guides and translations to train your memory.',
        icon: 'bi-card-text',
        color: '#3B82F6',
        countLabel: `${this.flashcardDeck.length} Flip Cards`
      },
      {
        id: 'quiz',
        title: 'Speed Quiz Challenge',
        badge: `${this.quizQuestions.length} Drills • +50 XP`,
        description: 'Rapid-fire multiple choice questions. Pick the right answer quickly to earn bonus XP and sharpen recall!',
        icon: 'bi-lightning-charge-fill',
        color: '#10B981',
        countLabel: `${this.quizQuestions.length} MCQ Drills`
      },
      {
        id: 'scramble',
        title: 'Word Scramble',
        badge: `${this.wordScrambleSets.length} Puzzles • +40 XP`,
        description: 'Tap jumbled words in the correct grammatical order to form meaningful everyday sentences.',
        icon: 'bi-sort-alpha-down',
        color: '#8B5CF6',
        countLabel: `${this.wordScrambleSets.length} Word Puzzles`
      },
      {
        id: 'blanks',
        title: 'Fill in the Blanks',
        badge: `${this.blankQuestions.length} Drills • +40 XP`,
        description: 'Select the missing words in essential conversations to master sentence structures and grammar.',
        icon: 'bi-input-cursor-text',
        color: '#EC4899',
        countLabel: `${this.blankQuestions.length} Context Sentences`
      }
    ];
  }

  openPracticeActivity(topic: 'match' | 'flashcards' | 'quiz' | 'scramble' | 'blanks') {
    this.selectedPracticeTopic.set(topic);
    this.practiceStage.set('activity');

    if (this.allDynamicActivities().length > 0) {
      this.processDynamicActivities(this.allDynamicActivities());
    }

    if (topic === 'match') {
      this.initMatchSet(0);
    } else if (topic === 'flashcards') {
      this.flashcardIndex.set(0);
      this.isCardFlipped.set(false);
    } else if (topic === 'quiz') {
      this.quizStep.set(0);
      this.quizAnswered.set(false);
      this.quizFeedback.set(null);
    } else if (topic === 'scramble') {
      this.initScrambleQuestion(0);
    } else if (topic === 'blanks') {
      this.initBlankQuestion(0);
    }
  }

  backToPracticeTopics() {
    this.practiceStage.set('topics');
  }

  getTopicTitle(topicId: string): string {
    switch (topicId) {
      case 'match': return 'Match It (Pair Matching)';
      case 'flashcards': return 'Interactive Flashcards';
      case 'quiz': return 'Speed Quiz Challenge';
      case 'scramble': return 'Word Scramble / Sentence Builder';
      case 'blanks': return 'Fill in the Blanks';
      default: return 'Practice Activity';
    }
  }

  // --- 🧩 5 MATCH IT SETS METHODS ---
  initMatchSet(setIndex: number) {
    const validIndex = Math.max(0, Math.min(setIndex, this.matchSets.length - 1));
    this.currentMatchSetIndex.set(validIndex);
    this.matchedPairIds.set([]);
    this.selectedLeftPair.set(null);
    this.selectedRightPair.set(null);
    this.isSetComplete.set(false);
    this.shakeLeftId.set(null);
    this.shakeRightId.set(null);
    this.matchFeedback.set(null);

    const set = this.matchSets[validIndex];
    if (set && set.pairs) {
      const rights = set.pairs.map(p => ({ id: p.id, text: p.rightText, hint: p.rightHint }));
      // Fisher-Yates shuffle
      for (let i = rights.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [rights[i], rights[j]] = [rights[j], rights[i]];
      }
      this.shuffledRightItems.set(rights);
    }
  }

  selectMatchSetDirect(idx: number) {
    this.initMatchSet(idx);
  }

  selectLeft(pairId: number) {
    if (this.isPairMatched(pairId) || this.isSetComplete()) return;
    this.selectedLeftPair.set(pairId);
    if (this.selectedRightPair() !== null) {
      this.checkMatchPair();
    }
  }

  selectRight(pairId: number) {
    if (this.isPairMatched(pairId) || this.isSetComplete()) return;
    this.selectedRightPair.set(pairId);
    if (this.selectedLeftPair() !== null) {
      this.checkMatchPair();
    }
  }

  isPairMatched(pairId: number): boolean {
    return this.matchedPairIds().includes(pairId);
  }

  checkMatchPair() {
    const left = this.selectedLeftPair();
    const right = this.selectedRightPair();
    if (left === null || right === null) return;

    if (left === right) {
      // MATCH!
      this.matchedPairIds.update(m => [...m, left]);
      this.matchScore.update(s => s + 10);
      this.xp.update(x => x + 10);
      this.matchStreak.update(st => st + 1);
      this.matchFeedback.set('Awesome Match! +10 XP');
      this.audioService.playSuccess();

      this.selectedLeftPair.set(null);
      this.selectedRightPair.set(null);

      const currentSet = this.matchSets[this.currentMatchSetIndex()];
      if (this.matchedPairIds().length === currentSet.pairs.length) {
        this.isSetComplete.set(true);
        confetti({ particleCount: 70, spread: 70, origin: { y: 0.6 } });

        if (this.currentMatchSetIndex() >= this.matchSets.length - 1) {
          this.isAllSetsComplete.set(true);
          confetti({ particleCount: 150, spread: 90, origin: { y: 0.5 } });
        }
      }
    } else {
      // MISMATCH!
      this.shakeLeftId.set(left);
      this.shakeRightId.set(right);
      this.matchStreak.set(0);
      this.matchFeedback.set('Not a match! Try again.');
      this.audioService.playError();

      setTimeout(() => {
        this.shakeLeftId.set(null);
        this.shakeRightId.set(null);
        this.selectedLeftPair.set(null);
        this.selectedRightPair.set(null);
        this.matchFeedback.set(null);
      }, 650);
    }
  }

  nextMatchSet() {
    if (this.currentMatchSetIndex() < this.matchSets.length - 1) {
      this.initMatchSet(this.currentMatchSetIndex() + 1);
    } else {
      this.isAllSetsComplete.set(true);
    }
  }

  restartMatchSets() {
    this.isAllSetsComplete.set(false);
    this.initMatchSet(0);
  }

  // --- 🗂️ FLASHCARD METHODS ---
  toggleFlipCard() {
    this.isCardFlipped.update(v => !v);
  }

  nextFlashcard() {
    this.isCardFlipped.set(false);
    if (this.flashcardIndex() < this.flashcardDeck.length - 1) {
      this.flashcardIndex.update(i => i + 1);
    } else {
      this.flashcardIndex.set(0);
    }
  }

  prevFlashcard() {
    this.isCardFlipped.set(false);
    if (this.flashcardIndex() > 0) {
      this.flashcardIndex.update(i => i - 1);
    } else {
      this.flashcardIndex.set(this.flashcardDeck.length - 1);
    }
  }

  // --- ⚡ SPEED QUIZ METHODS ---
  answerQuiz(optionIndex: number) {
    if (this.quizAnswered()) return;
    this.quizAnswered.set(true);

    const currentQ = this.quizQuestions[this.quizStep()];
    if (optionIndex === currentQ.correct) {
      this.quizScore.update(s => s + 10);
      this.xp.update(x => x + 10);
      this.quizFeedback.set('Correct! +10 XP');
      this.audioService.playSuccess();
      confetti({ particleCount: 50, spread: 60, origin: { y: 0.6 } });
    } else {
      this.audioService.playError();
      this.quizFeedback.set(`Not quite! The correct answer was "${currentQ.options[currentQ.correct]}".`);
    }
  }

  nextQuizQuestion() {
    this.quizAnswered.set(false);
    this.quizFeedback.set(null);
    if (this.quizStep() < this.quizQuestions.length - 1) {
      this.quizStep.update(s => s + 1);
    } else {
      this.quizStep.set(0);
    }
  }

  // --- 🔤 WORD SCRAMBLE METHODS ---
  initScrambleQuestion(idx: number) {
    const validIdx = Math.max(0, Math.min(idx, this.wordScrambleSets.length - 1));
    this.scrambleIndex.set(validIdx);
    this.scrambleSelectedWords.set([]);
    this.scrambleAnswered.set(false);
    this.scrambleIsCorrect.set(false);

    const item = this.wordScrambleSets[validIdx];
    const shuffled = [...item.sentenceWords];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    this.scrambleAvailableWords.set(shuffled);
  }

  selectScrambleWord(word: string, index: number) {
    if (this.scrambleAnswered()) return;
    this.scrambleSelectedWords.update(words => [...words, word]);
    this.scrambleAvailableWords.update(avail => {
      const updated = [...avail];
      updated.splice(index, 1);
      return updated;
    });
  }

  removeScrambleWord(word: string, index: number) {
    if (this.scrambleAnswered()) return;
    this.scrambleSelectedWords.update(words => {
      const updated = [...words];
      updated.splice(index, 1);
      return updated;
    });
    this.scrambleAvailableWords.update(avail => [...avail, word]);
  }

  checkScrambleAnswer() {
    if (this.scrambleAnswered()) return;
    this.scrambleAnswered.set(true);

    const assembled = this.scrambleSelectedWords().join(' ').trim().toLowerCase();
    const correct = this.wordScrambleSets[this.scrambleIndex()].correctSentence.trim().toLowerCase();

    if (assembled === correct) {
      this.scrambleIsCorrect.set(true);
      this.xp.update(x => x + 15);
      this.audioService.playSuccess();
      confetti({ particleCount: 50, spread: 60, origin: { y: 0.6 } });
    } else {
      this.scrambleIsCorrect.set(false);
      this.audioService.playError();
    }
  }

  nextScrambleQuestion() {
    if (this.scrambleIndex() < this.wordScrambleSets.length - 1) {
      this.initScrambleQuestion(this.scrambleIndex() + 1);
    } else {
      this.initScrambleQuestion(0);
    }
  }

  // --- ✍️ FILL IN BLANKS METHODS ---
  initBlankQuestion(idx: number) {
    const validIdx = Math.max(0, Math.min(idx, this.blankQuestions.length - 1));
    this.blankIndex.set(validIdx);
    this.blankAnswered.set(false);
    this.selectedBlankOption.set(null);
    this.blankIsCorrect.set(false);
  }

  selectBlankOption(optIndex: number) {
    if (this.blankAnswered()) return;
    this.blankAnswered.set(true);
    this.selectedBlankOption.set(optIndex);

    const q = this.blankQuestions[this.blankIndex()];
    if (optIndex === q.correctIndex) {
      this.blankIsCorrect.set(true);
      this.xp.update(x => x + 10);
      this.audioService.playSuccess();
      confetti({ particleCount: 50, spread: 60, origin: { y: 0.6 } });
    } else {
      this.blankIsCorrect.set(false);
      this.audioService.playError();
    }
  }

  nextBlankQuestion() {
    if (this.blankIndex() < this.blankQuestions.length - 1) {
      this.initBlankQuestion(this.blankIndex() + 1);
    } else {
      this.initBlankQuestion(0);
    }
  }

  saveSettings() {
    this.settingsSavedNotice.set(true);
    setTimeout(() => {
      this.settingsSavedNotice.set(false);
    }, 3000);
  }

  triggerAchievement() {
    this.showAchievementModal.set(true);
    confetti({
      particleCount: 120,
      spread: 80,
      origin: { y: 0.6 }
    });
  }

  logout() {
    this.authService.logout().subscribe({
      complete: () => {
        window.location.href = '/login';
      },
      error: () => {
        this.authService.clearSession();
        window.location.href = '/login';
      }
    });
  }
}
