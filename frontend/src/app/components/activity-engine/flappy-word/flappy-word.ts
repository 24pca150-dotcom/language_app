import { Component, Input, Output, EventEmitter, OnInit, OnDestroy, ViewChild, ElementRef, HostListener, signal } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface FlappyGateOption {
  text: string;
  isCorrect: boolean;
}

export interface FlappyGateWave {
  question: string;
  topOption: FlappyGateOption;
  bottomOption: FlappyGateOption;
  explanation?: string;
}

export interface FlappyWordData {
  id?: number;
  type?: string;
  title?: string;
  question?: string;
  speed?: 'gentle' | 'normal' | 'fast';
  waves?: FlappyGateWave[];
  options?: any[];
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

@Component({
  selector: 'app-activity-flappy-word',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './flappy-word.html',
  styleUrls: ['./flappy-word.css']
})
export class FlappyWordComponent implements OnInit, OnDestroy {
  @Input() activity: FlappyWordData | null = null;
  @Input() showFeedback: boolean = true;

  @Output() answered = new EventEmitter<{
    isCorrect: boolean;
    score: number;
    total: number;
    accuracy: number;
  }>();

  @ViewChild('flappyCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;

  // Game Signals
  gameState = signal<'start' | 'playing' | 'gameover' | 'victory'>('start');
  score = signal<number>(0);
  lives = signal<number>(3);
  currentWaveIndex = signal<number>(0);
  totalWaves = signal<number>(1);
  currentPrompt = signal<string>('Fly through the correct word cloud!');
  soundEnabled = signal<boolean>(true);
  Math = Math;

  // Audio Context (Synth)
  private audioCtx: AudioContext | null = null;

  // Animation & Loop
  private animFrameId: number | null = null;
  private lastTime: number = 0;

  // Bird Physics
  birdX: number = 85;
  birdY: number = 280;
  birdVy: number = 0;
  birdAngle: number = 0;
  private gravity: number = 700;
  private flapStrength: number = -260;

  // Cloud Gates
  wavesData: FlappyGateWave[] = [];
  gateX: number = 520;
  gateSpeed: number = 180;
  gatePassed: boolean = false;
  correctHits: number = 0;
  wrongHits: number = 0;

  // Visuals
  private particles: Particle[] = [];
  private bgClouds: { x: number; y: number; size: number; speed: number }[] = [];

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

  playSynthSound(type: 'flap' | 'correct' | 'crash' | 'win') {
    if (!this.soundEnabled()) return;
    this.initAudio();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    try {
      if (type === 'flap') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(320, now);
        osc.frequency.exponentialRampToValueAtTime(140, now + 0.08);
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.08);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.08);
      } else if (type === 'correct') {
        [587.33, 739.99, 880].forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now + idx * 0.08);
          gain.gain.setValueAtTime(0.16, now + idx * 0.08);
          gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.08 + 0.25);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + idx * 0.08);
          osc.stop(now + idx * 0.08 + 0.25);
        });
      } else if (type === 'crash') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(160, now);
        osc.frequency.exponentialRampToValueAtTime(50, now + 0.3);
        gain.gain.setValueAtTime(0.25, now);
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
    this.wavesData = [];

    if (act?.waves && act.waves.length > 0) {
      this.wavesData = JSON.parse(JSON.stringify(act.waves));
    } else if (act?.options && act.options.length >= 2) {
      this.wavesData = [{
        question: act.question || act.title || 'Fly into the correct cloud gate!',
        topOption: { text: act.options[0].text || '', isCorrect: !!act.options[0].isCorrect },
        bottomOption: { text: act.options[1].text || '', isCorrect: !!act.options[1].isCorrect }
      }];
    } else {
      this.wavesData = [
        {
          question: "Fly to the Past Tense of 'Sing':",
          topOption: { text: 'Sang', isCorrect: true },
          bottomOption: { text: 'Singed', isCorrect: false }
        },
        {
          question: "Choose the Synonym of 'Huge':",
          topOption: { text: 'Tiny', isCorrect: false },
          bottomOption: { text: 'Giant', isCorrect: true }
        },
        {
          question: "Pick the Correct Plural of 'Child':",
          topOption: { text: 'Children', isCorrect: true },
          bottomOption: { text: 'Childs', isCorrect: false }
        }
      ];
    }

    if (act?.speed === 'gentle') {
      this.gateSpeed = 150;
      this.gravity = 600;
      this.flapStrength = -240;
    } else if (act?.speed === 'fast') {
      this.gateSpeed = 220;
      this.gravity = 800;
      this.flapStrength = -280;
    } else {
      this.gateSpeed = 180;
      this.gravity = 700;
      this.flapStrength = -260;
    }

    this.totalWaves.set(this.wavesData.length);
  }

  private initCanvas() {
    const canvas = this.canvasRef.nativeElement;
    canvas.width = 440;
    canvas.height = 580;

    // Generate background floating clouds
    this.bgClouds = [];
    for (let i = 0; i < 6; i++) {
      this.bgClouds.push({
        x: Math.random() * canvas.width,
        y: 40 + Math.random() * (canvas.height - 180),
        size: 30 + Math.random() * 40,
        speed: 20 + Math.random() * 30
      });
    }

    this.drawStartScreen();
  }

  startGame() {
    this.initAudio();
    this.gameState.set('playing');
    this.score.set(0);
    this.lives.set(3);
    this.currentWaveIndex.set(0);
    this.correctHits = 0;
    this.wrongHits = 0;
    this.birdY = 280;
    this.birdVy = 0;
    this.birdAngle = 0;
    this.particles = [];
    this.spawnGate(0);
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
    if (e.key === ' ' || e.key === 'ArrowUp' || e.key.toLowerCase() === 'w') {
      e.preventDefault();
      this.flap();
    }
  }

  onCanvasClick() {
    if (this.gameState() === 'playing') {
      this.flap();
    }
  }

  flap() {
    this.birdVy = this.flapStrength;
    this.playSynthSound('flap');
    this.addFeatherParticles();
  }

  private spawnGate(waveIdx: number) {
    if (waveIdx >= this.wavesData.length) {
      this.triggerVictory();
      return;
    }
    this.currentWaveIndex.set(waveIdx);
    this.currentPrompt.set(this.wavesData[waveIdx].question);
    this.gateX = this.canvasRef.nativeElement.width + 60;
    this.gatePassed = false;
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

    // Bird physics
    this.birdVy += this.gravity * dt;
    this.birdY += this.birdVy * dt;
    this.birdAngle = Math.min(Math.PI / 4, Math.max(-Math.PI / 4, this.birdVy * 0.002));

    // Floor / Ceiling check
    if (this.birdY < 24) {
      this.birdY = 24;
      this.birdVy = 0;
    } else if (this.birdY > canvas.height - 40) {
      // Hit ground
      this.birdY = canvas.height - 40;
      this.handleCrash();
      return;
    }

    // Move bg clouds
    this.bgClouds.forEach(c => {
      c.x -= c.speed * dt;
      if (c.x < -100) c.x = canvas.width + 100;
    });

    // Move Gate
    this.gateX -= this.gateSpeed * dt;

    // Check collision with Gate
    // Gate has Top Cloud (Y: 130) and Bottom Cloud (Y: 370)
    const birdR = 18;
    const gateW = 80;

    // Check if bird is within horizontal slice of gate
    if (this.birdX + birdR >= this.gateX - gateW / 2 && this.birdX - birdR <= this.gateX + gateW / 2) {
      if (!this.gatePassed) {
        this.gatePassed = true;
        const wave = this.wavesData[this.currentWaveIndex()];

        // Top cloud zone: Y < 290
        // Bottom cloud zone: Y >= 290
        const isTop = this.birdY < 290;
        const chosen = isTop ? wave.topOption : wave.bottomOption;

        if (chosen.isCorrect) {
          // CORRECT GATE!
          this.correctHits++;
          this.score.update(s => s + 100);
          this.playSynthSound('correct');
          this.addExplosionParticles(this.birdX, this.birdY, '#10b981', 20);
        } else {
          // WRONG GATE!
          this.handleCrash();
          return;
        }
      }
    }

    // Gate exited left side of screen
    if (this.gateX < -100) {
      this.spawnGate(this.currentWaveIndex() + 1);
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

  private handleCrash() {
    this.wrongHits++;
    this.lives.update(l => Math.max(0, l - 1));
    this.playSynthSound('crash');
    this.addExplosionParticles(this.birdX, this.birdY, '#ef4444', 30);

    if (this.lives() <= 0) {
      this.triggerGameOver();
      return;
    }

    // Reset position and jump to next gate
    this.birdY = 280;
    this.birdVy = 0;
    setTimeout(() => {
      if (this.gameState() === 'playing') {
        this.spawnGate(this.currentWaveIndex() + 1);
      }
    }, 800);
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
    const total = this.wavesData.length;
    const accuracy = total > 0 ? Math.round((this.correctHits / total) * 100) : 0;
    this.answered.emit({
      isCorrect: won && this.correctHits >= Math.ceil(total * 0.6),
      score: this.score(),
      total: total,
      accuracy: accuracy
    });
  }

  private addFeatherParticles() {
    for (let i = 0; i < 4; i++) {
      this.particles.push({
        x: this.birdX - 14,
        y: this.birdY + (Math.random() - 0.5) * 10,
        vx: -40 - Math.random() * 30,
        vy: 20 + Math.random() * 30,
        color: '#fef08a',
        radius: 2.5,
        life: 0.35,
        maxLife: 0.35
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
        radius: 3 + Math.random() * 3,
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

    // 1. Sky Gradient
    const skyGrad = ctx.createLinearGradient(0, 0, 0, canvas.height);
    skyGrad.addColorStop(0, '#0284c7');
    skyGrad.addColorStop(0.6, '#38bdf8');
    skyGrad.addColorStop(1, '#bae6fd');
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // 2. Background Floating Clouds
    ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
    this.bgClouds.forEach(c => {
      ctx.beginPath();
      ctx.arc(c.x, c.y, c.size, 0, Math.PI * 2);
      ctx.arc(c.x + c.size * 0.6, c.y - c.size * 0.3, c.size * 0.7, 0, Math.PI * 2);
      ctx.arc(c.x + c.size * 1.2, c.y, c.size * 0.8, 0, Math.PI * 2);
      ctx.fill();
    });

    // 3. Cloud Gates (Top Gate & Bottom Gate)
    if (this.currentWaveIndex() < this.wavesData.length) {
      const wave = this.wavesData[this.currentWaveIndex()];
      // Top Gate (Y: 135)
      this.drawCloudGate(ctx, this.gateX, 135, wave.topOption.text, wave.topOption.isCorrect);
      // Bottom Gate (Y: 425)
      this.drawCloudGate(ctx, this.gateX, 425, wave.bottomOption.text, wave.bottomOption.isCorrect);
    }

    // 4. Ground
    ctx.fillStyle = '#15803d';
    ctx.fillRect(0, canvas.height - 24, canvas.width, 24);
    ctx.fillStyle = '#4ade80';
    ctx.fillRect(0, canvas.height - 24, canvas.width, 5);

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

    // 6. Bird Sprite (Cute Yellow Aviator Bird)
    this.drawBird(ctx, this.birdX, this.birdY, this.birdAngle);
  }

  private drawCloudGate(ctx: CanvasRenderingContext2D, x: number, y: number, text: string, isCorrect: boolean) {
    ctx.save();
    ctx.translate(x, y);

    // Cloud shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
    ctx.beginPath();
    ctx.roundRect(-75, -45, 150, 90, 24);
    ctx.fill();

    // Cloud body
    ctx.fillStyle = isCorrect ? 'rgba(255, 255, 255, 0.95)' : 'rgba(241, 245, 249, 0.92)';
    ctx.strokeStyle = isCorrect ? '#10b981' : '#cbd5e1';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.roundRect(-70, -40, 140, 80, 20);
    ctx.fill();
    ctx.stroke();

    // Option text
    ctx.fillStyle = '#0f172a';
    ctx.font = 'bold 16px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, 0, 0);

    ctx.restore();
  }

  private drawBird(ctx: CanvasRenderingContext2D, x: number, y: number, angle: number) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);

    // Body (Bright Yellow)
    ctx.fillStyle = '#facc15';
    ctx.beginPath();
    ctx.arc(0, 0, 18, 0, Math.PI * 2);
    ctx.fill();

    // Wing
    ctx.fillStyle = '#eab308';
    ctx.beginPath();
    ctx.ellipse(-6, 2, 10, 6, -0.3, 0, Math.PI * 2);
    ctx.fill();

    // Eye
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(8, -5, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#0f172a';
    ctx.beginPath();
    ctx.arc(10, -5, 2.5, 0, Math.PI * 2);
    ctx.fill();

    // Beak
    ctx.fillStyle = '#f97316';
    ctx.beginPath();
    ctx.moveTo(14, -2);
    ctx.lineTo(24, 2);
    ctx.lineTo(14, 6);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
  }

  private drawStartScreen() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    this.render();

    ctx.fillStyle = 'rgba(15, 23, 42, 0.65)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 22px "Segoe UI", Roboto, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🕊️ Flappy Word Flight', canvas.width / 2, canvas.height / 2 - 35);

    ctx.font = '13px "Segoe UI", Roboto, sans-serif';
    ctx.fillStyle = '#94a3b8';
    ctx.fillText('Tap screen or press Space to flap wings!', canvas.width / 2, canvas.height / 2 - 8);
    ctx.fillText('Fly through the correct word cloud gate', canvas.width / 2, canvas.height / 2 + 15);
    ctx.restore();
  }
}
