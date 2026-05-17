// lib/screens/trilha/widgets/no_quiz_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class NoQuizWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;

  const NoQuizWidget({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final desbloqueado = item.desbloqueado;
    final concluido = item.concluido;

    return GestureDetector(
      onTap: desbloqueado ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: desbloqueado ? 1.0 : 0.5,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: concluido ? const Color(0xFF00897B) : const Color(0xFF1A2A28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: concluido ? const Color(0xFF4DB6AC) : const Color(0xFF2A3A38),
                ),
              ),
              child: Center(
                child: desbloqueado
                    ? const Text('📝', style: TextStyle(fontSize: 20))
                    : const Icon(Icons.lock, color: Color(0xFF2A3A38), size: 18),
              ),
            ),
          ),
          if (concluido)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6C90E),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('✓', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
