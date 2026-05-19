// lib/screens/trilha/widgets/no_fase_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class NoFaseWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;
  final double size;

  const NoFaseWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.size = 82,
  });

  @override
  Widget build(BuildContext context) {
    Color cor;
    if (!item.desbloqueado) {
      cor = const Color(0xFF2A2A45);
    } else if (item.concluido) {
      cor = const Color(0xFF7C4DFF);
    } else {
      cor = const Color(0xFFFF6F00);
    }

    final iconSize = size * 0.37;
    final badgeSize = size * 0.27;

    return GestureDetector(
      onTap: item.desbloqueado ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              border: Border.all(
                color: item.emAndamento ? const Color(0xFFFFAB40) : Colors.transparent,
                width: 3,
              ),
              boxShadow: item.emAndamento
                  ? [BoxShadow(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 3,
                    )]
                  : null,
            ),
            child: Center(
              child: item.desbloqueado
                  ? Icon(Icons.style, color: Colors.white, size: iconSize)
                  : Icon(Icons.lock, color: const Color(0xFF555566), size: iconSize),
            ),
          ),
          if (item.concluido)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('✓',
                    style: TextStyle(
                      fontSize: badgeSize * 0.55,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
