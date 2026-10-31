import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, signal } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface WordNinjaData {
  id?: number;
  type?: string;
  title?: string;
  question?: string; // e.g. "Slice only Adjectives!"
  correctWords?: string[]; // words player MUST slice
  wrongWords?: string[]; // words player MUST avoid (or bombs)
  speed?: 'normal' | 'fast' | 'ninja';
  explanation?: string;
}

export type FruitType =
  | 'watermelon'
  | 'orange'
  | 'apple'
  | 'strawberry'
  | 'banana'
  | 'pineapple'
  | 'kiwi'
  | 'coconut'
  | 'bomb';

interface FruitConfig {
  name: string;
  juiceColor: string;
  radius: number;
}

const FRUIT_CONFIGS: Record<FruitType, FruitConfig> = {
  watermelon: { name: 'Watermelon', juiceColor: '#ef4444', radius: 44 },
  orange: { name: 'Orange', juiceColor: '#f97316', radius: 40 },
  apple: { name: 'Apple', juiceColor: '#f43f5e', radius: 39 },
  strawberry: { name: 'Strawberry', juiceColor: '#e11d48', radius: 38 },
  banana: { name: 'Banana', juiceColor: '#eab308', radius: 40 },
  pineapple: { name: 'Pineapple', juiceColor: '#ca8a04', radius: 44 },
  kiwi: { name: 'Kiwi', juiceColor: '#22c55e', radius: 38 },
  coconut: { name: 'Coconut', juiceColor: '#f8fafc', radius: 41 },
  bomb: { name: 'Bomb', juiceColor: '#f59e0b', radius: 38 }
};

const TARGET_FRUIT_TYPES: FruitType[] = [
  'watermelon',
  'orange',
  'apple',
  'strawberry',
  'banana',
  'pineapple',
  'kiwi',
  'coconut'
];

interface SlicedPiece {
  x: number;
  y: number;
  vx: number;
  vy: number;
  rot: number;
  vRot: number;
  text: string;
  side: 'left' | 'right';
  fruitType: FruitType;
  color: string;
  radius: number;
  life: number;
}

interface FloatingWordItem {
  id: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  text: string;
  isCorrect: boolean;
  color: string;
  fruitType: FruitType;
  juiceColor: string;
  sliced: boolean;
  angle: number;
  vRot: number;
  sparkPhase: number;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  color: string;
  radius: number;
  life: number;
  maxLife: number;
  type?: 'juice' | 'spark' | 'smoke';
}

interface BladePoint {
  x: number;
  y: number;
  time: number;
}

interface JuiceStain {
  x: number;
  y: number;
  color: string;
  radius: number;
  opacity: number;
  drips: { x: number; y: number; length: number; width: number }[];
}

@Component({
  selector: 'app-activity-word-ninja',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './word-ninja.html',
  styleUrls: ['./word-ninja.css']
})
export class WordNinjaComponent implements OnInit, OnDestroy {
  @Input() activity: WordNinjaData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{
    isCorrect: boolean;
    score: number;
    accuracy: number;
  }>();

