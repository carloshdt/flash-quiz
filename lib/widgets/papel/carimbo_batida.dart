// lib/widgets/papel/carimbo_batida.dart
// Carimbo com animação de batida: cai de cima (scale 1.6 → 1.0) como se
// estampado na página. onBatida dispara quando a batida completa (som/haptic).
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'carimbo.dart';

class CarimboBatida extends StatelessWidget {
  final String texto;
  final Color cor;
  final double fontSize;
  final VoidCallback? onBatida;

  const CarimboBatida({
    super.key,
    required this.texto,
    this.cor = AppColors.verde,
    this.fontSize = 32,
    this.onBatida,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.6, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      onEnd: onBatida,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Carimbo(texto: texto, cor: cor, fontSize: fontSize),
    );
  }
}
