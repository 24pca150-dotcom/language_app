import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, HostListener, signal } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface SpaceDefenderChallenge {
  question: string;
  targetWord: string;
  distractors: string[];
  explanation?: string;
}

export interface SpaceDefenderData {
  id?: number;
  type?: string;
  title?: string;
  question?: string;
  speed?: 'normal' | 'hyper' | 'inferno';
  challenges?: SpaceDefenderChallenge[];
  explanation?: string;
}

interface Bullet {
  x: number;
  y: number;
  vy: number;
}

interface AlienTarget {
  id: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  text: string;
  isCorrect: boolean;
  radius: number;
  destroyed: boolean;
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

interface Star {
  x: number;
  y: number;
  size: number;
  speed: number;
}

@Component({
  selector: 'app-activity-space-defender',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './space-defender.html',
  styleUrls: ['./space-defender.css']
})
export class SpaceDefenderComponent implements OnInit, OnDestroy {
  @Input() activity: SpaceDefenderData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{
    isCorrect: boolean;
    score: number;
    total: number;
    accuracy: number;
  }>();

  @ViewChild('spaceCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;

  // Game Signals
  gameState = signal<'start' | 'playing' | 'gameover' | 'victory'>('start');
  score = signal<number>(0);
  lives = signal<number>(5);
  currentChallengeIndex = signal<number>(0);
  totalChallenges = signal<number>(1);
  currentPrompt = signal<string>('Shoot the correct answer UFO!');
  soundEnabled = signal<boolean>(true);
  Math = Math;

  // Audio Context
  private audioCtx: AudioContext | null = null;

  // Loop & Anim
  private animFrameId: number | null = null;
  private lastTime: number = 0;

  // Player Ship
  playerX: number = 240;
  playerY: number = 550;
  private shipSpeed: number = 320;
  private movingLeft: boolean = false;
  private movingRight: boolean = false;

  // Bullets & Aliens
  private bullets: Bullet[] = [];
  private aliens: AlienTarget[] = [];
  private particles: Particle[] = [];
  private stars: Star[] = [];
  private lastFireTime: number = 0;

  challengesData: SpaceDefenderChallenge[] = [];
  correctHits: number = 0;
  wrongHits: number = 0;

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

  playSynthSound(type: 'laser' | 'boom' | 'hit' | 'win') {
    if (!this.soundEnabled()) return;
    this.initAudio();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    try {
      if (type === 'laser') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(880, now);
        osc.frequency.exponentialRampToValueAtTime(180, now + 0.09);
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.09);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.09);
      } else if (type === 'boom') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(300, now);
        osc.frequency.exponentialRampToValueAtTime(50, now + 0.25);
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
      } else if (type === 'hit') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(140, now);
        osc.frequency.exponentialRampToValueAtTime(40, now + 0.3);
        gain.gain.setValueAtTime(0.3, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.3);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.3);
      } else if (type === 'win') {
        [523, 659, 784, 1046].forEach((f, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(f, now + idx * 0.08);
          gain.gain.setValueAtTime(0.2, now + idx * 0.08);
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
    this.challengesData = [];

    if (act?.challenges && act.challenges.length > 0) {
      this.challengesData = JSON.parse(JSON.stringify(act.challenges));
    } else {
      this.challengesData = [
        {
          question: "Shoot the Antonym of 'Cowardly':",
          targetWord: "Brave",
          distractors: ["Timid", "Fearful"]
        },
        {
          question: "Shoot the Correct Verb in: 'They ____ soccer':",
          targetWord: "Play",
          distractors: ["Plays", "Playing"]
        },
        {
          question: "Shoot the Synonym of 'Fast':",
          targetWord: "Rapid",
          distractors: ["Slow", "Lazy"]
        }
      ];
    }

    this.totalChallenges.set(this.challengesData.length);
  }

  private initCanvas() {
    const canvas = this.canvasRef.nativeElement;
    canvas.width = 440;
    canvas.height = 580;
    this.playerX = canvas.width / 2;
    this.playerY = canvas.height - 55;

    // Starfield
    this.stars = [];
    for (let i = 0; i < 40; i++) {
      this.stars.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        size: 1 + Math.random() * 2,
        speed: 40 + Math.random() * 80
      });
    }

    this.drawStartScreen();
  }

  startGame() {
    this.initAudio();
    this.gameState.set('playing');
    this.score.set(0);
    this.lives.set(5);
    this.currentChallengeIndex.set(0);
    this.correctHits = 0;
    this.wrongHits = 0;
    this.bullets = [];
    this.aliens = [];
    this.particles = [];
    this.playerX = this.canvasRef.nativeElement.width / 2;
    this.playerY = this.canvasRef.nativeElement.height - 55;
    this.spawnChallenge(0);
    this.startLoop();
  }

  restartGame() {
    this.startGame();
  }

  toggleSound() {
    this.soundEnabled.update(s => !s);
  }

  @HostListener('window:keydown', ['$event'])
  handleKeyDown(e: KeyboardEvent) {
    if (this.gameState() !== 'playing') return;
    if (e.key === 'ArrowLeft' || e.key.toLowerCase() === 'a') {
      this.movingLeft = true;
    } else if (e.key === 'ArrowRight' || e.key.toLowerCase() === 'd') {
      this.movingRight = true;
    } else if (e.key === ' ' || e.key === 'ArrowUp' || e.key.toLowerCase() === 'w') {
      e.preventDefault();
      this.fireBullet();
    }
  }

  @HostListener('window:keyup', ['$event'])
  handleKeyUp(e: KeyboardEvent) {
    if (e.key === 'ArrowLeft' || e.key.toLowerCase() === 'a') {
      this.movingLeft = false;
    } else if (e.key === 'ArrowRight' || e.key.toLowerCase() === 'd') {
      this.movingRight = false;
    }
  }

  moveShip(delta: number) {
    this.playerX = Math.max(30, Math.min(this.canvasRef.nativeElement.width - 30, this.playerX + delta * 40));
  }

  fireBullet() {
    const now = performance.now();
    if (now - this.lastFireTime < 180) return; // rate limit
    this.lastFireTime = now;

    this.bullets.push({
      x: this.playerX,
      y: this.playerY - 24,
      vy: -550
    });
    this.playSynthSound('laser');
  }

  private spawnChallenge(idx: number) {
    if (idx >= this.challengesData.length) {
      this.triggerVictory();
      return;
    }
    this.currentChallengeIndex.set(idx);
    const ch = this.challengesData[idx];
    this.currentPrompt.set(ch.question);
    this.aliens = [];

    // Combine target and distractors
    const all = [
      { text: ch.targetWord, isCorrect: true },
      ...ch.distractors.map(d => ({ text: d, isCorrect: false }))
    ];
    // Shuffle positions
    all.sort(() => Math.random() - 0.5);

    const canvasW = this.canvasRef.nativeElement.width;
    const spacing = canvasW / (all.length + 1);

    all.forEach((item, i) => {
      this.aliens.push({
        id: i + 1,
        x: spacing * (i + 1),
        y: -40,
        vx: (Math.random() - 0.5) * 30,
        vy: 65 + Math.random() * 25,
        text: item.text,
        isCorrect: item.isCorrect,
        radius: 38,
        destroyed: false
      });
    });
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

    // Move player
    if (this.movingLeft) this.playerX = Math.max(30, this.playerX - this.shipSpeed * dt);
    if (this.movingRight) this.playerX = Math.min(canvas.width - 30, this.playerX + this.shipSpeed * dt);

    // Starfield scroll
    this.stars.forEach(s => {
      s.y += s.speed * dt;
      if (s.y > canvas.height) {
        s.y = 0;
        s.x = Math.random() * canvas.width;
      }
    });

    // Move bullets
    for (let i = this.bullets.length - 1; i >= 0; i--) {
      const b = this.bullets[i];
      b.y += b.vy * dt;
      if (b.y < -20) this.bullets.splice(i, 1);
    }

    // Move aliens & check collision with bullets
    let targetDestroyed = false;

    for (let i = this.aliens.length - 1; i >= 0; i--) {
      const a = this.aliens[i];
      if (a.destroyed) continue;

      a.y += a.vy * dt;
      a.x += a.vx * dt;

      // Bounce horizontal walls
      if (a.x < a.radius || a.x > canvas.width - a.radius) a.vx = -a.vx;

      // Check bullet hit
      for (let j = this.bullets.length - 1; j >= 0; j--) {
        const b = this.bullets[j];
        if (Math.hypot(b.x - a.x, b.y - a.y) < a.radius) {
          // Hit!
          a.destroyed = true;
          this.bullets.splice(j, 1);

          if (a.isCorrect) {
            // TARGET HIT!
            this.correctHits++;
            this.score.update(s => s + 100);
            this.playSynthSound('boom');
            this.addExplosionParticles(a.x, a.y, '#10b981', 25);
            targetDestroyed = true;
          } else {
            // WRONG TARGET HIT!
            this.wrongHits++;
            this.lives.update(l => Math.max(0, l - 1));
            this.playSynthSound('hit');
            this.addExplosionParticles(a.x, a.y, '#ef4444', 30);
            if (this.lives() <= 0) {
              this.triggerGameOver();
              return;
            }
          }
          break;
        }
      }

      // Check reach bottom defense line
      if (a.y > canvas.height - 40) {
        if (a.isCorrect) {
          // Target escaped!
          this.wrongHits++;
          this.lives.update(l => Math.max(0, l - 1));
          this.playSynthSound('hit');
          if (this.lives() <= 0) {
            this.triggerGameOver();
            return;
          }
          targetDestroyed = true; // force next wave
        }
        this.aliens.splice(i, 1);
      }
    }

    if (targetDestroyed) {
      setTimeout(() => {
        if (this.gameState() === 'playing') {
          this.spawnChallenge(this.currentChallengeIndex() + 1);
        }
      }, 700);
    }

    // Update Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.life <= 0) this.particles.splice(i, 1);
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
    const total = this.challengesData.length;
    const accuracy = total > 0 ? Math.round((this.correctHits / total) * 100) : 0;
    this.answered.emit({
      isCorrect: won && this.correctHits >= Math.ceil(total * 0.6),
      score: this.score(),
      total: total,
      accuracy: accuracy
    });
  }

  private addExplosionParticles(x: number, y: number, color: string, count: number) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 40 + Math.random() * 180;
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        color: color,
        radius: 3 + Math.random() * 4,
        life: 0.5,
        maxLife: 0.5
      });
    }
  }

  // --- RENDERER ---
  private render() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // 1. Deep Space
    ctx.fillStyle = '#090d16';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // 2. Stars
    ctx.fillStyle = '#ffffff';
    this.stars.forEach(s => {
      ctx.fillRect(s.x, s.y, s.size, s.size);
    });

    // 3. Bullets (Laser beams)
    ctx.fillStyle = '#38bdf8';
    ctx.shadowColor = '#0284c7';
    ctx.shadowBlur = 8;
    this.bullets.forEach(b => {
      ctx.fillRect(b.x - 2.5, b.y, 5, 16);
    });
    ctx.shadowBlur = 0;

    // 4. Aliens / Target Asteroid Pods
    this.aliens.forEach(a => {
      if (a.destroyed) return;
      ctx.save();
      ctx.translate(a.x, a.y);

      // Pod Body
      ctx.fillStyle = a.isCorrect ? '#065f46' : '#7f1d1d';
      ctx.strokeStyle = a.isCorrect ? '#10b981' : '#ef4444';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(0, 0, a.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      // Inner ring
      ctx.strokeStyle = a.isCorrect ? 'rgba(52, 211, 153, 0.4)' : 'rgba(248, 113, 113, 0.4)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(0, 0, a.radius - 8, 0, Math.PI * 2);
      ctx.stroke();

      // Word Text
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 15px "Segoe UI", Roboto, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(a.text, 0, 0);

      ctx.restore();
    });

    // 5. Particles
    this.particles.forEach(p => {
      ctx.save();
      ctx.fillStyle = p.color;
      ctx.globalAlpha = p.life / p.maxLife;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 6. Player Spaceship
    this.drawShip(ctx, this.playerX, this.playerY);
  }

  private drawShip(ctx: CanvasRenderingContext2D, x: number, y: number) {
    ctx.save();
    ctx.translate(x, y);

    // Thruster flame
    ctx.fillStyle = '#f59e0b';
    ctx.shadowColor = '#d97706';
    ctx.shadowBlur = 10;
    ctx.beginPath();
    ctx.moveTo(-8, 18);
    ctx.lineTo(0, 30 + Math.random() * 8);
    ctx.lineTo(8, 18);
    ctx.closePath();
    ctx.fill();
    ctx.shadowBlur = 0;

    // Ship Hull (Cyan & White Sleek Fighter)
    ctx.fillStyle = '#0284c7';
    ctx.beginPath();
    ctx.moveTo(0, -26);
    ctx.lineTo(24, 18);
    ctx.lineTo(0, 10);
    ctx.lineTo(-24, 18);
    ctx.closePath();
    ctx.fill();

    // Wings & Cockpit
    ctx.fillStyle = '#38bdf8';
    ctx.beginPath();
    ctx.moveTo(0, -14);
    ctx.lineTo(6, 6);
    ctx.lineTo(-6, 6);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
  }

  private drawStartScreen() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    this.render();

    ctx.fillStyle = 'rgba(9, 13, 22, 0.7)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🚀 Space Word Defender', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#94a3b8';
    ctx.fillText('Move Left & Right • Space to Fire Lasers!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText('Shoot the correct answer alien pod', canvas.width / 2, canvas.height / 2 + 15);
    ctx.restore();
  }
}
