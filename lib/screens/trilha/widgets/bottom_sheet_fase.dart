// lib/screens/trilha/widgets/bottom_sheet_fase.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/barra_papel.dart';
import '../../../widgets/papel/botao_papel.dart';

class BottomSheetFase extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onIniciar;
  const BottomSheetFase({super.key, required this.item, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final percentual = (item.percentualVisto * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.papel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.grao,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Título da fase
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.fase.nome,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.tinta),
            ),
          ),
          const SizedBox(height: 12),

          // Barra de progresso dos cards vistos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$percentual% dos cards vistos',
                style: const TextStyle(fontSize: 11, color: AppColors.tintaSuave),
              ),
              const SizedBox(height: 6),
              BarraPapel(item.percentualVisto, AppColors.laranja, altura: 8),
            ],
          ),
          const SizedBox(height: 16),

          // Botão iniciar ou continuar
          SizedBox(
            width: double.infinity,
            child: BotaoPapel(
              cor: AppColors.verde,
              onPressed: () {
                Navigator.pop(context);
                onIniciar();
              },
              child: Center(
                child: Text(
                  item.cardsVistos > 0 ? '▶ Continuar Flashcards' : '▶ Iniciar Flashcards',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
