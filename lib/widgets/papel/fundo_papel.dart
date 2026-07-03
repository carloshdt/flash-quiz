// lib/widgets/papel/fundo_papel.dart
// Fundo papel creme com grão pontilhado determinístico.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FundoPapel extends StatelessWidget {
  final Widget child;
  const FundoPapel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.papel,
      child: CustomPaint(
        painter: _GraoPainter(), // grão atrás do conteúdo, nunca por cima
        child: child,
      ),
    );
  }
}

class _GraoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.grao.withValues(alpha: 0.35);
    // Pontos em grade pseudo-aleatória determinística (sem Random pra não tremer)
    for (double y = 8; y < size.height; y += 26) {
      for (double x = 8; x < size.width; x += 26) {
        final dx = ((x * 7 + y * 13) % 11) - 5;
        final dy = ((x * 13 + y * 7) % 9) - 4;
        canvas.drawCircle(Offset(x + dx, y + dy), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
