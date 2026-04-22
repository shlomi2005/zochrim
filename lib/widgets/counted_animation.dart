import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// overlay שמופיע אחרי לחיצה על "ספרתי" - צ'קמארק מונפש + מחמאה אישית
class CountedAnimation extends StatefulWidget {
  final String compliment;
  final VoidCallback onDone;
  const CountedAnimation({
    super.key,
    required this.compliment,
    required this.onDone,
  });

  @override
  State<CountedAnimation> createState() => _CountedAnimationState();
}

class _CountedAnimationState extends State<CountedAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: _buildStack(),
      ),
    );
  }

  Widget _buildStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black.withOpacity(0.65)),
        // confetti
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (c, _) => CustomPaint(
              painter: _ConfettiPainter(progress: _confettiCtrl.value),
            ),
          ),
        ),
        // הצ'קמארק והטקסט
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
            child: FadeTransition(
              opacity: _ctrl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 70, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      widget.compliment,
                      textAlign: TextAlign.center,
                      style: AppFonts.liturgical(
                        size: 22,
                        weight: FontWeight.w600,
                        color: AppColors.goldSoft,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static final _rng = math.Random(42);
  static final _pieces = List.generate(60, (i) {
    return _ConfettiPiece(
      angle: _rng.nextDouble() * math.pi * 2,
      speed: 250 + _rng.nextDouble() * 320,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
      color: [
        AppColors.accentGold,
        AppColors.goldSoft,
        AppColors.accentRose,
        Colors.white,
      ][_rng.nextInt(4)],
      size: 4 + _rng.nextDouble() * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 350 * progress * progress;
    for (final p in _pieces) {
      final dx = math.cos(p.angle) * p.speed * progress;
      final dy = math.sin(p.angle) * p.speed * progress + gravity;
      final offset = center + Offset(dx, dy);
      final paint = Paint()
        ..color = p.color.withOpacity(1 - progress * 0.6);
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.8),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  final double angle;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;
  _ConfettiPiece({
    required this.angle,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}
