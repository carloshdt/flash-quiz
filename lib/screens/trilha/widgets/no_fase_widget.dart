// lib/screens/trilha/widgets/no_fase_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/borda_tracejada_painter.dart';

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
    final iconSize = size * 0.37;

    // Bloqueado: rascunho não preenchido — papel com borda tracejada + cadeado
    if (!item.desbloqueado) {
      return Semantics(
        label: 'Fase bloqueada',
        child: CustomPaint(
          painter: BordaTracejadaPainter(raio: size / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child:
                  Icon(Icons.lock, color: AppColors.tintaSuave, size: iconSize),
            ),
          ),
        ),
      );
    }

    // Em andamento: laranja; concluído: selo carimbado verde com ✓ branco
    final cor = item.concluido ? AppColors.verde : AppColors.laranja;

    return Semantics(
      button: true,
      label: 'Fase ${item.fase.nome}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              item.concluido ? Icons.check : Icons.style,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
