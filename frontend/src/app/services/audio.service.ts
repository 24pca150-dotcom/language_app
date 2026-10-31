import { Injectable } from '@angular/core';
import { Howl } from 'howler';

@Injectable({
  providedIn: 'root'
})
export class AudioService {
  private successSound: Howl;
  private errorSound: Howl;
  private currentPlayingAudio: HTMLAudioElement | null = null;

  private voices: SpeechSynthesisVoice[] = [];
  private speechTimeout: any = null;

  constructor() {
    this.initVoices();

    // Initialize Howler instances
    this.successSound = new Howl({
      src: ['/assets/audio/success.mp3'],
      volume: 0.5,
      onloaderror: () => console.warn('Success audio file not found, fallback to synthesis.'),
      onplayerror: () => console.warn('Error playing success sound.')
    });

    this.errorSound = new Howl({
      src: ['/assets/audio/error.mp3'],
      volume: 0.5,
      onloaderror: () => console.warn('Error audio file not found, fallback to synthesis.'),
      onplayerror: () => console.warn('Error playing error sound.')
    });
  }

  private initVoices(): void {
    if (typeof window !== 'undefined' && window.speechSynthesis) {
      this.voices = window.speechSynthesis.getVoices();
      window.speechSynthesis.onvoiceschanged = () => {
        this.voices = window.speechSynthesis.getVoices();
      };
    }
  }

  getBestVoice(langPrefix: string = 'en'): SpeechSynthesisVoice | null {
    if (typeof window === 'undefined' || !window.speechSynthesis) return null;
    if (this.voices.length === 0) {
      this.voices = window.speechSynthesis.getVoices();
    }
    const matching = this.voices.filter(v => v.lang.toLowerCase().startsWith(langPrefix.toLowerCase()));
    if (matching.length === 0) return null;

    const getScore = (name: string, lang: string): number => {
      let score = 0;
      const lower = name.toLowerCase();
      if (lower.includes('natural') || lower.includes('neural')) score += 100;
      if (lower.includes('online')) score += 50;
      if (lower.includes('google')) score += 45;
      if (lower.includes('samantha') || lower.includes('jenny') || lower.includes('aria') || lower.includes('zira') || lower.includes('siri')) score += 35;
      if (lower.includes('us') || lang.toLowerCase().includes('en-us') || lang.toLowerCase().includes('en-gb')) score += 25;
      if (lower.includes('david')) score += 15;
      return score;
    };

    return matching.reduce((best, curr) => {
      return getScore(curr.name, curr.lang) > getScore(best.name, best.lang) ? curr : best;
    }, matching[0]);
  }

  playSuccess(speechText: string = "Super!") {
    this.stopAll();
    if (this.successSound.state() === 'loaded') {
      this.successSound.play();
    } else {
      this.synthesizeSuccess();
    }
    this.speak(speechText);
  }

  playSuccessSoundOnly() {
    this.stopAll();
    if (this.successSound.state() === 'loaded') {
      this.successSound.play();
    } else {
      this.synthesizeSuccess();
    }
  }

  playError(speechText: string = "Wrong!") {
    this.stopAll();
    if (this.errorSound.state() === 'loaded') {
      this.errorSound.play();
    } else {
      this.synthesizeError();
    }
    this.speak(speechText);
  }

  speak(text: string, options?: { rate?: number; pitch?: number; lang?: string; onEnd?: () => void; onError?: () => void }) {
    if (typeof window === 'undefined' || !window.speechSynthesis) {
      if (options?.onError) options.onError();
      return;
    }

    this.stopAll();

    const cleanText = text.trim();
    if (!cleanText) {
      if (options?.onEnd) options.onEnd();
      return;
    }

    // Small delay ensures Chrome cancel() completes cleanly before starting new utterance
    this.speechTimeout = setTimeout(() => {
      try {
        const utterance = new SpeechSynthesisUtterance(cleanText);
        const lang = options?.lang || 'en-US';
        utterance.lang = lang;
        utterance.rate = options?.rate ?? 0.88;
        utterance.pitch = options?.pitch ?? 1.0;

        const bestVoice = this.getBestVoice(lang.split('-')[0]);
        if (bestVoice) {
          utterance.voice = bestVoice;
        }

        utterance.onend = () => {
          if (options?.onEnd) options.onEnd();
        };

        utterance.onerror = (e) => {
          console.warn('SpeechSynthesis error:', e);
          if (options?.onError) options.onError();
        };

        window.speechSynthesis.speak(utterance);
      } catch (err) {
        console.warn('Speech failed:', err);
        if (options?.onError) options.onError();
      }
    }, 40);
  }

  speakWordWithSpelling(wordOrPhrase: string, onEnd?: () => void, onError?: () => void) {
    if (!wordOrPhrase || !wordOrPhrase.trim()) {
      if (onEnd) onEnd();
      return;
    }

    const clean = wordOrPhrase.trim();
    const words = clean.split(/\s+/);

    // If single word or short 2-word phrase, pronounce word, spell each letter clearly, then pronounce word again!
    if (words.length <= 2 && clean.length <= 16) {
      const letters = clean.replace(/[^a-zA-Z]/g, '').toUpperCase().split('');
      if (letters.length > 0) {
        // e.g. "celery. C, E, L, E, R, Y. celery."
        const spelledLetters = letters.join(', ');
        const speechText = `${clean}... ${spelledLetters}... ${clean}.`;
        this.speak(speechText, {
          rate: 0.82,
          pitch: 1.0,
          onEnd,
          onError
        });
        return;
      }
    }

    this.speak(clean, {
      rate: 0.88,
      pitch: 1.0,
      onEnd,
      onError
    });
  }

