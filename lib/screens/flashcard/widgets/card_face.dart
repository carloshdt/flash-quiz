// lib/screens/flashcard/widgets/card_face.dart
// Face do flashcard (frente = pergunta, verso = resposta) — papel com fita.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/fita.dart';

class CardFace extends StatelessWidget {
  final String texto;
  final String label;
  final Color cor;

  const CardFace({
    super.key,
    required this.texto,
    required this.label,
    this.cor = AppColors.cartao,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // fita vaza pra fora do card
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(2, 3),
                  blurRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.tintaSuave,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                texto,
                style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.tinta,
                    fontWeight: FontWeight.w600,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Fita adesiva "colando" o card no topo-centro
        const Positioned(top: -10, child: Fita()),
      ],
    );
  }
}
