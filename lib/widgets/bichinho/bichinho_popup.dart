// lib/widgets/bichinho/bichinho_popup.dart
// Bottom sheet com sprite grande, estágio, energia, humor e dica.
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

Future<void> mostrarBichinhoPopup(
  BuildContext context, {
  required Bichinho bichinho,
  required HumorBichinho humor,
  required int? proximoThreshold,
}) {
  final dicas = {
    HumorBichinho.feliz: 'Tá feliz! Continue assim.',
    HumorBichinho.neutro: 'Estude hoje pra deixar ele feliz!',
    HumorBichinho.comFome: 'Tá com fome! Alimente com 3 cards.',
    HumorBichinho.dormindo: 'Dormiu de tédio... acorde ele estudando!',
  };

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.papel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BichinhoSprite(
            temaId: bichinho.temaId,
            estagio: bichinho.estagio,
            humor: humor,
            tamanho: 128,
          ),
          const SizedBox(height: 12),
          Text(bichinho.nomeEstagio, style: AppTheme.pixel(fontSize: 28)),
          if (proximoThreshold != null)
            Text('${bichinho.energia}/$proximoThreshold energia',
                style: AppTheme.pixel(fontSize: 18, color: AppColors.tintaSuave)),
          const SizedBox(height: 8),
          Text(dicas[humor]!, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
