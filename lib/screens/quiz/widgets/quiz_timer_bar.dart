// lib/screens/quiz/widgets/quiz_timer_bar.dart
// Barra de timer do quiz: roxa, vira vermelha quando resta < 30% do tempo
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizTimerBar extends StatelessWidget {
  final double percentual; // 0.0 a 1.0
  final int segundos;

  const QuizTimerBar({super.key, required this.percentual, required this.segundos});

  @override
  Widget build(BuildContext context) {
    final cor = percentual < 0.30 ? const Color(0xFFFF3D00) : AppColors.purple;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentual,
                backgroundColor: const Color(0xFF1A1A3A),
                valueColor: AlwaysStoppedAnimation<Color>(cor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$segundos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}
