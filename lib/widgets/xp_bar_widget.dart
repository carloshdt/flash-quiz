// lib/widgets/xp_bar_widget.dart
// Barra de XP estilo recorte: borda de tinta 2px, preenchimento amarelo.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class XpBarWidget extends StatelessWidget {
  final int nivel;
  final int xpAtual;
  final int xpProximo;

  const XpBarWidget({
    super.key,
    required this.nivel,
    required this.xpAtual,
    required this.xpProximo,
  });

  @override
  Widget build(BuildContext context) {
    final progresso = xpProximo > 0 ? (xpAtual / xpProximo).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NÍVEL $nivel',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.tinta,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$xpAtual / $xpProximo XP',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.tintaSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.tinta, width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progresso,
            child: Container(color: AppColors.amarelo),
          ),
        ),
      ],
    );
  }
}
