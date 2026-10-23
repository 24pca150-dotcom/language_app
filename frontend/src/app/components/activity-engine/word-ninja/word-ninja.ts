import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, HostListener, signal } from '@angular/core';
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

interface SlicedPiece {
  x: number;
  y: number;
  vx: number;
  vy: number;
  rot: number;
  vRot: number;
  text: string;
  side: 'left' | 'right';
  color: string;
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
  sliced: boolean;
  angle: number;
  vRot: number;
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
}

interface BladePoint {
  x: number;
  y: number;
  time: number;
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
  lives = signal<number>(3);
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

  // Slicing Trail
  private isPointerDown: boolean = false;
  private bladeTrail: BladePoint[] = [];

  // Active game entities
  private floatingItems: FloatingWordItem[] = [];
  private slicedPieces: SlicedPiece[] = [];
  private particles: Particle[] = [];
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
        // Blade swoosh
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(600, now);
        osc.frequency.exponentialRampToValueAtTime(200, now + 0.08);
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.08);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.08);
      } else if (type === 'slice') {
        // Crisp slice chop + chord
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(880, now);
        osc.frequency.exponentialRampToValueAtTime(440, now + 0.12);
        gain.gain.setValueAtTime(0.2, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.12);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.12);
      } else if (type === 'bomb') {
        // Boom explosion
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(100, now);
        osc.frequency.exponentialRampToValueAtTime(30, now + 0.35);
        gain.gain.setValueAtTime(0.3, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.35);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.35);
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
    this.lives.set(3);
    this.streak.set(0);
    this.slicedCorrectCount = 0;
    this.slicedWrongCount = 0;
    this.floatingItems = [];
    this.slicedPieces = [];
    this.particles = [];
    this.bladeTrail = [];
    this.spawnTimer = 0.5; // launch first wave quickly
    this.startLoop();
  }

  restartGame() {
    this.startGame();
  }

  toggleSound() {
    this.soundEnabled.update(s => !s);
  }

  // --- CONTROLS: POINTER EVENTS (TOUCH & MOUSE) ---
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

    // Check line segment intersection with floating items
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

  // --- SLICE INTERSECTION DETECTION ---
  private checkSliceCollisions(p1: BladePoint, p2: BladePoint) {
    for (const item of this.floatingItems) {
      if (item.sliced) continue;

      // Distance from circle center to line segment
      const dist = this.distToSegment({ x: item.x, y: item.y }, p1, p2);
      if (dist < item.radius + 8) {
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
      // CORRECT SLICE!
      this.slicedCorrectCount++;
      const bonus = 100 + this.streak() * 20;
      this.score.update(s => s + bonus);
      this.streak.update(st => st + 1);
      this.playSynthSound('slice');

      // Create slice halves
      this.createSlicePieces(item);
      this.addJuiceSplatter(item.x, item.y, '#10b981', 30);

      if (this.slicedCorrectCount >= this.targetSlicesNeeded) {
        setTimeout(() => this.triggerVictory(), 400);
      }
    } else {
      // WRONG SLICE (Bomb/Distractor)
      this.slicedWrongCount++;
      this.streak.set(0);
      this.lives.update(l => Math.max(0, l - 1));
      this.playSynthSound('bomb');
      this.addJuiceSplatter(item.x, item.y, '#ef4444', 40);

      if (this.lives() <= 0) {
        setTimeout(() => this.triggerGameOver(), 400);
      }
    }
  }

  private createSlicePieces(item: FloatingWordItem) {
    const leftText = item.text.slice(0, Math.ceil(item.text.length / 2));
    const rightText = item.text.slice(Math.ceil(item.text.length / 2));

    this.slicedPieces.push({
      x: item.x - 12,
      y: item.y,
      vx: item.vx - 60,
      vy: item.vy - 30,
      rot: item.angle,
      vRot: -3,
      text: leftText,
      side: 'left',
      color: item.color,
      life: 1.2
    });

    this.slicedPieces.push({
      x: item.x + 12,
      y: item.y,
      vx: item.vx + 60,
      vy: item.vy - 30,
      rot: item.angle,
      vRot: 3,
      text: rightText,
      side: 'right',
      color: item.color,
      life: 1.2
    });
  }

  private addJuiceSplatter(x: number, y: number, color: string, count: number) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 60 + Math.random() * 220;
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        color: color,
        radius: 3 + Math.random() * 4,
        life: 0.5 + Math.random() * 0.3,
        maxLife: 0.8
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
    // Gravity constant
    const gravity = 480;

    // Prune old blade trail (lasts ~150ms)
    const now = performance.now();
    this.bladeTrail = this.bladeTrail.filter(pt => now - pt.time < 160);

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

      // Drop off bottom of screen
      if (item.y > this.canvasRef.nativeElement.height + 80) {
        // If an unsliced correct item fell, player missed it!
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
      p.vy += gravity * 0.4 * dt;
      p.life -= dt;
      if (p.life <= 0) this.particles.splice(i, 1);
    }
  }

  private launchWave() {
    const canvas = this.canvasRef.nativeElement;
    // Launch 2 to 3 items
    const count = Math.random() < 0.6 ? 2 : 3;
    for (let i = 0; i < count; i++) {
      const isCorrect = Math.random() < 0.65 || (this.correctBank.length > 0 && Math.random() < 0.5);
      const text = isCorrect
        ? this.correctBank[Math.floor(Math.random() * this.correctBank.length)]
        : this.wrongBank[Math.floor(Math.random() * this.wrongBank.length)];

      const spawnX = 60 + Math.random() * (canvas.width - 120);
      const spawnY = canvas.height + 25;

      // Initial impulse launch velocity upwards towards center
      const targetCenterX = canvas.width / 2;
      const vx = (targetCenterX - spawnX) * (0.6 + Math.random() * 0.4) + (Math.random() - 0.5) * 40;
      const vy = -(530 + Math.random() * 80);

      this.floatingItems.push({
        id: ++this.itemIdCounter,
        x: spawnX,
        y: spawnY,
        vx: vx,
        vy: vy,
        radius: 38,
        text: text,
        isCorrect: isCorrect,
        color: isCorrect ? '#059669' : '#dc2626',
        sliced: false,
        angle: (Math.random() - 0.5) * 0.4,
        vRot: (Math.random() - 0.5) * 1.5
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

  // --- RENDERER ---
  private render() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // 1. Dojo Wooden Background
    const bgGrad = ctx.createRadialGradient(canvas.width / 2, canvas.height / 2, 50, canvas.width / 2, canvas.height / 2, 400);
    bgGrad.addColorStop(0, '#1e1b4b');
    bgGrad.addColorStop(1, '#0f172a');
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Faint dojo wood floor lines
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
    ctx.lineWidth = 1.5;
    for (let y = 60; y < canvas.height; y += 60) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvas.width, y);
      ctx.stroke();
    }

    // 2. Particles (Juice & Sparks)
    this.particles.forEach(p => {
      ctx.save();
      ctx.fillStyle = p.color;
      ctx.globalAlpha = p.life / p.maxLife;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 3. Floating Items (Un-sliced)
    this.floatingItems.forEach(item => {
      if (item.sliced) return;
      ctx.save();
      ctx.translate(item.x, item.y);
      ctx.rotate(item.angle);

      // Shadow
      ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
      ctx.beginPath();
      ctx.roundRect(-item.radius, -item.radius + 6, item.radius * 2, item.radius * 2, 20);
      ctx.fill();

      // Fruit / Word Bubble Body
      const bubbleGrad = ctx.createLinearGradient(0, -item.radius, 0, item.radius);
      if (item.isCorrect) {
        bubbleGrad.addColorStop(0, '#34d399');
        bubbleGrad.addColorStop(1, '#059669');
      } else {
        bubbleGrad.addColorStop(0, '#f87171');
        bubbleGrad.addColorStop(1, '#dc2626');
      }

      ctx.fillStyle = bubbleGrad;
      ctx.strokeStyle = item.isCorrect ? '#6ee7b7' : '#fca5a5';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.roundRect(-item.radius, -item.radius, item.radius * 2, item.radius * 2, 18);
      ctx.fill();
      ctx.stroke();

      // Glossy highlight
      ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
      ctx.beginPath();
      ctx.roundRect(-item.radius + 6, -item.radius + 6, item.radius * 2 - 12, 14, 8);
      ctx.fill();

      // Word Text
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 15px "Segoe UI", Roboto, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.shadowColor = 'rgba(0,0,0,0.6)';
      ctx.shadowBlur = 4;
      ctx.fillText(item.text, 0, 0);

      ctx.restore();
    });

    // 4. Sliced Pieces
    this.slicedPieces.forEach(p => {
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      ctx.globalAlpha = Math.max(0, p.life);

      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.roundRect(-22, -22, 44, 44, 8);
      ctx.fill();

      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 13px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(p.text, 0, 0);
      ctx.restore();
    });

    // 5. Glowing Katana Blade Trail
    if (this.bladeTrail.length >= 2) {
      ctx.save();
      for (let i = 1; i < this.bladeTrail.length; i++) {
        const pA = this.bladeTrail[i - 1];
        const pB = this.bladeTrail[i];
        const alpha = i / this.bladeTrail.length;

        // Outer Neon Glow
        ctx.strokeStyle = `rgba(56, 189, 248, ${alpha * 0.7})`;
        ctx.lineWidth = 10 * alpha;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(pA.x, pA.y);
        ctx.lineTo(pB.x, pB.y);
        ctx.stroke();

        // Inner Sharp Blade Core
        ctx.strokeStyle = `rgba(255, 255, 255, ${alpha})`;
        ctx.lineWidth = 4 * alpha;
        ctx.beginPath();
        ctx.moveTo(pA.x, pA.y);
        ctx.lineTo(pB.x, pB.y);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  private drawStartBanner() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    this.render();

    ctx.fillStyle = 'rgba(15, 23, 42, 0.7)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('⚔️ Word Ninja Slicer', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#94a3b8';
    ctx.fillText('Swipe or drag across words to slice!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText('Slice correct targets • Avoid distractors', canvas.width / 2, canvas.height / 2 + 15);
    ctx.restore();
  }
}
