// lib/screens/trilha/widgets/no_fase_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class NoFaseWidget extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onTap;

  const NoFaseWidget({super.key, required this.item, required this.onTap});

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

    return GestureDetector(
      onTap: item.desbloqueado ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
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
                      blurRadius: 12,
                      spreadRadius: 2,
                    )]
                  : null,
            ),
            child: Center(
              child: item.desbloqueado
                  ? const Icon(Icons.style, color: Colors.white, size: 24)
                  : const Icon(Icons.lock, color: Color(0xFF555566), size: 22),
            ),
          ),
          if (item.concluido)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('✓', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
