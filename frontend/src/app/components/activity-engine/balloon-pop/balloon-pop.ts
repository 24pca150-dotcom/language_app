import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, HostListener, signal } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface BalloonPopData {
  id?: number;
  type?: string;
  title?: string;
  question?: string;
  correctWords?: string[];
  wrongWords?: string[];
  speed?: 'gentle' | 'normal' | 'breezy';
  explanation?: string;
}

interface Balloon {
  id: number;
  x: number;
  y: number;
  vy: number;
  radius: number;
  text: string;
  isCorrect: boolean;
  color: string;
  wobbleOffset: number;
  wobbleSpeed: number;
  popped: boolean;
}

interface ConfettiParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  color: string;
  size: number;
  life: number;
  maxLife: number;
}

@Component({
  selector: 'app-activity-balloon-pop',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './balloon-pop.html',
  styleUrls: ['./balloon-pop.css']
})
export class BalloonPopComponent implements OnInit, OnDestroy {
  @Input() activity: BalloonPopData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{
    isCorrect: boolean;
    score: number;
    accuracy: number;
  }>();

  @ViewChild('balloonCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;

  // Game Signals
  gameState = signal<'start' | 'playing' | 'gameover' | 'victory'>('start');
  score = signal<number>(0);
  lives = signal<number>(5);
  poppedCount = signal<number>(0);
  targetPrompt = signal<string>('Pop the correct balloons!');
  soundEnabled = signal<boolean>(true);
  Math = Math;

  // Web Audio Synth
  private audioCtx: AudioContext | null = null;

  // Loop & Anim
  private animFrameId: number | null = null;
  private lastTime: number = 0;
  private spawnTimer: number = 0;
  private spawnInterval: number = 1.4;

  // Entities
  private balloons: Balloon[] = [];
  private confetti: ConfettiParticle[] = [];
  private balloonIdCounter: number = 0;

  // Words
  private correctBank: string[] = [];
  private wrongBank: string[] = [];
  private targetNeeded: number = 10;
  poppedCorrectTotal: number = 0;
  poppedWrongTotal: number = 0;

  private balloonColors = ['#f43f5e', '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4'];

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

  playSynthSound(type: 'pop' | 'wrong' | 'win') {
    if (!this.soundEnabled()) return;
    this.initAudio();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    try {
      if (type === 'pop') {
        // High crisp snap pop + rubber thump
        const osc = ctx.createOscillator();
        const thump = ctx.createOscillator();
        const gain = ctx.createGain();
        const thumpGain = ctx.createGain();

        osc.type = 'triangle';
        osc.frequency.setValueAtTime(950, now);
        osc.frequency.exponentialRampToValueAtTime(70, now + 0.06);

        thump.type = 'sine';
        thump.frequency.setValueAtTime(140, now);
        thump.frequency.exponentialRampToValueAtTime(45, now + 0.08);

        gain.gain.setValueAtTime(0.4, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

        thumpGain.gain.setValueAtTime(0.3, now);
        thumpGain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

        osc.connect(gain);
        thump.connect(thumpGain);
        gain.connect(ctx.destination);
        thumpGain.connect(ctx.destination);

        osc.start(now);
        thump.start(now);
        osc.stop(now + 0.07);
        thump.stop(now + 0.08);
      } else if (type === 'wrong') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(140, now);
        osc.frequency.exponentialRampToValueAtTime(60, now + 0.25);
        gain.gain.setValueAtTime(0.2, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
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
    this.targetPrompt.set(act?.question || act?.title || 'Pop the correct target word balloons!');

    if (act?.correctWords && act.correctWords.length > 0) {
      this.correctBank = [...act.correctWords];
    } else {
      this.correctBank = ['Sun', 'Moon', 'Sky', 'Star', 'Cloud', 'Rain', 'Breeze'];
    }

    if (act?.wrongWords && act.wrongWords.length > 0) {
      this.wrongBank = [...act.wrongWords];
    } else {
      this.wrongBank = ['Car', 'Table', 'Phone', 'Book', 'Shoe', 'Chair'];
    }

    if (act?.speed === 'gentle') this.spawnInterval = 1.8;
    else if (act?.speed === 'breezy') this.spawnInterval = 1.1;
    else this.spawnInterval = 1.4;

    this.targetNeeded = Math.min(10, this.correctBank.length * 2);
  }

  private initCanvas() {
    const canvas = this.canvasRef.nativeElement;
    canvas.width = 440;
    canvas.height = 580;
    this.drawStartScreen();
  }

  startGame() {
    this.initAudio();
    this.gameState.set('playing');
    this.score.set(0);
    this.lives.set(5);
    this.poppedCorrectTotal = 0;
    this.poppedWrongTotal = 0;
    this.poppedCount.set(0);
    this.balloons = [];
    this.confetti = [];
    this.spawnTimer = 0.4;
    this.startLoop();
  }

  restartGame() {
    this.startGame();
  }

  toggleSound() {
    this.soundEnabled.update(s => !s);
  }

  onCanvasClick(e: MouseEvent) {
    if (this.gameState() !== 'playing') return;
    const canvas = this.canvasRef.nativeElement;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    const clickX = (e.clientX - rect.left) * scaleX;
    const clickY = (e.clientY - rect.top) * scaleY;

    // Check hit balloon (check from top to bottom)
    for (let i = this.balloons.length - 1; i >= 0; i--) {
      const b = this.balloons[i];
      if (b.popped) continue;

      const dist = Math.hypot(clickX - b.x, clickY - b.y);
      if (dist <= b.radius + 6) {
        this.popBalloon(b);
        break;
      }
    }
  }

  private popBalloon(b: Balloon) {
    b.popped = true;

    if (b.isCorrect) {
      // CORRECT!
      this.poppedCorrectTotal++;
      this.poppedCount.set(this.poppedCorrectTotal);
      this.score.update(s => s + 100);
      this.playSynthSound('pop');
      this.addConfetti(b.x, b.y, b.color);

      if (this.poppedCorrectTotal >= this.targetNeeded) {
        setTimeout(() => this.triggerVictory(), 400);
      }
    } else {
      // WRONG!
      this.poppedWrongTotal++;
      this.lives.update(l => Math.max(0, l - 1));
      this.playSynthSound('wrong');
      this.addConfetti(b.x, b.y, '#ef4444');

      if (this.lives() <= 0) {
        setTimeout(() => this.triggerGameOver(), 400);
      }
    }
  }

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
    const canvas = this.canvasRef.nativeElement;

    // Spawn balloons
    this.spawnTimer -= dt;
    if (this.spawnTimer <= 0) {
      this.spawnTimer = this.spawnInterval;
      this.spawnBalloon();
    }

    // Move balloons
    for (let i = this.balloons.length - 1; i >= 0; i--) {
      const b = this.balloons[i];
      b.y += b.vy * dt;
      b.wobbleOffset += b.wobbleSpeed * dt;
      b.x += Math.sin(b.wobbleOffset) * 0.6;

      // Check escaped top
      if (b.y < -50) {
        if (b.isCorrect && !b.popped) {
          // Missed correct balloon!
          this.lives.update(l => Math.max(0, l - 1));
          this.playSynthSound('wrong');
          if (this.lives() <= 0) {
            this.triggerGameOver();
            return;
          }
        }
        this.balloons.splice(i, 1);
      }
    }

    // Update confetti
    for (let i = this.confetti.length - 1; i >= 0; i--) {
      const c = this.confetti[i];
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vy += 320 * dt; // gravity
      c.life -= dt;
      if (c.life <= 0) this.confetti.splice(i, 1);
    }
  }

  private spawnBalloon() {
    const canvas = this.canvasRef.nativeElement;
    const isCorrect = Math.random() < 0.65;
    const text = isCorrect
      ? this.correctBank[Math.floor(Math.random() * this.correctBank.length)]
      : this.wrongBank[Math.floor(Math.random() * this.wrongBank.length)];

    const color = isCorrect
      ? this.balloonColors[Math.floor(Math.random() * this.balloonColors.length)]
      : '#64748b';

    const radius = 38;
    const x = radius + 15 + Math.random() * (canvas.width - radius * 2 - 30);
    const speed = -(90 + Math.random() * 45);

    this.balloons.push({
      id: ++this.balloonIdCounter,
      x: x,
      y: canvas.height + 60,
      vy: speed,
      radius: radius,
      text: text,
      isCorrect: isCorrect,
      color: color,
      wobbleOffset: Math.random() * Math.PI * 2,
      wobbleSpeed: 2 + Math.random() * 2,
      popped: false
    });
  }

  private addConfetti(x: number, y: number, color: string) {
    const palette = [color, '#facc15', '#38bdf8', '#ffffff'];
    for (let i = 0; i < 28; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 60 + Math.random() * 200;
      this.confetti.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        color: palette[Math.floor(Math.random() * palette.length)],
        size: 3 + Math.random() * 4,
        life: 0.6,
        maxLife: 0.6
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
    const total = this.poppedCorrectTotal + this.poppedWrongTotal;
    const accuracy = total > 0 ? Math.round((this.poppedCorrectTotal / total) * 100) : 0;
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

    // 1. Sky Gradient
    const skyGrad = ctx.createLinearGradient(0, 0, 0, canvas.height);
    skyGrad.addColorStop(0, '#e0f2fe');
    skyGrad.addColorStop(0.5, '#bae6fd');
    skyGrad.addColorStop(1, '#7dd3fc');
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // 2. Confetti
    this.confetti.forEach(c => {
      ctx.save();
      ctx.fillStyle = c.color;
      ctx.globalAlpha = c.life / c.maxLife;
      ctx.beginPath();
      ctx.arc(c.x, c.y, c.size, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 3. Balloons
    this.balloons.forEach(b => {
      if (b.popped) return;
      ctx.save();
      ctx.translate(b.x, b.y);

      // String
      ctx.strokeStyle = '#94a3b8';
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(0, b.radius);
      ctx.quadraticCurveTo(6, b.radius + 15, -4, b.radius + 30);
      ctx.stroke();

      // Shadow
      ctx.fillStyle = 'rgba(0, 0, 0, 0.12)';
      ctx.beginPath();
      ctx.arc(4, 4, b.radius, 0, Math.PI * 2);
      ctx.fill();

      // Balloon Body (Oval)
      const grad = ctx.createRadialGradient(-10, -10, 5, 0, 0, b.radius);
      grad.addColorStop(0, '#ffffff');
      grad.addColorStop(0.3, b.color);
      grad.addColorStop(1, b.color);
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.ellipse(0, 0, b.radius, b.radius * 1.15, 0, 0, Math.PI * 2);
      ctx.fill();

      // Knot
      ctx.fillStyle = b.color;
      ctx.beginPath();
      ctx.moveTo(-5, b.radius * 1.15);
      ctx.lineTo(5, b.radius * 1.15);
      ctx.lineTo(0, b.radius * 1.15 + 6);
      ctx.closePath();
      ctx.fill();

      // Text inside balloon
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 15px "Segoe UI", Roboto, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.shadowColor = 'rgba(0,0,0,0.6)';
      ctx.shadowBlur = 4;
      ctx.fillText(b.text, 0, 0);

      ctx.restore();
    });
  }

  private drawStartScreen() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    this.render();

    ctx.fillStyle = 'rgba(15, 23, 42, 0.55)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🎈 Balloon Word Pop', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#e2e8f0';
    ctx.fillText('Tap floating balloons to pop correct words!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText("Don't let target balloons escape into the clouds", canvas.width / 2, canvas.height / 2 + 15);
    ctx.restore();
  }
}
