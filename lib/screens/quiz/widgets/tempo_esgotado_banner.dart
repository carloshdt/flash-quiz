// lib/screens/quiz/widgets/tempo_esgotado_banner.dart
import 'package:flutter/material.dart';

class TempoEsgotadoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const TempoEsgotadoBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF3A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF5252)),
        ),
        child: const Text(
          'Tempo esgotado — toque para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFFFF5252), fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
