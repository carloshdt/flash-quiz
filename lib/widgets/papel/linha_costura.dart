// lib/widgets/papel/linha_costura.dart
// Divisor tracejado tipo costura / linha de recorte.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LinhaCostura extends StatelessWidget {
  final Color cor;
  const LinhaCostura({super.key, this.cor = AppColors.grao});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(double.infinity, 2), painter: _CosturaPainter(cor));
  }
}

class _CosturaPainter extends CustomPainter {
  final Color cor;
  _CosturaPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 8.0, gap = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset((x + dash).clamp(0, size.width), 1), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _CosturaPainter old) => old.cor != cor;
}