  @ViewChild('ninjaCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;

  // Game Signals
  gameState = signal<'start' | 'playing' | 'gameover' | 'victory'>('start');
  score = signal<number>(0);
  lives = signal<number>(5);
  streak = signal<number>(0);
  targetPrompt = signal<string>('Slice the correct words!');
  soundEnabled = signal<boolean>(true);
  Math = Math;

  // Audio Context (Synth - zero external mp3 files)
  private audioCtx: AudioContext | null = null;

  // Animation & Loop
  private animFrameId: number | null = null;
  private lastTime: number = 0;
  private spawnTimer: number = 0;
  private spawnInterval: number = 1.6; // launch wave every 1.6s
  private screenShakeTimer: number = 0;

  // Slicing Trail
  private isPointerDown: boolean = false;
  private bladeTrail: BladePoint[] = [];

  // Active game entities
  private floatingItems: FloatingWordItem[] = [];
  private slicedPieces: SlicedPiece[] = [];
  private particles: Particle[] = [];
  private wallStains: JuiceStain[] = [];
  private itemIdCounter: number = 0;

  // Words bank
  private correctBank: string[] = [];
  private wrongBank: string[] = [];
  private targetSlicesNeeded: number = 10;
  slicedCorrectCount: number = 0;
  slicedWrongCount: number = 0;

  ngOnInit() {
    this.parseData();
    this.initCanvas();
  }

  ngOnDestroy() {
    this.stopLoop();
    if (this.audioCtx) {
      try { this.audioCtx.close(); } catch (e) {}
    }
  }

  private initAudio() {
    if (!this.audioCtx) {
      const AudioClass = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioClass) this.audioCtx = new AudioClass();
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  playSynthSound(type: 'swish' | 'slice' | 'bomb' | 'win') {
    if (!this.soundEnabled()) return;
    this.initAudio();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    try {
      if (type === 'swish') {
        // Fast katana blade whoosh
        const osc = ctx.createOscillator();
        const filter = ctx.createBiquadFilter();
        const gain = ctx.createGain();

        osc.type = 'triangle';
        osc.frequency.setValueAtTime(2200, now);
        osc.frequency.exponentialRampToValueAtTime(280, now + 0.11);

        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(1800, now);
        filter.frequency.exponentialRampToValueAtTime(500, now + 0.11);
        filter.Q.value = 3.0;

        gain.gain.setValueAtTime(0.01, now);
        gain.gain.linearRampToValueAtTime(0.25, now + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.11);

        osc.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);

        osc.start(now);
        osc.stop(now + 0.11);
      } else if (type === 'slice') {
        // Sharp katana fruit cut: impact + blade slice ring
        const osc1 = ctx.createOscillator();
        const osc2 = ctx.createOscillator();
        const filter = ctx.createBiquadFilter();
        const gain = ctx.createGain();

        osc1.type = 'sawtooth';
        osc1.frequency.setValueAtTime(2800, now);
        osc1.frequency.exponentialRampToValueAtTime(320, now + 0.13);

        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(1400, now);
        osc2.frequency.exponentialRampToValueAtTime(440, now + 0.13);

        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(2000, now);
        filter.Q.value = 2.5;

        gain.gain.setValueAtTime(0.01, now);
        gain.gain.linearRampToValueAtTime(0.35, now + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.13);

        osc1.connect(filter);
        osc2.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);

        osc1.start(now);
        osc2.start(now);
        osc1.stop(now + 0.13);
        osc2.stop(now + 0.13);
      } else if (type === 'bomb') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(120, now);
        osc.frequency.exponentialRampToValueAtTime(25, now + 0.4);
        gain.gain.setValueAtTime(0.35, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.4);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.4);
      } else if (type === 'win') {
        [523, 659, 784, 1046].forEach((f, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(f, now + idx * 0.08);
          gain.gain.setValueAtTime(0.18, now + idx * 0.08);
          gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.08 + 0.3);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + idx * 0.08);
          osc.stop(now + idx * 0.08 + 0.3);
        });
      }
    } catch (e) {}
  }

  private parseData() {
    const act = this.activity;
    this.targetPrompt.set(act?.question || act?.title || 'Slice the correct target words!');

    if (act?.correctWords && act.correctWords.length > 0) {
      this.correctBank = [...act.correctWords];
    } else {
      this.correctBank = ['Brave', 'Gentle', 'Bright', 'Honest', 'Swift', 'Happy', 'Clever'];
    }

    if (act?.wrongWords && act.wrongWords.length > 0) {
      this.wrongBank = [...act.wrongWords];
    } else {
      this.wrongBank = ['Run', 'Eat', 'Quickly', 'Table', 'Sleep', 'Loudly', 'Jump'];
    }

    if (act?.speed === 'fast') this.spawnInterval = 1.3;
    else if (act?.speed === 'ninja') this.spawnInterval = 0.95;
    else this.spawnInterval = 1.6;

    this.targetSlicesNeeded = Math.min(10, this.correctBank.length * 2);
  }

  private initCanvas() {
    const canvas = this.canvasRef.nativeElement;
    canvas.width = 440;
    canvas.height = 580;
    this.drawStartBanner();
  }

  startGame() {
    this.initAudio();
    this.gameState.set('playing');
    this.score.set(0);
    this.lives.set(5);
    this.streak.set(0);
    this.slicedCorrectCount = 0;
    this.slicedWrongCount = 0;
    this.floatingItems = [];
    this.slicedPieces = [];
    this.particles = [];
    this.wallStains = [];
    this.bladeTrail = [];
    this.screenShakeTimer = 0;
    this.spawnTimer = 0.5;
    this.startLoop();
  }

  restartGame() {
    this.startGame();
  }

  toggleSound() {
    this.soundEnabled.update(s => !s);
  }

  // --- CONTROLS: POINTER EVENTS ---
  onPointerDown(e: PointerEvent) {
    if (this.gameState() !== 'playing') return;
    this.isPointerDown = true;
    const pt = this.getCanvasPoint(e);
    this.bladeTrail = [{ x: pt.x, y: pt.y, time: performance.now() }];
    this.playSynthSound('swish');
  }

  onPointerMove(e: PointerEvent) {
    if (!this.isPointerDown || this.gameState() !== 'playing') return;
    const pt = this.getCanvasPoint(e);
    const now = performance.now();
    this.bladeTrail.push({ x: pt.x, y: pt.y, time: now });

    if (this.bladeTrail.length >= 2) {
      const p1 = this.bladeTrail[this.bladeTrail.length - 2];
      const p2 = this.bladeTrail[this.bladeTrail.length - 1];
      this.checkSliceCollisions(p1, p2);
    }
  }

  onPointerUp(e?: any) {
    this.isPointerDown = false;
  }

  private getCanvasPoint(e: PointerEvent): { x: number; y: number } {
    const canvas = this.canvasRef.nativeElement;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY
    };
  }

  // --- SLICE DETECTION ---
  private checkSliceCollisions(p1: BladePoint, p2: BladePoint) {
    for (const item of this.floatingItems) {
      if (item.sliced) continue;

      const dist = this.distToSegment({ x: item.x, y: item.y }, p1, p2);
      if (dist < item.radius + 10) {
        this.sliceItem(item);
      }
    }
  }

  private distToSegment(p: { x: number; y: number }, v: BladePoint, w: BladePoint): number {
    const l2 = (v.x - w.x) * (v.x - w.x) + (v.y - w.y) * (v.y - w.y);
    if (l2 === 0) return Math.hypot(p.x - v.x, p.y - v.y);
    let t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
    t = Math.max(0, Math.min(1, t));
    const projX = v.x + t * (w.x - v.x);
    const projY = v.y + t * (w.y - v.y);
    return Math.hypot(p.x - projX, p.y - projY);
  }

  private sliceItem(item: FloatingWordItem) {
    item.sliced = true;

    if (item.isCorrect) {
      // Correct slice!
      this.slicedCorrectCount++;
      const bonus = 100 + this.streak() * 20;
      this.score.update(s => s + bonus);
      this.streak.update(st => st + 1);
      this.playSynthSound('slice');

      this.createSlicePieces(item);
      this.addJuiceSplatter(item.x, item.y, item.juiceColor, 35, item.fruitType);

      if (this.slicedCorrectCount >= this.targetSlicesNeeded) {
        setTimeout(() => this.triggerVictory(), 400);
      }
    } else {
      // Wrong slice (Distractor or Bomb)
      this.slicedWrongCount++;
      this.streak.set(0);
      this.lives.update(l => Math.max(0, l - 1));

      if (item.fruitType === 'bomb') {
        this.playSynthSound('bomb');
        this.screenShakeTimer = 0.28;
        this.addBombExplosion(item.x, item.y);
        this.createSlicePieces(item);
      } else {
        this.playSynthSound('bomb');
        this.createSlicePieces(item);
        this.addJuiceSplatter(item.x, item.y, '#ef4444', 35, item.fruitType);
      }

      if (this.lives() <= 0) {
        setTimeout(() => this.triggerGameOver(), 450);
      }
    }
  }

  private createSlicePieces(item: FloatingWordItem) {
    const leftText = item.text.slice(0, Math.ceil(item.text.length / 2));
    const rightText = item.text.slice(Math.ceil(item.text.length / 2));

    this.slicedPieces.push({
      x: item.x - 14,
      y: item.y,
      vx: item.vx - 70,
      vy: item.vy - 40,
      rot: item.angle,
      vRot: -3.5,
      text: leftText,
      side: 'left',
      fruitType: item.fruitType,
      color: item.color,
      radius: item.radius,
      life: 1.3
    });

    this.slicedPieces.push({
      x: item.x + 14,
      y: item.y,
      vx: item.vx + 70,
      vy: item.vy - 40,
      rot: item.angle,
      vRot: 3.5,
      text: rightText,
      side: 'right',
      fruitType: item.fruitType,
      color: item.color,
      radius: item.radius,
      life: 1.3
    });
  }

  private addJuiceSplatter(x: number, y: number, color: string, count: number, fruitType: FruitType) {
    // 1. Splash droplets flying in 360
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 70 + Math.random() * 240;
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        color: color,
        radius: 3 + Math.random() * 4.5,
        life: 0.5 + Math.random() * 0.35,
        maxLife: 0.85,
        type: 'juice'
      });
    }

    // 2. Wall juice splatter stain on the dojo wood wall
    if (this.wallStains.length >= 8) {
      this.wallStains.shift();
    }
    const drips = [];
    const dripCount = 2 + Math.floor(Math.random() * 3);
    for (let d = 0; d < dripCount; d++) {
      drips.push({
        x: (Math.random() - 0.5) * 32,
        y: 6 + Math.random() * 8,
        length: 16 + Math.random() * 35,
        width: 2 + Math.random() * 2.5
      });
    }
    this.wallStains.push({
      x: x,
      y: y,
      color: color,
      radius: 22 + Math.random() * 16,
      opacity: 0.82,
      drips: drips
    });
  }

  private addBombExplosion(x: number, y: number) {
    // Fiery blast particles
    for (let i = 0; i < 45; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 90 + Math.random() * 320;
      const colors = ['#f59e0b', '#ef4444', '#fbbf24', '#ffffff', '#475569'];
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        color: colors[Math.floor(Math.random() * colors.length)],
        radius: 3.5 + Math.random() * 6,
        life: 0.6 + Math.random() * 0.4,
        maxLife: 1.0,
        type: 'spark'
      });
    }

    // Smoke clouds
    for (let s = 0; s < 12; s++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 20 + Math.random() * 70;
      this.particles.push({
        x: x + (Math.random() - 0.5) * 20,
        y: y + (Math.random() - 0.5) * 20,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 30,
        color: 'rgba(51, 65, 85, 0.6)',
        radius: 14 + Math.random() * 16,
        life: 0.8 + Math.random() * 0.4,
        maxLife: 1.2,
        type: 'smoke'
      });
    }
  }

  // --- GAME LOOP ---
  private startLoop() {
    this.stopLoop();
    this.lastTime = performance.now();
    const loop = (timestamp: number) => {
      const dt = Math.min((timestamp - this.lastTime) / 1000, 0.1);
      this.lastTime = timestamp;

      this.update(dt);
      this.render();

      if (this.gameState() === 'playing') {
        this.animFrameId = requestAnimationFrame(loop);
      }
    };
    this.animFrameId = requestAnimationFrame(loop);
  }

  private stopLoop() {
    if (this.animFrameId !== null) {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
  }

  private update(dt: number) {
    const gravity = 480;

    // Prune old blade trail
    const now = performance.now();
    this.bladeTrail = this.bladeTrail.filter(pt => now - pt.time < 160);

    // Screen shake update
    if (this.screenShakeTimer > 0) {
      this.screenShakeTimer = Math.max(0, this.screenShakeTimer - dt);
    }

    // Spawn waves
    this.spawnTimer -= dt;
    if (this.spawnTimer <= 0) {
      this.spawnTimer = this.spawnInterval;
      this.launchWave();
    }

    // Update Floating Items
    for (let i = this.floatingItems.length - 1; i >= 0; i--) {
      const item = this.floatingItems[i];
      item.x += item.vx * dt;
      item.y += item.vy * dt;
      item.vy += gravity * dt;
      item.angle += item.vRot * dt;
      item.sparkPhase += dt * 15;

      // Drop off bottom of screen
      if (item.y > this.canvasRef.nativeElement.height + 80) {
        if (item.isCorrect && !item.sliced) {
          this.lives.update(l => Math.max(0, l - 1));
          this.streak.set(0);
          if (this.lives() <= 0) {
            this.triggerGameOver();
            return;
          }
        }
        this.floatingItems.splice(i, 1);
      }
    }

    // Update Sliced Pieces
    for (let i = this.slicedPieces.length - 1; i >= 0; i--) {
      const piece = this.slicedPieces[i];
      piece.x += piece.vx * dt;
      piece.y += piece.vy * dt;
      piece.vy += gravity * dt;
      piece.rot += piece.vRot * dt;
      piece.life -= dt;
      if (piece.life <= 0) this.slicedPieces.splice(i, 1);
    }

    // Update Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.type === 'juice') {
        p.vy += gravity * 0.45 * dt;
      } else if (p.type === 'smoke') {
        p.radius += dt * 8;
      }
      p.life -= dt;
      if (p.life <= 0) this.particles.splice(i, 1);
    }

    // Update Wall Stains (fade gradually)
    for (let i = this.wallStains.length - 1; i >= 0; i--) {
      const s = this.wallStains[i];
      s.opacity -= dt * 0.04;
      if (s.opacity <= 0) this.wallStains.splice(i, 1);
    }
  }

  private launchWave() {
    const canvas = this.canvasRef.nativeElement;
    const count = Math.random() < 0.6 ? 2 : 3;

    for (let i = 0; i < count; i++) {
      const isCorrect = Math.random() < 0.65 || (this.correctBank.length > 0 && Math.random() < 0.45);
      const text = isCorrect
        ? this.correctBank[Math.floor(Math.random() * this.correctBank.length)]
        : this.wrongBank[Math.floor(Math.random() * this.wrongBank.length)];

      const spawnX = 60 + Math.random() * (canvas.width - 120);
      const spawnY = canvas.height + 30;

      const targetCenterX = canvas.width / 2;
      const vx = (targetCenterX - spawnX) * (0.6 + Math.random() * 0.4) + (Math.random() - 0.5) * 45;
      const vy = -(540 + Math.random() * 80);

      // Determine Fruit Type:
      // Correct words are always luscious original fruits!
      // Wrong words are either hazardous Bombs or distractor fruits!
      let fruitType: FruitType;
      if (isCorrect) {
        fruitType = TARGET_FRUIT_TYPES[Math.floor(Math.random() * TARGET_FRUIT_TYPES.length)];
      } else {
        fruitType = Math.random() < 0.45
          ? 'bomb'
          : TARGET_FRUIT_TYPES[Math.floor(Math.random() * TARGET_FRUIT_TYPES.length)];
      }

      const config = FRUIT_CONFIGS[fruitType];

      this.floatingItems.push({
        id: ++this.itemIdCounter,
        x: spawnX,
        y: spawnY,
        vx: vx,
        vy: vy,
        radius: config.radius,
        text: text,
        isCorrect: isCorrect,
        color: config.juiceColor,
        fruitType: fruitType,
        juiceColor: config.juiceColor,
        sliced: false,
        angle: (Math.random() - 0.5) * 0.4,
        vRot: (Math.random() - 0.5) * 1.6,
        sparkPhase: Math.random() * 10
      });
    }
  }

  private triggerVictory() {
    this.gameState.set('victory');
    this.stopLoop();
    this.playSynthSound('win');
    this.emitResult(true);
  }

  private triggerGameOver() {
    this.gameState.set('gameover');
    this.stopLoop();
    this.emitResult(false);
  }

  private emitResult(won: boolean) {
    const total = this.slicedCorrectCount + this.slicedWrongCount;
    const accuracy = total > 0 ? Math.round((this.slicedCorrectCount / total) * 100) : 0;
    this.answered.emit({
      isCorrect: won,
      score: this.score(),
      accuracy: accuracy
    });
  }

  // ==========================================
  // --- CANVAS RENDERER ---
  // ==========================================
  private render() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.save();

    // Screen Shake effect
    if (this.screenShakeTimer > 0) {
      const shakeAmt = (this.screenShakeTimer / 0.28) * 8;
      ctx.translate((Math.random() - 0.5) * shakeAmt, (Math.random() - 0.5) * shakeAmt);
    }

    // 1. Classic Dojo Wooden Plank Background
    this.drawDojoBackground(ctx, canvas.width, canvas.height);

    // 2. Wall Juice Stains (Fruit Splatters on wood)
    this.drawWallStains(ctx);

    // 3. Particles (Juice Droplets, Sparks & Smoke)
    this.drawParticles(ctx);

    // 4. Floating Unsliced Whole Fruits
    this.floatingItems.forEach(item => {
      if (item.sliced) return;
      this.drawFruitItem(ctx, item);
    });

    // 5. Sliced Fruit Pieces (Two Halves Falling Apart)
    this.slicedPieces.forEach(piece => {
      this.drawSlicedPiece(ctx, piece);
    });

    // 6. Glowing Katana Blade Trail
    this.drawBladeTrail(ctx);

    ctx.restore();
  }

  // --- DOJO WOODEN BACKGROUND ---
  private drawDojoBackground(ctx: CanvasRenderingContext2D, width: number, height: number) {
    // Rich dark mahogany wood gradient
    const bgGrad = ctx.createRadialGradient(width / 2, height / 2, 40, width / 2, height / 2, 380);
    bgGrad.addColorStop(0, '#2e190e');
    bgGrad.addColorStop(0.7, '#1b0d06');
    bgGrad.addColorStop(1, '#0e0603');
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, width, height);

    // Horizontal wooden plank seams
    const plankHeight = 65;
    ctx.lineWidth = 2;
    for (let y = plankHeight; y < height; y += plankHeight) {
      // Dark groove
      ctx.strokeStyle = 'rgba(0, 0, 0, 0.45)';
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();

      // Top wood edge highlight
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
      ctx.beginPath();
      ctx.moveTo(0, y + 1);
      ctx.lineTo(width, y + 1);
      ctx.stroke();

      // Wooden pegs/nails
      ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
      ctx.beginPath();
      ctx.arc(28, y - plankHeight / 2, 3, 0, Math.PI * 2);
      ctx.arc(width - 28, y - plankHeight / 2, 3, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // --- WALL JUICE STAINS ---
  private drawWallStains(ctx: CanvasRenderingContext2D) {
    this.wallStains.forEach(stain => {
      ctx.save();
      ctx.globalAlpha = Math.max(0, stain.opacity);
      ctx.fillStyle = stain.color;

      // Central juice puddle blob
      ctx.beginPath();
      ctx.ellipse(stain.x, stain.y, stain.radius, stain.radius * 0.75, 0, 0, Math.PI * 2);
      ctx.fill();

      // Splatter lobes around center
      for (let i = 0; i < 5; i++) {
        const ang = (i * Math.PI * 2) / 5 + 0.3;
        const dist = stain.radius * (0.8 + (i % 2) * 0.35);
        ctx.beginPath();
        ctx.arc(stain.x + Math.cos(ang) * dist, stain.y + Math.sin(ang) * dist * 0.7, stain.radius * 0.3, 0, Math.PI * 2);
        ctx.fill();
      }

      // Trickling drips down the wall
      stain.drips.forEach(d => {
        ctx.beginPath();
        ctx.roundRect(stain.x + d.x, stain.y + d.y, d.width, d.length, d.width / 2);
        ctx.fill();

        // Droplet at drip tip
        ctx.beginPath();
        ctx.arc(stain.x + d.x + d.width / 2, stain.y + d.y + d.length + 1, d.width * 1.1, 0, Math.PI * 2);
        ctx.fill();
      });

      ctx.restore();
    });
  }

  // --- PARTICLES ---
  private drawParticles(ctx: CanvasRenderingContext2D) {
    this.particles.forEach(p => {
      ctx.save();
      const alpha = Math.max(0, p.life / p.maxLife);
      ctx.globalAlpha = alpha;

      if (p.type === 'smoke') {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();
      } else if (p.type === 'spark') {
        ctx.fillStyle = p.color;
        ctx.shadowColor = p.color;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();
      } else {
        // Juicy droplet with shine
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        ctx.beginPath();
        ctx.arc(p.x - p.radius * 0.3, p.y - p.radius * 0.3, p.radius * 0.35, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore();
    });
  }

  // ==========================================
  // --- ORIGINAL FRUIT DRAWING ROUTINES ---
  // ==========================================
  private drawFruitItem(ctx: CanvasRenderingContext2D, item: FloatingWordItem) {
    ctx.save();
    ctx.translate(item.x, item.y);
    ctx.rotate(item.angle);

    const r = item.radius;

    // 1. Soft 3D drop shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.4)';
    ctx.beginPath();
    ctx.ellipse(0, r + 8, r * 0.9, 10, 0, 0, Math.PI * 2);
    ctx.fill();

    // 2. Draw Specific Authentic Fruit Body
    switch (item.fruitType) {
      case 'watermelon':
        this.drawWatermelonWhole(ctx, r);
        break;
      case 'orange':
        this.drawOrangeWhole(ctx, r);
        break;
      case 'apple':
        this.drawAppleWhole(ctx, r);
        break;
      case 'strawberry':
        this.drawStrawberryWhole(ctx, r);
        break;
      case 'banana':
        this.drawBananaWhole(ctx, r);
        break;
      case 'pineapple':
        this.drawPineappleWhole(ctx, r);
        break;
      case 'kiwi':
        this.drawKiwiWhole(ctx, r);
        break;
      case 'coconut':
        this.drawCoconutWhole(ctx, r);
        break;
      case 'bomb':
        this.drawBombWhole(ctx, r, item.sparkPhase);
        break;
    }

    // 3. Ninja Wooden Banner / Label across the fruit
    this.drawFruitWordBanner(ctx, item.text, r, item.fruitType === 'bomb', item.isCorrect);

    ctx.restore();
  }

  // --- 1. WATERMELON ---
  private drawWatermelonWhole(ctx: CanvasRenderingContext2D, r: number) {
    // Green striped watermelon body
    const grad = ctx.createRadialGradient(-r * 0.3, -r * 0.3, 4, 0, 0, r);
    grad.addColorStop(0, '#22c55e');
    grad.addColorStop(0.5, '#16a34a');
    grad.addColorStop(1, '#14532d');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, Math.PI * 2);
    ctx.fill();

    // Characteristic wavy dark green stripes
    ctx.strokeStyle = '#052e16';
    ctx.lineWidth = 5;
    ctx.lineCap = 'round';
    for (let xOffset of [-r * 0.65, -r * 0.3, 0, r * 0.3, r * 0.65]) {
      ctx.beginPath();
      ctx.moveTo(xOffset, -r * 0.85);
      ctx.bezierCurveTo(xOffset - 7, -r * 0.3, xOffset + 7, r * 0.3, xOffset, r * 0.85);
      ctx.stroke();
    }

    // Stem at top
    ctx.strokeStyle = '#78350f';
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.moveTo(0, -r);
    ctx.quadraticCurveTo(8, -r - 12, 14, -r - 10);
    ctx.stroke();

    // Curly green tendril
    ctx.strokeStyle = '#4ade80';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(0, -r);
    ctx.quadraticCurveTo(-10, -r - 10, -6, -r - 14);
    ctx.stroke();

    // Glossy light reflection
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.75, -Math.PI * 0.75, -Math.PI * 0.45);
    ctx.stroke();
  }

  // --- 2. ORANGE ---
  private drawOrangeWhole(ctx: CanvasRenderingContext2D, r: number) {
    const grad = ctx.createRadialGradient(-r * 0.3, -r * 0.3, 4, 0, 0, r);
    grad.addColorStop(0, '#fed7aa');
    grad.addColorStop(0.3, '#fb923c');
    grad.addColorStop(0.8, '#ea580c');
    grad.addColorStop(1, '#9a3412');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, Math.PI * 2);
    ctx.fill();

    // Dimpled citrus skin texture
    ctx.fillStyle = 'rgba(154, 52, 18, 0.35)';
    for (let i = 0; i < 20; i++) {
      const ang = i * 1.4;
      const dist = (i % 5 + 1) * (r * 0.16);
      ctx.fillRect(Math.cos(ang) * dist, Math.sin(ang) * dist, 1.5, 1.5);
    }

    // Top brown stem
    ctx.fillStyle = '#78350f';
    ctx.fillRect(-2.5, -r - 5, 5, 6);

    // Fresh green leaf
    ctx.save();
    ctx.translate(2, -r - 3);
    ctx.rotate(0.35);
    ctx.fillStyle = '#16a34a';
    ctx.beginPath();
    ctx.ellipse(10, 0, 11, 5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#86efac';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(20, 0);
    ctx.stroke();
    ctx.restore();

    // Gloss
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.45)';
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.75, -Math.PI * 0.78, -Math.PI * 0.48);
    ctx.stroke();
  }

  // --- 3. RED APPLE ---
  private drawAppleWhole(ctx: CanvasRenderingContext2D, r: number) {
    const grad = ctx.createRadialGradient(-r * 0.25, -r * 0.25, 4, 0, 0, r);
    grad.addColorStop(0, '#fca5a5');
    grad.addColorStop(0.3, '#ef4444');
    grad.addColorStop(0.85, '#dc2626');
    grad.addColorStop(1, '#7f1d1d');

    ctx.fillStyle = grad;

    // Apple contour with top and bottom clefts
    ctx.beginPath();
    ctx.moveTo(0, -r * 0.7);
    ctx.bezierCurveTo(r * 0.65, -r * 1.05, r * 1.15, -r * 0.3, r * 0.95, r * 0.4);
    ctx.bezierCurveTo(r * 0.75, r * 1.05, r * 0.2, r * 1.05, 0, r * 0.85);
    ctx.bezierCurveTo(-r * 0.2, r * 1.05, -r * 0.75, r * 1.05, -r * 0.95, r * 0.4);
    ctx.bezierCurveTo(-r * 1.15, -r * 0.3, -r * 0.65, -r * 1.05, 0, -r * 0.7);
    ctx.fill();

    // Apple Stem
    ctx.strokeStyle = '#59371d';
    ctx.lineWidth = 3.5;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(0, -r * 0.65);
    ctx.quadraticCurveTo(6, -r * 1.05, 10, -r * 1.15);
    ctx.stroke();

    // Leaf
    ctx.save();
    ctx.translate(4, -r * 0.85);
    ctx.rotate(-0.5);
    ctx.fillStyle = '#22c55e';
    ctx.beginPath();
    ctx.ellipse(8, 0, 9, 4.5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    // Gloss
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.45)';
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.arc(-r * 0.25, -r * 0.15, r * 0.55, -Math.PI * 0.8, -Math.PI * 0.45);
    ctx.stroke();
  }

  // --- 4. STRAWBERRY ---
  private drawStrawberryWhole(ctx: CanvasRenderingContext2D, r: number) {
    const grad = ctx.createRadialGradient(-r * 0.2, -r * 0.2, 4, 0, 0, r);
    grad.addColorStop(0, '#fda4af');
    grad.addColorStop(0.3, '#f43f5e');
    grad.addColorStop(0.85, '#e11d48');
    grad.addColorStop(1, '#881337');

    ctx.fillStyle = grad;

    // Conical strawberry berry shape
    ctx.beginPath();
    ctx.moveTo(0, -r * 0.7);
    ctx.bezierCurveTo(r * 0.8, -r * 0.7, r * 1.0, 0, 0, r * 1.05);
    ctx.bezierCurveTo(-r * 1.0, 0, -r * 0.8, -r * 0.7, 0, -r * 0.7);
    ctx.fill();

    // Golden seed speckles (achenes)
    ctx.fillStyle = '#fef08a';
    const seeds = [
      { x: 0, y: -r * 0.4 },
      { x: -r * 0.35, y: -r * 0.35 },
      { x: r * 0.35, y: -r * 0.35 },
      { x: -r * 0.5, y: -r * 0.05 },
      { x: 0, y: -r * 0.05 },
      { x: r * 0.5, y: -r * 0.05 },
      { x: -r * 0.35, y: r * 0.25 },
      { x: r * 0.35, y: r * 0.25 },
      { x: 0, y: r * 0.3 },
      { x: -r * 0.18, y: r * 0.55 },
      { x: r * 0.18, y: r * 0.55 },
      { x: 0, y: r * 0.75 }
    ];
    seeds.forEach(s => {
      ctx.beginPath();
      ctx.ellipse(s.x, s.y, 1.8, 2.5, 0.2, 0, Math.PI * 2);
      ctx.fill();
    });

    // Green leafy crown (calyx)
    ctx.fillStyle = '#16a34a';
    for (let a of [-0.9, -0.45, 0, 0.45, 0.9]) {
      ctx.save();
      ctx.translate(0, -r * 0.65);
      ctx.rotate(a);
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(4, -14);
      ctx.lineTo(-4, -14);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    }
  }

  // --- 5. BANANA ---
  private drawBananaWhole(ctx: CanvasRenderingContext2D, r: number) {
    ctx.save();
    ctx.rotate(0.2);

    // Curved banana body
    const grad = ctx.createLinearGradient(-r * 0.8, -r * 0.8, r * 0.8, r * 0.8);
    grad.addColorStop(0, '#fef08a');
    grad.addColorStop(0.4, '#facc15');
    grad.addColorStop(0.85, '#eab308');
    grad.addColorStop(1, '#ca8a04');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.moveTo(-r * 0.85, -r * 0.65);
    ctx.bezierCurveTo(-r * 0.4, -r * 0.1, -r * 0.2, r * 0.5, r * 0.85, r * 0.75);
    ctx.bezierCurveTo(r * 0.2, r * 0.7, -r * 0.2, r * 0.1, -r * 0.85, -r * 0.65);
    ctx.fill();

    // Central banana ridge facet line
    ctx.strokeStyle = '#ca8a04';
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.moveTo(-r * 0.85, -r * 0.65);
    ctx.bezierCurveTo(-r * 0.3, -r * 0.05, -r * 0.1, r * 0.4, r * 0.85, r * 0.75);
    ctx.stroke();

    // Green-brown stem at top
    ctx.fillStyle = '#4d7c0f';
    ctx.beginPath();
    ctx.ellipse(-r * 0.85, -r * 0.65, 5, 4, 0.5, 0, Math.PI * 2);
    ctx.fill();

    // Dark blossom tip at bottom
    ctx.fillStyle = '#451a03';
    ctx.beginPath();
    ctx.ellipse(r * 0.85, r * 0.75, 4, 3, 0.3, 0, Math.PI * 2);
    ctx.fill();

    ctx.restore();
  }

  // --- 6. PINEAPPLE ---
  private drawPineappleWhole(ctx: CanvasRenderingContext2D, r: number) {
    // Spiky green crown leaves on top
    ctx.fillStyle = '#15803d';
    for (let ang of [-0.6, -0.3, 0, 0.3, 0.6]) {
      ctx.save();
      ctx.translate(0, -r * 0.45);
      ctx.rotate(ang);
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(6, -26);
      ctx.lineTo(0, -32);
      ctx.lineTo(-6, -26);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    }

    // Oval golden-amber fruit body
    const grad = ctx.createRadialGradient(-r * 0.2, 0, 4, 0, r * 0.15, r * 0.85);
    grad.addColorStop(0, '#fef08a');
    grad.addColorStop(0.3, '#facc15');
    grad.addColorStop(0.7, '#ca8a04');
    grad.addColorStop(1, '#78350f');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.ellipse(0, r * 0.2, r * 0.75, r * 0.85, 0, 0, Math.PI * 2);
    ctx.fill();

    // Diamond crosshatch scale mesh
    ctx.strokeStyle = '#78350f';
    ctx.lineWidth = 1.8;
    ctx.save();
    ctx.beginPath();
    ctx.ellipse(0, r * 0.2, r * 0.75, r * 0.85, 0, 0, Math.PI * 2);
    ctx.clip();

    for (let d = -r; d <= r; d += 14) {
      ctx.beginPath();
      ctx.moveTo(-r, d - r * 0.5);
      ctx.lineTo(r, d + r * 1.5);
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(r, d - r * 0.5);
      ctx.lineTo(-r, d + r * 1.5);
      ctx.stroke();
    }
    ctx.restore();
  }

  // --- 7. KIWI ---
  private drawKiwiWhole(ctx: CanvasRenderingContext2D, r: number) {
    const grad = ctx.createRadialGradient(-r * 0.3, -r * 0.3, 4, 0, 0, r);
    grad.addColorStop(0, '#b45309');
    grad.addColorStop(0.5, '#78350f');
    grad.addColorStop(1, '#451a03');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.ellipse(0, 0, r * 0.85, r, 0, 0, Math.PI * 2);
    ctx.fill();

    // Fuzzy hairy stippling
    ctx.fillStyle = 'rgba(254, 240, 138, 0.25)';
    for (let i = 0; i < 28; i++) {
      const ang = i * 0.7;
      const dist = (i % 6 + 1) * (r * 0.13);
      ctx.fillRect(Math.cos(ang) * dist * 0.8, Math.sin(ang) * dist, 1.5, 2.5);
    }
  }

  // --- 8. COCONUT ---
  private drawCoconutWhole(ctx: CanvasRenderingContext2D, r: number) {
    const grad = ctx.createRadialGradient(-r * 0.3, -r * 0.3, 4, 0, 0, r);
    grad.addColorStop(0, '#78350f');
    grad.addColorStop(0.6, '#451a03');
    grad.addColorStop(1, '#270e02');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, Math.PI * 2);
    ctx.fill();

    // Fibrous shell texture stripes
    ctx.strokeStyle = 'rgba(217, 119, 6, 0.25)';
    ctx.lineWidth = 1.5;
    for (let a = 0; a < Math.PI * 2; a += 0.45) {
      ctx.beginPath();
      ctx.moveTo(Math.cos(a) * r * 0.4, Math.sin(a) * r * 0.4);
      ctx.lineTo(Math.cos(a) * r * 0.9, Math.sin(a) * r * 0.9);
      ctx.stroke();
    }

    // Three characteristic dark germination eyes
    ctx.fillStyle = '#1c0a02';
    ctx.beginPath();
    ctx.arc(-8, -r * 0.4, 4, 0, Math.PI * 2);
    ctx.arc(8, -r * 0.4, 4, 0, Math.PI * 2);
    ctx.arc(0, -r * 0.22, 4.5, 0, Math.PI * 2);
    ctx.fill();
  }

  // --- 9. CLASSIC NINJA BOMB (WITH BURNING SPARK FUSE) ---
  private drawBombWhole(ctx: CanvasRenderingContext2D, r: number, sparkPhase: number) {
    // Cast-iron metallic sphere
    const grad = ctx.createRadialGradient(-r * 0.35, -r * 0.35, 3, 0, 0, r);
    grad.addColorStop(0, '#94a3b8');
    grad.addColorStop(0.25, '#334155');
    grad.addColorStop(0.7, '#1e293b');
    grad.addColorStop(1, '#020617');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, Math.PI * 2);
    ctx.fill();

    // Metallic rim highlight
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.35)';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.8, -Math.PI * 0.78, -Math.PI * 0.45);
    ctx.stroke();

    // Brass bomb collar
    ctx.fillStyle = '#b45309';
    ctx.fillRect(-7, -r - 5, 14, 6);

    // Twisted rope fuse
    ctx.strokeStyle = '#78350f';
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.moveTo(0, -r - 5);
    ctx.quadraticCurveTo(12, -r - 18, 18, -r - 24);
    ctx.stroke();

    // Animated glowing spark at fuse tip!
    const sparkTipX = 18;
    const sparkTipY = -r - 24;

    ctx.save();
    ctx.shadowColor = '#fbbf24';
    ctx.shadowBlur = 14;

    // Glowing spark core
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(sparkTipX, sparkTipY, 4, 0, Math.PI * 2);
    ctx.fill();

    // Spark rays
    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 2;
    for (let k = 0; k < 6; k++) {
      const a = (k * Math.PI) / 3 + sparkPhase;
      const rayLen = 5 + Math.sin(sparkPhase * 2 + k) * 4;
      ctx.beginPath();
      ctx.moveTo(sparkTipX, sparkTipY);
      ctx.lineTo(sparkTipX + Math.cos(a) * rayLen, sparkTipY + Math.sin(a) * rayLen);
      ctx.stroke();
    }
    ctx.restore();

    // Hazard skull / danger glyph on bomb body
    ctx.fillStyle = 'rgba(239, 68, 68, 0.75)';
    ctx.font = 'bold 15px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('💣', 0, -r * 0.35);
  }

  // --- FRUIT WORD BANNER (LACQUERED WOOD PLAQUE) ---
  private drawFruitWordBanner(
    ctx: CanvasRenderingContext2D,
    text: string,
    r: number,
    isBomb: boolean,
    isCorrect: boolean
  ) {
    ctx.font = 'bold 13.5px "Segoe UI", Roboto, sans-serif';
    const textWidth = ctx.measureText(text).width;
    const bannerW = Math.max(76, textWidth + 24);
    const bannerH = 26;

    // Plaque background gradient
    const bannerGrad = ctx.createLinearGradient(0, -bannerH / 2, 0, bannerH / 2);
    if (isBomb) {
      bannerGrad.addColorStop(0, '#7f1d1d');
      bannerGrad.addColorStop(1, '#450a0a');
    } else {
      bannerGrad.addColorStop(0, 'rgba(30, 20, 12, 0.92)');
      bannerGrad.addColorStop(1, 'rgba(15, 8, 4, 0.94)');
    }

    ctx.fillStyle = bannerGrad;
    ctx.beginPath();
    ctx.roundRect(-bannerW / 2, -bannerH / 2 + 2, bannerW, bannerH, 8);
    ctx.fill();

    // Golden / red lacquer border
    ctx.strokeStyle = isBomb ? '#f87171' : '#f59e0b';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    // 4 Brass corner rivets
    ctx.fillStyle = isBomb ? '#ef4444' : '#fbbf24';
    const rivetX = bannerW / 2 - 5;
    const rivetY = bannerH / 2 - 4;
    ctx.beginPath();
    ctx.arc(-rivetX, -rivetY + 2, 1.8, 0, Math.PI * 2);
    ctx.arc(rivetX, -rivetY + 2, 1.8, 0, Math.PI * 2);
    ctx.arc(-rivetX, rivetY + 2, 1.8, 0, Math.PI * 2);
    ctx.arc(rivetX, rivetY + 2, 1.8, 0, Math.PI * 2);
    ctx.fill();

    // Word Text
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.shadowColor = 'rgba(0, 0, 0, 0.9)';
    ctx.shadowBlur = 4;
    ctx.fillText(text, 0, 2);
    ctx.shadowBlur = 0;
  }

  // ==========================================
  // --- SLICED FRUIT PIECES (AUTHENTIC INTERIORS) ---
  // ==========================================
  private drawSlicedPiece(ctx: CanvasRenderingContext2D, piece: SlicedPiece) {
    ctx.save();
    ctx.translate(piece.x, piece.y);
    ctx.rotate(piece.rot);
    ctx.globalAlpha = Math.max(0, piece.life);

    const r = piece.radius;
    const isLeft = piece.side === 'left';

    // 1. Draw Sliced Interior of Fruit
    switch (piece.fruitType) {
      case 'watermelon':
        this.drawWatermelonHalf(ctx, r, isLeft);
        break;
      case 'orange':
        this.drawOrangeHalf(ctx, r, isLeft);
        break;
      case 'apple':
        this.drawAppleHalf(ctx, r, isLeft);
        break;
      case 'strawberry':
        this.drawStrawberryHalf(ctx, r, isLeft);
        break;
      case 'banana':
        this.drawBananaHalf(ctx, r, isLeft);
        break;
      case 'pineapple':
        this.drawPineappleHalf(ctx, r, isLeft);
        break;
      case 'kiwi':
        this.drawKiwiHalf(ctx, r, isLeft);
        break;
      case 'coconut':
        this.drawCoconutHalf(ctx, r, isLeft);
        break;
      case 'bomb':
        this.drawBombHalf(ctx, r, isLeft);
        break;
    }

    // 2. Draw Sliced Half of the Word Banner
    this.drawSlicedBanner(ctx, piece.text, isLeft);

    ctx.restore();
  }

  // --- WATERMELON HALF ---
  private drawWatermelonHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Dark green outer rind
    ctx.fillStyle = '#15803d';
    ctx.fill();

    // White/Lime inner rind layer
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.88, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#dcfce7';
    ctx.fill();

    // Succulent red watermelon flesh
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.8, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#ef4444';
    ctx.fill();

    // Black teardrop watermelon seeds
    ctx.fillStyle = '#0f172a';
    const seedX = isLeft ? -r * 0.45 : r * 0.45;
    for (let sy of [-r * 0.4, 0, r * 0.4]) {
      ctx.beginPath();
      ctx.ellipse(seedX, sy, 2.5, 4, isLeft ? 0.3 : -0.3, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // --- ORANGE HALF ---
  private drawOrangeHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Orange peel
    ctx.fillStyle = '#ea580c';
    ctx.fill();

    // White pith
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.9, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#fef08a';
    ctx.fill();

    // Juicy citrus segments
    const segCount = 4;
    for (let s = 0; s < segCount; s++) {
      const a1 = startAng + (s * Math.PI) / segCount + 0.08;
      const a2 = startAng + ((s + 1) * Math.PI) / segCount - 0.08;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, r * 0.82, a1, a2);
      ctx.closePath();
      ctx.fillStyle = '#fb923c';
      ctx.fill();
    }
  }

  // --- APPLE HALF ---
  private drawAppleHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Red skin rim
    ctx.fillStyle = '#dc2626';
    ctx.fill();

    // Crisp creamy pale flesh
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.9, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#fef9c3';
    ctx.fill();

    // Core recess & seeds
    ctx.fillStyle = '#451a03';
    ctx.beginPath();
    ctx.ellipse(isLeft ? -r * 0.25 : r * 0.25, 0, 3, 5, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  // --- STRAWBERRY HALF ---
  private drawStrawberryHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    ctx.fillStyle = '#e11d48';
    ctx.fill();

    // Soft pinkish flesh gradient
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.85, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#ffe4e6';
    ctx.fill();

    // Fiber rays
    ctx.strokeStyle = '#f43f5e';
    ctx.lineWidth = 1.2;
    for (let a = startAng; a <= endAng; a += 0.35) {
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(Math.cos(a) * r * 0.7, Math.sin(a) * r * 0.7);
      ctx.stroke();
    }
  }

  // --- BANANA HALF ---
  private drawBananaHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r * 0.8, startAng, endAng);
    ctx.closePath();

    // Yellow peel
    ctx.fillStyle = '#facc15';
    ctx.fill();

    // Creamy pale flesh
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.7, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#fef08a';
    ctx.fill();
  }

  // --- PINEAPPLE HALF ---
  private drawPineappleHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    ctx.fillStyle = '#ca8a04';
    ctx.fill();

    // Golden yellow pulp
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.88, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#facc15';
    ctx.fill();

    // Core circle
    ctx.strokeStyle = '#eab308';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.35, startAng, endAng);
    ctx.stroke();
  }

  // --- KIWI HALF ---
  private drawKiwiHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Brown fuzzy skin
    ctx.fillStyle = '#78350f';
    ctx.fill();

    // Vibrant emerald pulp
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.88, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#22c55e';
    ctx.fill();

    // Cream center
    ctx.fillStyle = '#fef9c3';
    ctx.beginPath();
    ctx.ellipse(0, 0, isLeft ? -r * 0.22 : r * 0.22, r * 0.35, 0, 0, Math.PI * 2);
    ctx.fill();

    // Ring of black seeds
    ctx.fillStyle = '#0f172a';
    for (let k = 0; k < 6; k++) {
      const a = startAng + (k * Math.PI) / 6 + 0.15;
      ctx.beginPath();
      ctx.arc(Math.cos(a) * r * 0.45, Math.sin(a) * r * 0.45, 1.6, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // --- COCONUT HALF ---
  private drawCoconutHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Brown shell
    ctx.fillStyle = '#451a03';
    ctx.fill();

    // Pure white coconut meat
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.85, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#f8fafc';
    ctx.fill();

    // Hollow center
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.48, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#1e1b4b';
    ctx.fill();
  }

  // --- BOMB HALF ---
  private drawBombHalf(ctx: CanvasRenderingContext2D, r: number, isLeft: boolean) {
    ctx.beginPath();
    const startAng = isLeft ? Math.PI * 0.5 : -Math.PI * 0.5;
    const endAng = isLeft ? Math.PI * 1.5 : Math.PI * 0.5;
    ctx.arc(0, 0, r, startAng, endAng);
    ctx.closePath();

    // Cracked iron shell
    ctx.fillStyle = '#1e293b';
    ctx.fill();

    // Red-hot ember interior
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.8, startAng, endAng);
    ctx.closePath();
    ctx.fillStyle = '#ef4444';
    ctx.fill();
  }

  // --- SLICED BANNER ---
  private drawSlicedBanner(ctx: CanvasRenderingContext2D, text: string, isLeft: boolean) {
    ctx.font = 'bold 12px "Segoe UI", Roboto, sans-serif';
    const tagW = 38;
    const tagH = 22;

    ctx.fillStyle = 'rgba(20, 10, 5, 0.9)';
    ctx.beginPath();
    ctx.roundRect(isLeft ? -tagW : 0, -tagH / 2, tagW, tagH, 4);
    ctx.fill();

    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 1.2;
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, isLeft ? -tagW / 2 : tagW / 2, 0);
  }

  // --- GLOWING KATANA TRAIL ---
  private drawBladeTrail(ctx: CanvasRenderingContext2D) {
    if (this.bladeTrail.length < 2) return;

    ctx.save();
    for (let i = 1; i < this.bladeTrail.length; i++) {
      const pA = this.bladeTrail[i - 1];
      const pB = this.bladeTrail[i];
      const alpha = i / this.bladeTrail.length;

      // Outer Neon Cyan Glow
      ctx.strokeStyle = `rgba(56, 189, 248, ${alpha * 0.75})`;
      ctx.lineWidth = 11 * alpha;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(pA.x, pA.y);
      ctx.lineTo(pB.x, pB.y);
      ctx.stroke();

      // Inner Sharp Katana Core
      ctx.strokeStyle = `rgba(255, 255, 255, ${alpha * 0.95})`;
      ctx.lineWidth = 4 * alpha;
      ctx.beginPath();
      ctx.moveTo(pA.x, pA.y);
      ctx.lineTo(pB.x, pB.y);
      ctx.stroke();
    }
    ctx.restore();
  }

  private drawStartBanner() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    this.render();

    ctx.fillStyle = 'rgba(15, 23, 42, 0.72)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('⚔️ Word Ninja Slicer', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#cbd5e1';
    ctx.fillText('Slice flying fruits with target words!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText('🍉 Orange • Apple • Watermelon • Avoid Bombs! 💣', canvas.width / 2, canvas.height / 2 + 16);
    ctx.restore();
  }
}
