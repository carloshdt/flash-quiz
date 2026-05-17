// lib/widgets/xp_bar_widget.dart
import 'package:flutter/material.dart';

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
    final progresso = xpProximo > 0 ? xpAtual / xpProximo : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nível $nivel', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 12)),
              Text('$xpAtual / $xpProximo XP', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF1A237E),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
