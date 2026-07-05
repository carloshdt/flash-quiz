// lib/screens/quiz/widgets/quiz_timer_bar.dart
// Régua de tempo: papel com marquinhas a cada 10%, laranja → vermelho < 30%.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizTimerBar extends StatelessWidget {
  final double percentual; // 0.0 a 1.0
  final int segundos;

  const QuizTimerBar({super.key, required this.percentual, required this.segundos});

  @override
  Widget build(BuildContext context) {
    // Mantém o threshold: resta < 30% do tempo → vermelho
    final cor = percentual < 0.30 ? const Color(0xFFD63A2F) : AppColors.laranja;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.papel,
                border: Border.all(color: AppColors.tinta, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentual.clamp(0.0, 1.0),
                        child: ColoredBox(color: cor),
                      ),
                    ),
                    // Marquinhas da régua por cima do preenchimento
                    const Positioned.fill(
                      child: CustomPaint(painter: _MarquinhasPainter()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$segundos',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.tinta),
            ),
          ),
        ],
      ),
    );
  }
}

// Traços verticais a cada 10% da largura — cara de régua escolar.
class _MarquinhasPainter extends CustomPainter {
  const _MarquinhasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grao
      ..strokeWidth = 1;
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
