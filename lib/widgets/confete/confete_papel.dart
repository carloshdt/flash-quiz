// lib/widgets/confete/confete_papel.dart
// Confete de papel picado — retângulos coloridos caindo com rotação.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ConfetePapel extends StatefulWidget {
  final int particulas;
  const ConfetePapel({super.key, this.particulas = 24});

  @override
  State<ConfetePapel> createState() => _ConfetePapelState();
}

class _ConfetePapelState extends State<ConfetePapel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particula> _parts;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final cores = [AppColors.laranja, AppColors.verde, AppColors.amarelo, AppColors.azul, AppColors.rosa];
    _parts = List.generate(widget.particulas, (i) => _Particula(
          x: r.nextDouble(),
          velY: 0.5 + r.nextDouble() * 0.8,
          fase: r.nextDouble() * 2 * pi,
          cor: cores[i % cores.length],
        ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfetePainter(_parts, _ctrl.value),
        ),
      ),
    );
  }
}

class _Particula {
  final double x, velY, fase;
  final Color cor;
  _Particula({required this.x, required this.velY, required this.fase, required this.cor});
}

class _ConfetePainter extends CustomPainter {
  final List<_Particula> parts;
  final double t;
  _ConfetePainter(this.parts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final y = t * p.velY * size.height;
      if (y > size.height) continue;
      final x = p.x * size.width + sin(t * 6 + p.fase) * 20;
      paint.color = p.cor.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + p.fase);
      canvas.drawRect(const Rect.fromLTWH(-4, -6, 8, 12), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetePainter old) => old.t != t;
}
