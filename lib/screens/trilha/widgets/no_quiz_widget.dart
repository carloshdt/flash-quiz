// lib/screens/trilha/widgets/no_quiz_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class NoQuizWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;
  final double size;

  const NoQuizWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    final desbloqueado = item.desbloqueado;
    final concluido = item.concluido;
    final emojiSize = size * 0.38;
    final badgeSize = size * 0.27;

    return GestureDetector(
      onTap: desbloqueado ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: desbloqueado ? 1.0 : 0.5,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: concluido ? const Color(0xFF00897B) : const Color(0xFF1A2A28),
                borderRadius: BorderRadius.circular(size * 0.2),
                border: Border.all(
                  color: concluido ? const Color(0xFF4DB6AC) : const Color(0xFF2A3A38),
                  width: 2,
                ),
              ),
              child: Center(
                child: desbloqueado
                    ? Text('📝', style: TextStyle(fontSize: emojiSize))
                    : Icon(Icons.lock, color: const Color(0xFF2A3A38), size: emojiSize),
              ),
            ),
          ),
          if (concluido)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6C90E),
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
