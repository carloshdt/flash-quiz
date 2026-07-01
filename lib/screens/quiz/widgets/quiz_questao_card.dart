// lib/screens/quiz/widgets/quiz_questao_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizQuestaoCard extends StatelessWidget {
  final String pergunta;

  const QuizQuestaoCard({super.key, required this.pergunta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          pergunta,
          style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        ),
      ),
    );
  }
}
