// lib/screens/trilha/widgets/no_quiz_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';

class NoQuizWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;
  final double size;

  const NoQuizWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.38;
    final raio = size * 0.2;

    // Bloqueado: rascunho não preenchido — papel com borda tracejada + cadeado
    if (!item.desbloqueado) {
      return CustomPaint(
        painter: _BordaTracejadaPainter(raio: raio),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(Icons.lock, color: AppColors.tintaSuave, size: iconSize),
          ),
        ),
      );
    }

    // Em andamento: laranja com 📝; concluído: selo carimbado verde com ✓ branco
    final concluido = item.concluido;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: concluido ? AppColors.verde : AppColors.laranja,
          borderRadius: BorderRadius.circular(raio),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Center(
          child: concluido
              ? Icon(Icons.check, color: Colors.white, size: iconSize)
              : Text('📝', style: TextStyle(fontSize: iconSize)),
        ),
      ),
    );
  }
}

/// Retângulo arredondado com fundo papel e borda tracejada cinza (traço 8, gap 6)
/// — nó de quiz bloqueado.
class _BordaTracejadaPainter extends CustomPainter {
  final double raio;
  const _BordaTracejadaPainter({required this.raio});

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

    final path = Path()..addRRect(rrect);
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
  bool shouldRepaint(covariant _BordaTracejadaPainter old) => old.raio != raio;
}
