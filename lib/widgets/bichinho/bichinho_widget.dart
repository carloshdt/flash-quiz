// lib/widgets/bichinho/bichinho_widget.dart
// BichinhoMini (linha do tema na Home) e BichinhoHeader (topo da tela do tema).
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

class BichinhoMini extends StatelessWidget {
  final Bichinho bichinho;
  final HumorBichinho humor;
  final bool animado;
  const BichinhoMini({super.key, required this.bichinho, required this.humor, this.animado = true});

  @override
  Widget build(BuildContext context) {
    return BichinhoSprite(
      temaId: bichinho.temaId,
      estagio: bichinho.estagio,
      humor: humor,
      tamanho: 28,
      animado: animado,
    );
  }
}

class BichinhoHeader extends StatelessWidget {
  final Bichinho bichinho;
  final HumorBichinho humor;
  final int? proximoThreshold; // null = lendário
  final VoidCallback? onTap;
  final bool animado;

  const BichinhoHeader({
    super.key,
    required this.bichinho,
    required this.humor,
    required this.proximoThreshold,
    this.onTap,
    this.animado = true,
  });

  @override
  Widget build(BuildContext context) {
    final progresso = proximoThreshold == null
        ? 1.0
        : (bichinho.energia / proximoThreshold!).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: 'Bichinho ${bichinho.nomeEstagio}',
      child: GestureDetector(
        onTap: onTap,
        // opaque: toda a área do header é tocável — deferToChild deixaria
        // zonas mortas no SizedBox e no espaço vazio do Expanded.
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            BichinhoSprite(
              temaId: bichinho.temaId,
              estagio: bichinho.estagio,
              humor: humor,
              tamanho: 72,
              animado: animado,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bichinho.nomeEstagio, style: AppTheme.pixel(fontSize: 20)),
                  const SizedBox(height: 4),
                  if (proximoThreshold != null) ...[
                    // Barra de energia estilo pixel
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.tinta, width: 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progresso,
                        child: Container(color: AppColors.verde),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${bichinho.energia}/$proximoThreshold',
                        style: AppTheme.pixel(fontSize: 14, color: AppColors.tintaSuave)),
                  ] else
                    Text('★ máximo!',
                        style: AppTheme.pixel(fontSize: 14, color: AppColors.amarelo)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