  playAudioUrl(url: string, fallbackText?: string, onEnd?: () => void) {
    this.stopAll();

    this.currentPlayingAudio = new Audio(url);
    this.currentPlayingAudio.play().catch(err => {
      console.warn('Audio URL playback failed:', err);
      if (fallbackText) {
        this.speakWordWithSpelling(fallbackText, onEnd);
      } else if (onEnd) {
        onEnd();
      }
    });

    this.currentPlayingAudio.onended = () => {
      if (this.currentPlayingAudio?.src === url) {
        this.currentPlayingAudio = null;
      }
      if (onEnd) onEnd();
    };
  }

  stopAll() {
    if (this.speechTimeout) {
      clearTimeout(this.speechTimeout);
      this.speechTimeout = null;
    }
    if (this.currentPlayingAudio) {
      try {
        this.currentPlayingAudio.pause();
      } catch (e) {}
      this.currentPlayingAudio = null;
    }
    if (typeof window !== 'undefined' && window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }
  }

  // Fallback Audio Synthesizer (No MP3 required!)
  public synthesizeSuccess() {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(523.25, ctx.currentTime); // C5
      osc.frequency.exponentialRampToValueAtTime(1046.50, ctx.currentTime + 0.1); // C6
      
      gain.gain.setValueAtTime(0, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0.5, ctx.currentTime + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
      
      osc.connect(gain);
      gain.connect(ctx.destination);
      
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.5);
    } catch (e) {}
  }

  public synthesizeError() {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(150, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(100, ctx.currentTime + 0.3);
      
      gain.gain.setValueAtTime(0, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0.5, ctx.currentTime + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
      
      osc.connect(gain);
      gain.connect(ctx.destination);
      
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.3);
    } catch (e) {}
  }

  // 🚗 CAR RACER: Authentic Engine Acceleration / Rev Sound
  public playCarEngineSound(): void {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const now = ctx.currentTime;

      // Engine fundamental (Sawtooth)
      const osc1 = ctx.createOscillator();
      osc1.type = 'sawtooth';
      osc1.frequency.setValueAtTime(80, now);
      osc1.frequency.exponentialRampToValueAtTime(260, now + 0.28);
      osc1.frequency.exponentialRampToValueAtTime(190, now + 0.45);

      // Sub-bass body rumble (Triangle)
      const osc2 = ctx.createOscillator();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(50, now);
      osc2.frequency.exponentialRampToValueAtTime(130, now + 0.28);

      // Lowpass filter to give deep exhaust tone
      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(400, now);
      filter.frequency.linearRampToValueAtTime(950, now + 0.25);
      filter.frequency.linearRampToValueAtTime(500, now + 0.45);

      // Volume envelope
      const gain = ctx.createGain();
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.24, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.45);

      osc1.connect(filter);
      osc2.connect(filter);
      filter.connect(gain);
      gain.connect(ctx.destination);

      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.45);
      osc2.stop(now + 0.45);
    } catch (e) {}
  }

  // 🗡️ FRUIT/WORD NINJA: Sharp Katana / Knife Blade Slice Swish Sound
  public playKnifeSliceSound(): void {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const now = ctx.currentTime;

      // Fast descending blade whistle (Sine/Triangle)
      const osc = ctx.createOscillator();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(2600, now);
      osc.frequency.exponentialRampToValueAtTime(320, now + 0.12);

      // Metal slice filter
      const filter = ctx.createBiquadFilter();
      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(2200, now);
      filter.frequency.exponentialRampToValueAtTime(600, now + 0.12);
      filter.Q.value = 3.5;

      const gain = ctx.createGain();
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.35, now + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.12);
    } catch (e) {}
  }

  // 🐦 FLAPPY BIRD: Wing Flutter & Chirp Sound
  public playBirdFlapSound(): void {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const now = ctx.currentTime;

      // Wing stroke flutter
      const osc = ctx.createOscillator();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(160, now);
      osc.frequency.linearRampToValueAtTime(360, now + 0.05);
      osc.frequency.exponentialRampToValueAtTime(130, now + 0.14);

      // Soft air puff filter
      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(700, now);

      const gain = ctx.createGain();
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.28, now + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.14);
    } catch (e) {}
  }

  // 🎈 BALLOON POP: Crisp Elastic Burst / Pop Sound
  public playBalloonPopSound(): void {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const now = ctx.currentTime;

      // Fast snap burst
      const osc = ctx.createOscillator();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(950, now);
      osc.frequency.exponentialRampToValueAtTime(70, now + 0.06);

      // Thump body
      const thump = ctx.createOscillator();
      thump.type = 'sine';
      thump.frequency.setValueAtTime(140, now);
      thump.frequency.exponentialRampToValueAtTime(45, now + 0.08);

      const gain = ctx.createGain();
      gain.gain.setValueAtTime(0.4, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

      const thumpGain = ctx.createGain();
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
    } catch (e) {}
  }

  // ✨ MCQ / QUIZ: Crisp Celebratory Ding & Chime Sound for Correct Answer
  public playMcqCorrectSound(): void {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const now = ctx.currentTime;

      // Sparkling 3-note harmonic arpeggio (C6, E6, G6)
      const notes = [
        { freq: 1046.50, delay: 0.00 }, // C6
        { freq: 1318.51, delay: 0.05 }, // E6
        { freq: 1567.98, delay: 0.11 }  // G6
      ];

      notes.forEach(({ freq, delay }) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + delay);

        // Warm bell decay
        gain.gain.setValueAtTime(0.001, now + delay);
        gain.gain.linearRampToValueAtTime(0.25, now + delay + 0.015);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + delay + 0.42);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start(now + delay);
        osc.stop(now + delay + 0.42);
      });
    } catch (e) {}
  }

  // ❌ Soft wrong answer buzz
  public playWrongAnswerSound(): void {
    this.synthesizeError();
  }
}
