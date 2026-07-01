// lib/screens/flashcard/widgets/card_face.dart
// Face do flashcard (frente = pergunta, verso = resposta)
import 'package:flutter/material.dart';

class CardFace extends StatelessWidget {
  final String texto;
  final String label;
  final Color cor;
  final Color corBorda;

  const CardFace({
    super.key,
    required this.texto,
    required this.label,
    required this.cor,
    required this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Text(
            texto,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
