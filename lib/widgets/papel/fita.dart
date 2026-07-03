// lib/widgets/papel/fita.dart
// Fita adesiva translúcida que "cola" o topo de um card.
import 'package:flutter/material.dart';

class Fita extends StatelessWidget {
  final double largura;
  final double angulo; // graus

  const Fita({super.key, this.largura = 72, this.angulo = -4});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo * 3.14159 / 180,
      child: Container(
        width: largura,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 0),
          ],
        ),
      ),
    );
  }
}
