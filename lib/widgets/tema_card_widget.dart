// lib/widgets/tema_card_widget.dart
// Tema como recorte de papel: PapelCard torto + emoji grande + bichinho na linha.
import 'package:flutter/material.dart';
import '../models/bichinho.dart';
import '../models/tema.dart';
import '../theme/app_theme.dart';
import 'bichinho/bichinho_widget.dart';
import 'papel/papel_card.dart';

class TemaCardWidget extends StatelessWidget {
  final Tema tema;
  final VoidCallback onTap;
  final Bichinho? bichinho;
  final HumorBichinho? humor;

  const TemaCardWidget({
    super.key,
    required this.tema,
    required this.onTap,
    this.bichinho,
    this.humor,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueado = !tema.desbloqueado;
    final acento = AppColors.accentFor(tema.id);

    return GestureDetector(
      onTap: bloqueado ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: bloqueado ? 0.45 : 1.0,
        child: PapelCard(
          seed: tema.id,
          child: Row(
            children: [
              Text(tema.icone, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tema.nome, style: Theme.of(context).textTheme.titleLarge),
                    Container(height: 3, width: 48, color: acento), // sublinhado de marca-texto
                  ],
                ),
              ),
              if (!bloqueado && bichinho != null && humor != null)
                BichinhoMini(bichinho: bichinho!, humor: humor!),
              const SizedBox(width: 6),
              bloqueado
                  ? const Icon(Icons.lock_outline, color: AppColors.tintaSuave, size: 18)
                  : const Icon(Icons.chevron_right, color: AppColors.tintaSuave),
            ],
          ),
        ),
      ),
    );
  }
}
