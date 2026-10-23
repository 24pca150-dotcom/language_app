import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, HostListener, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface CarRacerOption {
  text: string;
  isCorrect: boolean;
}

export interface CarRacerRound {
  question: string;
  options: CarRacerOption[]; // 3 options: [0] Left, [1] Middle, [2] Right
  explanation?: string;
}

export interface CarRacerData {
  id?: number;
  type?: string;
  title?: string;
  question?: string;
  speed?: 'normal' | 'fast' | 'turbo';
  rounds?: CarRacerRound[];
  options?: any[]; // fallback if simple MCQ-style data passed
  explanation?: string;
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

interface FloatingText {
  x: number;
  y: number;
  text: string;
  color: string;
  life: number;
  scale: number;
}

@Component({
  selector: 'app-activity-car-racer',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './car-racer.html',
  styleUrls: ['./car-racer.css']
})
export class CarRacerComponent implements OnInit, OnDestroy {
  @Input() activity: CarRacerData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{
    isCorrect: boolean;
    score: number;
    total: number;
    accuracy: number;
  }>();

  @ViewChild('gameCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;

  // Game Signals
  gameState = signal<'start' | 'playing' | 'paused' | 'gameover' | 'victory'>('start');
  score = signal<number>(0);
  lives = signal<number>(3);
  currentRoundIndex = signal<number>(0);
  totalRounds = signal<number>(1);
  streak = signal<number>(0);
  currentQuestion = signal<string>('');
  soundEnabled = signal<boolean>(true);
  Math = Math;

  // Audio Context (Web Audio Synth - zero external dependencies)
  private audioCtx: AudioContext | null = null;

  // Animation & Physics
  private animFrameId: number | null = null;
  private lastTime: number = 0;
  private roadOffset: number = 0;
  private baseSpeed: number = 240; // pixels per sec
  private currentSpeed: number = 240;
  private nitroActive: boolean = false;
  private nitroTimer: number = 0;

  // Lanes: 3 lanes (0: Left, 1: Middle, 2: Right)
  currentLane: number = 1; // starts in middle
  targetLane: number = 1;
  playerCarX: number = 0;
  playerCarY: number = 0;

  // Wave / Oncoming targets
  roundsData: CarRacerRound[] = [];
  waveActive: boolean = false;
  waveY: number = -120; // starts above screen
  correctHits: number = 0;
  wrongHits: number = 0;

  // Visual effects
  private particles: Particle[] = [];
  private floatingTexts: FloatingText[] = [];
  private screenShake: number = 0;
  private flashColor: string | null = null;
  private flashTimer: number = 0;

  ngOnInit() {
    this.parseRounds();
    this.initCanvas();
  }

  ngOnDestroy() {
    this.stopGameLoop();
    if (this.audioCtx) {
      try { this.audioCtx.close(); } catch (e) {}
    }
  }

  // --- AUDIO SYNTHESIS ---
  private initAudio() {
    if (!this.audioCtx) {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioContextClass) {
        this.audioCtx = new AudioContextClass();
      }
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  playSynthSound(type: 'lane' | 'correct' | 'wrong' | 'nitro' | 'win') {
    if (!this.soundEnabled()) return;
    this.initAudio();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    try {
      if (type === 'lane') {
        // Quick swish
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(220, now);
        osc.frequency.exponentialRampToValueAtTime(440, now + 0.08);
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.08);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.08);
      } else if (type === 'correct') {
        // Joyful 2-tone arpeggio
        [523.25, 659.25, 783.99].forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now + idx * 0.07);
          gain.gain.setValueAtTime(0.18, now + idx * 0.07);
          gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.07 + 0.2);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + idx * 0.07);
          osc.stop(now + idx * 0.07 + 0.2);
        });
      } else if (type === 'wrong') {
        // Low crash buzz / tire screech
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(140, now);
        osc.frequency.exponentialRampToValueAtTime(60, now + 0.25);
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
      } else if (type === 'nitro') {
        // Rising power whoosh
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(300, now);
        osc.frequency.exponentialRampToValueAtTime(800, now + 0.2);
        gain.gain.setValueAtTime(0.15, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.2);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.2);
      } else if (type === 'win') {
        // Fanfare chord
        [523.25, 659.25, 783.99, 1046.5].forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(freq, now + idx * 0.09);
          gain.gain.setValueAtTime(0.2, now + idx * 0.09);
          gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.09 + 0.35);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + idx * 0.09);
          osc.stop(now + idx * 0.09 + 0.35);
        });
      }
    } catch (e) {
      // Audio playback suppressed or unallowed
    }
  }

  // --- DATA SETUP ---
  private parseRounds() {
    this.roundsData = [];
    const act = this.activity;

    if (act?.rounds && act.rounds.length > 0) {
      this.roundsData = JSON.parse(JSON.stringify(act.rounds));
    } else if (act?.options && act.options.length >= 2) {
      // Auto adapt standard MCQ options into 3 lanes
      const opts: CarRacerOption[] = act.options.slice(0, 3).map((o: any) => ({
        text: o.text || o.option_text || '',
        isCorrect: !!(o.isCorrect || o.is_correct)
      }));
      // Pad to 3 if only 2 options
      while (opts.length < 3) {
        opts.push({ text: '---', isCorrect: false });
      }
      this.roundsData = [{
        question: act.question || act.title || 'Steer into the correct answer lane!',
        options: opts,
        explanation: act.explanation
      }];
    } else {
      // Default demo round matching language learning
      this.roundsData = [
        {
          question: "Find the Past Tense of 'Drive':",
          options: [
            { text: "Drove", isCorrect: true },
            { text: "Drived", isCorrect: false },
            { text: "Driven", isCorrect: false }
          ],
          explanation: "'Drove' is the correct simple past tense of 'Drive'."
        },
        {
          question: "Choose the Antonym of 'Dangerous':",
          options: [
            { text: "Risky", isCorrect: false },
            { text: "Safe", isCorrect: true },
            { text: "Violent", isCorrect: false }
          ],
          explanation: "'Safe' is the opposite of 'Dangerous'."
        },
        {
          question: "Identify the Adjective in: 'Fast sports car':",
          options: [
            { text: "Car", isCorrect: false },
            { text: "Sports", isCorrect: false },
            { text: "Fast", isCorrect: true }
          ],
          explanation: "'Fast' is an adjective describing the car."
        }
      ];
    }

    // Set speed
    if (act?.speed === 'fast') this.baseSpeed = 300;
    else if (act?.speed === 'turbo') this.baseSpeed = 380;
    else this.baseSpeed = 240;
    this.currentSpeed = this.baseSpeed;

    this.totalRounds.set(this.roundsData.length);
  }

  // --- CANVAS & CONTROLS ---
  private initCanvas() {
    const canvas = this.canvasRef.nativeElement;
    // Set internal resolution matching vertical portrait layout
    canvas.width = 440;
    canvas.height = 580;
    this.playerCarY = canvas.height - 75;
    this.playerCarX = this.getLaneCenterX(1);
    this.drawInitialScreen();
  }

  startGame() {
    this.initAudio();
    this.gameState.set('playing');
    this.score.set(0);
    this.lives.set(3);
    this.streak.set(0);
    this.currentRoundIndex.set(0);
    this.correctHits = 0;
    this.wrongHits = 0;
    this.currentSpeed = this.baseSpeed;
    this.targetLane = 1;
    this.currentLane = 1;
    this.playerCarX = this.getLaneCenterX(1);
    this.particles = [];
    this.floatingTexts = [];
    this.spawnWave(0);
    this.startGameLoop();
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
      e.preventDefault();
      this.moveLane(-1);
    } else if (e.key === 'ArrowRight' || e.key.toLowerCase() === 'd') {
      e.preventDefault();
      this.moveLane(1);
    } else if (e.key === 'ArrowUp' || e.key.toLowerCase() === 'w' || e.key === ' ') {
      e.preventDefault();
      this.activateNitro();
    }
  }

  moveLane(delta: number) {
    const newLane = Math.max(0, Math.min(2, this.targetLane + delta));
    if (newLane !== this.targetLane) {
      this.targetLane = newLane;
      this.playSynthSound('lane');
      this.addSkidParticles();
    }
  }

  activateNitro() {
    if (this.nitroActive) return;
    this.nitroActive = true;
    this.nitroTimer = 1.2; // 1.2 seconds of nitro
    this.currentSpeed = this.baseSpeed * 1.6;
    this.playSynthSound('nitro');
    this.addFloatingText('NITRO BOOST! 🔥', this.playerCarX, this.playerCarY - 30, '#f59e0b');
  }

  // --- GAME LOOP ---
  private startGameLoop() {
    this.stopGameLoop();
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

  private stopGameLoop() {
    if (this.animFrameId !== null) {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
  }

  // --- UPDATE LOGIC ---
  private update(dt: number) {
    // Road scroll
    this.roadOffset = (this.roadOffset + this.currentSpeed * dt) % 80;

    // Smooth Car Steering (Lerp)
    const targetX = this.getLaneCenterX(this.targetLane);
    this.playerCarX += (targetX - this.playerCarX) * Math.min(1, dt * 14);

    // Nitro Timer
    if (this.nitroActive) {
      this.nitroTimer -= dt;
      this.addExhaustParticles();
      if (this.nitroTimer <= 0) {
        this.nitroActive = false;
        this.currentSpeed = this.baseSpeed;
      }
    } else {
      // Normal exhaust
      if (Math.random() < 0.3) {
        this.addExhaustParticles();
      }
    }

    // Screen Shake & Flash decay
    if (this.screenShake > 0) {
      this.screenShake = Math.max(0, this.screenShake - dt * 25);
    }
    if (this.flashTimer > 0) {
      this.flashTimer -= dt;
      if (this.flashTimer <= 0) this.flashColor = null;
    }

    // Update Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.life <= 0) this.particles.splice(i, 1);
    }

    // Update Floating Texts
    for (let i = this.floatingTexts.length - 1; i >= 0; i--) {
      const t = this.floatingTexts[i];
      t.y -= 35 * dt;
      t.life -= dt;
      if (t.life <= 0) this.floatingTexts.splice(i, 1);
    }

    // Move oncoming wave
    if (this.waveActive) {
      this.waveY += this.currentSpeed * dt;

      // Collision Check: Player Y is around 570
      const collisionY = this.playerCarY - 10;
      if (this.waveY >= collisionY && this.waveY <= collisionY + 45) {
        this.checkCollision();
      } else if (this.waveY > this.canvasRef.nativeElement.height + 60) {
        // Missed wave without collision -> treat as miss
        this.handleMissedWave();
      }
    }
  }

  private spawnWave(roundIndex: number) {
    if (roundIndex >= this.roundsData.length) {
      this.triggerVictory();
      return;
    }
    this.currentRoundIndex.set(roundIndex);
    const round = this.roundsData[roundIndex];
    this.currentQuestion.set(round.question);
    this.waveY = -120;
    this.waveActive = true;
  }

  private checkCollision() {
    this.waveActive = false; // hit registered
    const round = this.roundsData[this.currentRoundIndex()];
    // Closest lane to player
    const chosenLane = this.targetLane;
    const option = round.options[chosenLane];

    if (option && option.isCorrect) {
      // SUCCESS!
      this.correctHits++;
      const bonus = this.nitroActive ? 150 : 100;
      this.score.update(s => s + bonus);
      this.streak.update(st => st + 1);
      this.playSynthSound('correct');
      this.addExplosionParticles(this.playerCarX, this.playerCarY, '#10b981', 25);
      this.addFloatingText(`+${bonus} PERFECT! 🎯`, this.playerCarX, this.playerCarY - 30, '#10b981');
      this.flashScreen('rgba(16, 185, 129, 0.25)');

      // If streak >= 3, grant auto nitro
      if (this.streak() % 3 === 0) {
        this.activateNitro();
      }
    } else {
      // CRASH / WRONG!
      this.wrongHits++;
      this.streak.set(0);
      this.lives.update(l => Math.max(0, l - 1));
      this.playSynthSound('wrong');
      this.screenShake = 16;
      this.addExplosionParticles(this.playerCarX, this.playerCarY, '#ef4444', 35);
      this.addFloatingText('CRASH! 💥', this.playerCarX, this.playerCarY - 30, '#ef4444');
      this.flashScreen('rgba(239, 68, 68, 0.35)');

      if (this.lives() <= 0) {
        setTimeout(() => this.triggerGameOver(), 600);
        return;
      }
    }

    // Schedule next wave
    setTimeout(() => {
      if (this.gameState() === 'playing') {
        this.spawnWave(this.currentRoundIndex() + 1);
      }
    }, 1100);
  }

  private handleMissedWave() {
    this.waveActive = false;
    this.wrongHits++;
    this.streak.set(0);
    this.lives.update(l => Math.max(0, l - 1));
    this.playSynthSound('wrong');
    this.addFloatingText('MISSED! ⏱️', this.playerCarX, this.playerCarY - 30, '#f97316');

    if (this.lives() <= 0) {
      this.triggerGameOver();
      return;
    }

    setTimeout(() => {
      if (this.gameState() === 'playing') {
        this.spawnWave(this.currentRoundIndex() + 1);
      }
    }, 1000);
  }

  private triggerGameOver() {
    this.gameState.set('gameover');
    this.stopGameLoop();
    this.emitResult(false);
  }

  private triggerVictory() {
    this.gameState.set('victory');
    this.stopGameLoop();
    this.playSynthSound('win');
    this.emitResult(true);
  }

  private emitResult(won: boolean) {
    const total = this.roundsData.length;
    const accuracy = total > 0 ? Math.round((this.correctHits / total) * 100) : 0;
    this.answered.emit({
      isCorrect: won && this.correctHits >= Math.ceil(total * 0.6),
      score: this.score(),
      total: total,
      accuracy: accuracy
    });
  }

  // --- VISUAL EFFECTS HELPERS ---
  private addExhaustParticles() {
    const color = this.nitroActive ? '#3b82f6' : '#94a3b8';
    this.particles.push({
      x: this.playerCarX - 10 + (Math.random() * 20),
      y: this.playerCarY + 45,
      vx: (Math.random() - 0.5) * 20,
      vy: 120 + Math.random() * 80,
      color: color,
      radius: this.nitroActive ? 4 + Math.random() * 3 : 2 + Math.random() * 2,
      life: 0.35,
      maxLife: 0.35
    });
  }

  private addSkidParticles() {
    for (let i = 0; i < 6; i++) {
      this.particles.push({
        x: this.playerCarX - 12 + (Math.random() * 24),
        y: this.playerCarY + 40,
        vx: (Math.random() - 0.5) * 60,
        vy: 40 + Math.random() * 30,
        color: '#475569',
        radius: 2.5,
        life: 0.25,
        maxLife: 0.25
      });
    }
  }

  private addExplosionParticles(x: number, y: number, color: string, count: number) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 40 + Math.random() * 160;
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

  private addFloatingText(text: string, x: number, y: number, color: string) {
    this.floatingTexts.push({
      x: x,
      y: y,
      text: text,
      color: color,
      life: 1.0,
      scale: 1.2
    });
  }

  private flashScreen(color: string) {
    this.flashColor = color;
    this.flashTimer = 0.2;
  }

  private getRoadGeometry() {
    const canvas = this.canvasRef?.nativeElement;
    const canvasWidth = canvas ? canvas.width : 440;
    const roadWidth = 380;
    const roadLeft = (canvasWidth - roadWidth) / 2;
    const laneWidth = roadWidth / 3;
    return { roadLeft, roadWidth, laneWidth };
  }

  private getLaneCenterX(laneIndex: number): number {
    const { roadLeft, laneWidth } = this.getRoadGeometry();
    return roadLeft + laneWidth * laneIndex + laneWidth / 2;
  }

  // --- RENDERER (CANVAS) ---
  private render() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.save();

    // Screen Shake effect
    if (this.screenShake > 0) {
      const dx = (Math.random() - 0.5) * this.screenShake;
      const dy = (Math.random() - 0.5) * this.screenShake;
      ctx.translate(dx, dy);
    }

    // 1. Grass borders (Left and Right)
    ctx.fillStyle = '#2d8a39';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Grass texture accents
    ctx.fillStyle = '#25742f';
    for (let y = (this.roadOffset % 40) - 40; y < canvas.height; y += 40) {
      ctx.fillRect(8, y, 16, 12);
      ctx.fillRect(canvas.width - 24, y + 20, 16, 12);
    }

    // 2. Road Surface (Asphalt)
    const { roadLeft, roadWidth, laneWidth } = this.getRoadGeometry();
    const roadRight = roadLeft + roadWidth;

    // Asphalt gradient
    const roadGrad = ctx.createLinearGradient(roadLeft, 0, roadRight, 0);
    roadGrad.addColorStop(0, '#2d333b');
    roadGrad.addColorStop(0.5, '#373e47');
    roadGrad.addColorStop(1, '#2d333b');
    ctx.fillStyle = roadGrad;
    ctx.fillRect(roadLeft, 0, roadWidth, canvas.height);

    // 3. Race Track Curbs (Red and White alternating stripes on both sides)
    const curbWidth = 10;
    const stripeHeight = 24;
    for (let y = (this.roadOffset % (stripeHeight * 2)) - (stripeHeight * 2); y < canvas.height; y += stripeHeight) {
      const isRed = Math.floor((y - this.roadOffset) / stripeHeight) % 2 === 0;
      ctx.fillStyle = isRed ? '#dc2626' : '#ffffff';
      // Left curb
      ctx.fillRect(roadLeft - curbWidth, y, curbWidth, stripeHeight);
      // Right curb
      ctx.fillRect(roadRight, y, curbWidth, stripeHeight);
    }

    // 4. Lane Dividers
    // Divider 1 (between Left & Middle) - White dashed
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 4;
    ctx.setLineDash([28, 22]);
    ctx.lineDashOffset = -this.roadOffset;
    ctx.beginPath();
    ctx.moveTo(roadLeft + laneWidth, 0);
    ctx.lineTo(roadLeft + laneWidth, canvas.height);
    ctx.stroke();

    // Divider 2 (between Middle & Right) - White dashed
    ctx.beginPath();
    ctx.moveTo(roadLeft + laneWidth * 2, 0);
    ctx.lineTo(roadLeft + laneWidth * 2, canvas.height);
    ctx.stroke();
    ctx.setLineDash([]); // Reset line dash

    // Inner yellow shoulder line on right (like in photo)
    ctx.strokeStyle = '#eab308';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(roadRight - 4, 0);
    ctx.lineTo(roadRight - 4, canvas.height);
    ctx.stroke();

    // 5. Oncoming Wave (Cars & Floating Word Signs in each lane)
    if (this.waveActive && this.currentRoundIndex() < this.roundsData.length) {
      const round = this.roundsData[this.currentRoundIndex()];
      round.options.forEach((opt, idx) => {
        const laneX = this.getLaneCenterX(idx);
        const oncomingY = this.waveY;

        // Draw oncoming Car / Target
        if (opt.isCorrect) {
          // Correct Target: Blue/Gold Racing Sports Car + Star Glow
          this.drawSportsCar(ctx, laneX, oncomingY, '#2563eb', true);
        } else {
          // Wrong Target: Green Police Car with Siren (matching user's photo!)
          this.drawPoliceCar(ctx, laneX, oncomingY);
        }

        // Draw Floating Answer Tag above each oncoming car
        this.drawAnswerPlate(ctx, opt.text, laneX, oncomingY - 50, opt.isCorrect);
      });
    }

    // 6. Particles
    this.particles.forEach(p => {
      ctx.save();
      ctx.fillStyle = p.color;
      ctx.globalAlpha = p.life / p.maxLife;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 7. Player Car (Red Sports Car with stripes & spoiler)
    this.drawPlayerCar(ctx, this.playerCarX, this.playerCarY);

    // 8. Floating Texts
    this.floatingTexts.forEach(t => {
      ctx.save();
      ctx.font = 'bold 18px "Segoe UI", Roboto, sans-serif';
      ctx.fillStyle = t.color;
      ctx.textAlign = 'center';
      ctx.shadowColor = 'rgba(0,0,0,0.8)';
      ctx.shadowBlur = 6;
      ctx.fillText(t.text, t.x, t.y);
      ctx.restore();
    });

    // 9. Full Screen Flash (Green for correct, Red for crash)
    if (this.flashColor) {
      ctx.fillStyle = this.flashColor;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

    ctx.restore();
  }

  // --- SPRITE DRAWING HELPERS ---
  private drawPlayerCar(ctx: CanvasRenderingContext2D, x: number, y: number) {
    ctx.save();
    ctx.translate(x, y);

    // Car Shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.4)';
    ctx.beginPath();
    ctx.roundRect(-22, -38, 44, 82, 10);
    ctx.fill();

    // Main Body (Vibrant Red)
    const bodyGrad = ctx.createLinearGradient(-18, 0, 18, 0);
    bodyGrad.addColorStop(0, '#b91c1c');
    bodyGrad.addColorStop(0.5, '#ef4444');
    bodyGrad.addColorStop(1, '#991b1b');
    ctx.fillStyle = bodyGrad;
    ctx.beginPath();
    ctx.roundRect(-18, -36, 36, 76, 8);
    ctx.fill();

    // Racing White Stripes
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(-4, -36, 8, 76);

    // Windshield (Dark Glossy)
    ctx.fillStyle = '#0f172a';
    ctx.beginPath();
    ctx.roundRect(-13, -12, 26, 22, 4);
    ctx.fill();

    // Windshield reflection
    ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.fillRect(-10, -10, 5, 18);

    // Rear Window
    ctx.fillStyle = '#1e293b';
    ctx.beginPath();
    ctx.roundRect(-12, 18, 24, 10, 3);
    ctx.fill();

    // Headlights (Glowing Yellow/White)
    ctx.fillStyle = '#fef08a';
    ctx.shadowColor = '#facc15';
    ctx.shadowBlur = 10;
    ctx.fillRect(-15, -36, 7, 5);
    ctx.fillRect(8, -36, 7, 5);
    ctx.shadowBlur = 0;

    // Tail Lights (Red Glow)
    ctx.fillStyle = '#ef4444';
    ctx.shadowColor = '#dc2626';
    ctx.shadowBlur = 6;
    ctx.fillRect(-15, 38, 7, 4);
    ctx.fillRect(8, 38, 7, 4);
    ctx.shadowBlur = 0;

    // Rear Spoiler
    ctx.fillStyle = '#18181b';
    ctx.fillRect(-18, 34, 36, 5);

    ctx.restore();
  }

  private drawPoliceCar(ctx: CanvasRenderingContext2D, x: number, y: number) {
    ctx.save();
    ctx.translate(x, y);

    // Shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
    ctx.beginPath();
    ctx.roundRect(-20, -36, 40, 76, 8);
    ctx.fill();

    // Police Green Body (matching user's image!)
    const bodyGrad = ctx.createLinearGradient(-17, 0, 17, 0);
    bodyGrad.addColorStop(0, '#14532d');
    bodyGrad.addColorStop(0.5, '#16a34a');
    bodyGrad.addColorStop(1, '#14532d');
    ctx.fillStyle = bodyGrad;
    ctx.beginPath();
    ctx.roundRect(-17, -34, 34, 72, 8);
    ctx.fill();

    // White Racing Stripes on Sides (like user photo)
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(-15, -34, 3, 72);
    ctx.fillRect(12, -34, 3, 72);

    // "POLICE" text on roof
    ctx.font = 'bold 8px sans-serif';
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.fillText('POLICE', 0, -18);

    // Flashing Red & Blue Siren Bar
    const now = Date.now();
    const flash = Math.floor(now / 150) % 2 === 0;
    ctx.fillStyle = flash ? '#ef4444' : '#3b82f6';
    ctx.fillRect(-10, 0, 9, 6);
    ctx.fillStyle = flash ? '#3b82f6' : '#ef4444';
    ctx.fillRect(1, 0, 9, 6);

    // Windshield
    ctx.fillStyle = '#0f172a';
    ctx.beginPath();
    ctx.roundRect(-12, 10, 24, 16, 3);
    ctx.fill();

    ctx.restore();
  }

  private drawSportsCar(ctx: CanvasRenderingContext2D, x: number, y: number, color: string, isTarget: boolean) {
    ctx.save();
    ctx.translate(x, y);

    // Aura ring for correct target
    if (isTarget) {
      ctx.strokeStyle = '#10b981';
      ctx.lineWidth = 3;
      ctx.shadowColor = '#10b981';
      ctx.shadowBlur = 12;
      ctx.beginPath();
      ctx.arc(0, 0, 44, 0, Math.PI * 2);
      ctx.stroke();
      ctx.shadowBlur = 0;
    }

    // Shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
    ctx.beginPath();
    ctx.roundRect(-20, -36, 40, 76, 8);
    ctx.fill();

    // Blue/Gold Sports Body
    const bodyGrad = ctx.createLinearGradient(-17, 0, 17, 0);
    bodyGrad.addColorStop(0, '#1d4ed8');
    bodyGrad.addColorStop(0.5, '#3b82f6');
    bodyGrad.addColorStop(1, '#1d4ed8');
    ctx.fillStyle = bodyGrad;
    ctx.beginPath();
    ctx.roundRect(-17, -34, 34, 72, 8);
    ctx.fill();

    // Golden racing lightning bolt
    ctx.fillStyle = '#fbbf24';
    ctx.beginPath();
    ctx.moveTo(0, -20);
    ctx.lineTo(6, -8);
    ctx.lineTo(0, -6);
    ctx.lineTo(4, 6);
    ctx.lineTo(-6, -4);
    ctx.lineTo(0, -5);
    ctx.closePath();
    ctx.fill();

    // Windshield
    ctx.fillStyle = '#0f172a';
    ctx.beginPath();
    ctx.roundRect(-12, 10, 24, 16, 3);
    ctx.fill();

    ctx.restore();
  }

  private drawAnswerPlate(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, isCorrect: boolean) {
    ctx.save();
    ctx.font = 'bold 13px "Segoe UI", Roboto, sans-serif';
    const textMetrics = ctx.measureText(text);
    const boxW = Math.min(116, Math.max(74, textMetrics.width + 16));
    const boxH = 28;

    // Glowing background box
    ctx.fillStyle = isCorrect ? 'rgba(16, 185, 129, 0.95)' : 'rgba(30, 41, 59, 0.92)';
    ctx.strokeStyle = isCorrect ? '#34d399' : '#64748b';
    ctx.lineWidth = 2;
    ctx.shadowColor = 'rgba(0,0,0,0.5)';
    ctx.shadowBlur = 6;

    ctx.beginPath();
    ctx.roundRect(x - boxW / 2, y - boxH / 2, boxW, boxH, 6);
    ctx.fill();
    ctx.stroke();

    // Text label
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.shadowBlur = 0;
    ctx.fillText(text, x, y);

    ctx.restore();
  }

  private drawInitialScreen() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Render calm background road
    this.render();

    // Dim overlay
    ctx.fillStyle = 'rgba(15, 23, 42, 0.65)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Title & prompt
    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🏎️ Highway Racer', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#94a3b8';
    ctx.fillText('Steer into the correct answer lane!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText('Avoid police cars & obstacles', canvas.width / 2, canvas.height / 2 + 15);
    ctx.restore();
  }
}
