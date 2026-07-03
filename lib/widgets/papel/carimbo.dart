// lib/widgets/papel/carimbo.dart
// Carimbo rotacionado com borda dupla — APROVADO, RECORDE, etc.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class Carimbo extends StatelessWidget {
  final String texto;
  final Color cor;
  final double angulo; // graus
  final double fontSize;

  const Carimbo({
    super.key,
    required this.texto,
    this.cor = AppColors.verde,
    this.angulo = -8,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: cor, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: cor, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            texto,
            style: GoogleFonts.patrickHand(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: cor,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
