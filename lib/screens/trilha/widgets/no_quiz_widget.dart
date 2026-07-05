// lib/screens/trilha/widgets/no_quiz_widget.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/borda_tracejada_painter.dart';

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
    final iconSize = size * 0.38;
    final raio = size * 0.2;

    // Bloqueado: rascunho não preenchido — papel com borda tracejada + cadeado
    if (!item.desbloqueado) {
      return Semantics(
        label: 'Quiz bloqueado',
        child: CustomPaint(
          painter: BordaTracejadaPainter(raio: raio),
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

    // Em andamento: laranja com 📝; concluído: selo carimbado verde com ✓ branco
    final concluido = item.concluido;

    return Semantics(
      button: true,
      label: 'Quiz ${item.fase.nome}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: concluido ? AppColors.verde : AppColors.laranja,
            borderRadius: BorderRadius.circular(raio),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: concluido
                ? Icon(Icons.check, color: Colors.white, size: iconSize)
                : Text('📝', style: TextStyle(fontSize: iconSize)),
          ),
        ),
      ),
    );
  }
}
