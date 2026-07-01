// lib/widgets/xp_bar_widget.dart
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
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.35),
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$xpAtual / $xpProximo XP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
