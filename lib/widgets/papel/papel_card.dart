// lib/widgets/papel/papel_card.dart
// Card de papel: branco, canto 4px, rotação torta determinística e sombra dura.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PapelCard extends StatelessWidget {
  final Widget child;
  final int seed; // hash estável (ex: id do item) — mesma seed, mesma rotação
  final EdgeInsetsGeometry padding;
  final Color cor;

  const PapelCard({
    super.key,
    required this.child,
    this.seed = 0,
    this.padding = const EdgeInsets.all(16),
    this.cor = AppColors.cartao,
  });

  /// Rotação entre -1.5° e +1.5° derivada da seed.
  double get _angulo => ((seed * 2654435761) % 100 - 50) / 50 * 0.026; // rad ≈ 1.5°

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _angulo,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), offset: Offset(2, 3), blurRadius: 0),
          ],
        ),
        child: child,
      ),
    );
  }
}
