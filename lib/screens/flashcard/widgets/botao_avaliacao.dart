// lib/screens/flashcard/widgets/botao_avaliacao.dart
// Botão de autoavaliação SRS (Difícil / Médio / Fácil) — embrulha o BotaoPapel
// (sombra dura que afunda + scale 0.97 + haptic via AudioService).
import 'package:flutter/material.dart';
import '../../../widgets/papel/botao_papel.dart';

class BotaoAvaliacao extends StatelessWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corTexto;
  final VoidCallback onTap;

  const BotaoAvaliacao({
    super.key,
    required this.emoji,
    required this.label,
    required this.cor,
    this.corTexto = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: BotaoPapel(
          cor: cor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: onTap,
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: corTexto,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
