// lib/screens/quiz/widgets/quiz_alternativas.dart
// Lista A/B/C/D com highlight roxo na selecionada
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizAlternativas extends StatelessWidget {
  final List<String> alternativas;
  final int? respostaSelecionada;
  final bool desabilitada;
  final ValueChanged<int> onSelecionar;

  const QuizAlternativas({
    super.key,
    required this.alternativas,
    required this.respostaSelecionada,
    required this.desabilitada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    const letras = ['A', 'B', 'C', 'D'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: alternativas.length,
      itemBuilder: (_, i) {
        final selecionadaEsta = respostaSelecionada == i;
        return GestureDetector(
          onTap: desabilitada ? null : () => onSelecionar(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selecionadaEsta
                  ? AppColors.purple.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selecionadaEsta ? AppColors.purple : const Color(0xFF2A2A5A),
                width: selecionadaEsta ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  letras[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selecionadaEsta ? AppColors.purple : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alternativas[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: selecionadaEsta ? Colors.white : const Color(0xFFCCCCCC),
                      fontWeight: selecionadaEsta ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
