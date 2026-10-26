import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Fireworks & Confetti Celebration Dialog
class CelebrationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final int xpEarned;
  final VoidCallback onContinue;

  const CelebrationDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.xpEarned = 50,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Chapter Completed! 🎉',
    String subtitle = 'Fantastic job! You mastered this learning milestone.',
    int xpEarned = 50,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CelebrationDialog(
        title: title,
        subtitle: subtitle,
        xpEarned: xpEarned,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Generate confetti & fireworks burst particles
    for (int i = 0; i < 65; i++) {
      _particles.add(_ConfettiParticle(
        color: _getRandomColor(),
        angle: _random.nextDouble() * 2 * math.pi,
        distance: 40 + _random.nextDouble() * 160,
        size: 5 + _random.nextDouble() * 7,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        isStar: _random.nextBool(),
      ));
    }
  }

  Color _getRandomColor() {
    const colors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFFF4081), // Pink
      Color(0xFF00E676), // Neon Green
      Color(0xFF651FFF), // Deep Purple
      Color(0xFF00B0FF), // Bright Blue
      Color(0xFFFF6D00), // Orange
      Color(0xFFE040FB), // Magenta
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Fireworks / Confetti Particle Layer
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Card
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Trophy Badge with Clapping emojis
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 16),

                // Clapping Emojis Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('👏', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text('🎉', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 6),
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text('👏', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),

                // XP Earned Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '+${widget.xpEarned} Bonus XP Earned!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Super! Continue Learning',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double angle;
  final double distance;
  final double size;
  final double rotationSpeed;
  final bool isStar;

  _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotationSpeed,
    required this.isStar,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Loop with slight delay
      final currentDist = p.distance * progress;
      final x = center.dx + currentDist * math.cos(p.angle);
      // Add slight gravity
      final y = center.dy + currentDist * math.sin(p.angle) + (progress * progress * 50);

      paint.color = p.color.withValues(alpha: (1.0 - (progress * 0.7)).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi);

      if (p.isStar) {
        // Draw star-like diamond
        final path = Path()
          ..moveTo(0, -p.size)
          ..lineTo(p.size * 0.4, 0)
          ..lineTo(0, p.size)
          ..lineTo(-p.size * 0.4, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Draw confetti circle / rectangle
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
