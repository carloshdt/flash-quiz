// lib/screens/maratona/maratona_result_screen.dart
// Resultado da maratona em linguagem papel: recorde batido ganha carimbo
// RECORDE laranja com batida, fanfarra e confete — sem recorde, visual sóbrio.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/maratona_controller.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bichinho/evolucao_overlay.dart';
import '../../widgets/confete/confete_papel.dart';
import '../../widgets/papel/botao_papel.dart';
import '../../widgets/papel/carimbo_batida.dart';
import '../../widgets/papel/fundo_papel.dart';

class MaratonaResultScreen extends StatefulWidget {
  final MaratonaResultado resultado;

  const MaratonaResultScreen({super.key, required this.resultado});

  @override
  State<MaratonaResultScreen> createState() => _MaratonaResultScreenState();
}

class _MaratonaResultScreenState extends State<MaratonaResultScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.resultado.recordeBatido) {
      final audio = context.read<AudioService>();
      audio.tocar(Som.confete);
      audio.tocar(Som.fanfarra);
      audio.vibrar(Vibracao.pesada);
      // Recorde: evolução espera a batida do carimbo (onBatida)
    } else {
      // Sem carimbo — bichinho evoluiu de verdade, celebra mesmo assim
      _agendarEvolucao(const Duration(milliseconds: 800));
    }
  }

  // Agenda o overlay de evolução (se o bichinho evoluiu) após um respiro
  void _agendarEvolucao(Duration respiro) {
    final alimentar = widget.resultado.alimentar;
    if (alimentar?.evoluiu != true) return;
    Future.delayed(respiro, () {
      if (!mounted) return;
      final audio = context.read<AudioService>();
      audio.tocar(Som.pixelEvolucao);
      audio.vibrar(Vibracao.pesada);
      mostrarEvolucao(context, alimentar!.bichinho);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;

    return Scaffold(
      backgroundColor: AppColors.papel,
      body: FundoPapel(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(r.recordeBatido ? '🏆' : '🏃',
                            style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),

                        // Score gigante manuscrito
                        Text(
                          '${r.score}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(fontSize: 88, height: 1.0),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'acertos',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.tintaSuave,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Carimbo RECORDE só quando bateu o recorde
                        if (r.recordeBatido) ...[
                          CarimboBatida(
                            texto: 'RECORDE',
                            cor: AppColors.laranja,
                            fontSize: 32,
                            // Evolução (se houver) 500ms após a batida
                            onBatida: () => _agendarEvolucao(
                                const Duration(milliseconds: 500)),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Divisor de grão
                        Container(
                          width: 48,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.grao,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          r.recordeBatido
                              ? 'Novo recorde! 🎉'
                              : 'Recorde: ${r.recorde}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: r.recordeBatido
                                ? AppColors.laranja
                                : AppColors.tintaSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24,
                        24 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: BotaoPapel(
                            cor: AppColors.laranja,
                            onPressed: () => context.pushReplacement(
                              '/maratona/${r.temaId}'
                              '?nomeTema=${Uri.encodeComponent(r.nomeTema)}',
                            ),
                            child: const Center(
                              child: Text(
                                'Jogar de novo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: const Text(
                              'Voltar ao tema',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tinta,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Confete de papel quando bateu o recorde
            if (r.recordeBatido)
              const Positioned.fill(child: ConfetePapel()),
          ],
        ),
      ),
    );
  }
}
