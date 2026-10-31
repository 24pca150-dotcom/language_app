import 'package:flutter/services.dart';

class GameAudioService {
  static bool soundEnabled = true;

  /// 🚗 Car Engine Acceleration / Rev Feedback
  static void playCarEngine() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 🚗 Car Nitro Turbo Surge
  static void playCarNitro() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 🗡️ Fruit / Word Ninja: Sharp Knife Blade Slice Swish
  static void playKnifeSlice() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 🐦 Flappy Bird: Wing Flutter & Flap
  static void playBirdFlap() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 🎈 Balloon Pop: Crisp Elastic Balloon Burst
  static void playBalloonPop() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// ✨ MCQ / Quiz: Crisp Celebratory Ding & Chime on Correct Answer
  static void playCorrectDing() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// ❌ Wrong Answer Buzz & Alert
  static void playWrongBuzz() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// 🏆 Victory / Level Complete Fanfare
  static void playVictoryFanfare() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
