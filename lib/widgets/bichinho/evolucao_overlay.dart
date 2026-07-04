// lib/widgets/bichinho/evolucao_overlay.dart
// Animação de evolução: sprite antigo treme → flash branco → sprite novo salta.
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

Future<void> mostrarEvolucao(BuildContext context, Bichinho evoluido) {
  // Evolução implica sair de um estágio anterior — nunca chega aqui com ovo.
  assert(evoluido.estagio >= 1);
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) => _EvolucaoDialog(bichinho: evoluido),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _EvolucaoDialog extends StatefulWidget {
  final Bichinho bichinho;
  const _EvolucaoDialog({required this.bichinho});

  @override
  State<_EvolucaoDialog> createState() => _EvolucaoDialogState();
}

class _EvolucaoDialogState extends State<_EvolucaoDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // fases: 0-0.4 sprite antigo tremendo, 0.4-0.6 flash, 0.6-1.0 sprite novo saltando
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward().whenComplete(() {
        // Animação acabou: segura o sprite novo por 800ms e fecha sozinho.
        // isCurrent evita pop errado se outra rota subiu por cima no intervalo.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.of(context).pop();
          }
        });
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            if (t < 0.4) {
              // sprite ANTIGO tremendo (estágio - 1)
              final shake = (t * 60).floor() % 2 == 0 ? 2.0 : -2.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: BichinhoSprite(
                  temaId: widget.bichinho.temaId,
                  estagio: widget.bichinho.estagio - 1,
                  tamanho: 128,
                  animado: false,
                ),
              );
            }
            if (t < 0.6) {
              return Container(width: 160, height: 160, color: Colors.white);
            }
            // sprite novo salta (scale elástico) + texto
            final salto = Curves.elasticOut.transform((t - 0.6) / 0.4);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.5 + salto * 0.5,
                  child: BichinhoSprite(
                    temaId: widget.bichinho.temaId,
                    estagio: widget.bichinho.estagio,
                    tamanho: 128,
                    animado: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text('EVOLUIU!', style: AppTheme.pixel(fontSize: 32, color: AppColors.amarelo)),
                Text(widget.bichinho.nomeEstagio,
                    style: AppTheme.pixel(fontSize: 22, color: Colors.white)),
              ],
            );
          },
        ),
      ),
    );
  }
}
