// lib/screens/flashcard/widgets/botao_avaliacao.dart
// Botão de autoavaliação SRS (Difícil / Médio / Fácil)
import 'package:flutter/material.dart';

class BotaoAvaliacao extends StatelessWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corBorda;
  final VoidCallback onTap;

  const BotaoAvaliacao({
    super.key,
    required this.emoji,
    required this.label,
    required this.cor,
    required this.corBorda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: corBorda, width: 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
