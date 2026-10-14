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
  private synthesizeSuccess() {
    try {
      const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
      const ctx = new AudioContext();
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

  private synthesizeError() {
    try {
      const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
      const ctx = new AudioContext();
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
}
