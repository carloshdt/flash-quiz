// lib/screens/quiz/widgets/quiz_questao_card.dart
// Questão em card de papel torto — seed estável pra rotação não tremer.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/papel_card.dart';

class QuizQuestaoCard extends StatelessWidget {
  final String pergunta;
  final int seed; // id/índice da questão — mesma questão, mesma rotação

  const QuizQuestaoCard({super.key, required this.pergunta, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PapelCard(
        seed: seed,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            pergunta,
            style: const TextStyle(
                fontSize: 15, color: AppColors.tinta, height: 1.5),
          ),
        ),
      ),
    );
  }
}
