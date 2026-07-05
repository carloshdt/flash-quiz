// lib/widgets/papel/borda_tracejada_painter.dart
// Forma com fundo papel e borda tracejada cinza (costura) — visual de
// "rascunho não preenchido" dos nós bloqueados da trilha.
// Com raio >= metade do lado menor, o retângulo arredondado vira círculo.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'papel_util.dart';

class BordaTracejadaPainter extends CustomPainter {
  final double raio;
  const BordaTracejadaPainter({required this.raio});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      const Offset(1, 1) & Size(size.width - 2, size.height - 2),
      Radius.circular(raio),
    );

    // Fundo papel preenchido
    canvas.drawRRect(rrect, Paint()..color = AppColors.papel);

    // Borda tracejada ao longo do contorno
    final paint = Paint()
      ..color = AppColors.grao
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    desenharTracejado(canvas, Path()..addRRect(rrect), paint);
  }

  @override
  bool shouldRepaint(covariant BordaTracejadaPainter old) => old.raio != raio;
}
