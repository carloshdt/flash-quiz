// lib/screens/trilha/widgets/no_fase_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';

class NoFaseWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;
  final double size;

  const NoFaseWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.size = 82,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.37;

    // Bloqueado: rascunho não preenchido — papel com borda tracejada + cadeado
    if (!item.desbloqueado) {
      return CustomPaint(
        painter: const _BordaTracejadaPainter(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(Icons.lock, color: AppColors.tintaSuave, size: iconSize),
          ),
        ),
      );
    }

    // Em andamento: laranja; concluído: selo carimbado verde com ✓ branco
    final cor = item.concluido ? AppColors.verde : AppColors.laranja;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Icon(
            item.concluido ? Icons.check : Icons.style,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Círculo com fundo papel e borda tracejada cinza (traço 8, gap 6) — nó bloqueado.
class _BordaTracejadaPainter extends CustomPainter {
  const _BordaTracejadaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.shortestSide / 2 - 1;

    // Fundo papel preenchido
    canvas.drawCircle(centro, raio, Paint()..color = AppColors.papel);

    // Borda tracejada ao longo da circunferência
    final paint = Paint()
      ..color = AppColors.grao
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(Rect.fromCircle(center: centro, radius: raio));
    const dash = 8.0, gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double distancia = 0;
      while (distancia < metric.length) {
        final fim = (distancia + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distancia, fim), paint);
        distancia += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordaTracejadaPainter old) => false;
}
