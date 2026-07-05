// lib/screens/quiz/quiz_result_screen.dart
// Resultado do quiz em linguagem papel: score gigante manuscrito, carimbo
// APROVADO com batida, confete de papel e sons — reprovado recebe tom suave.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bichinho/evolucao_overlay.dart';
import '../../widgets/confete/confete_papel.dart';
import '../../widgets/papel/botao_papel.dart';
import '../../widgets/papel/carimbo_batida.dart';
import '../../widgets/papel/fundo_papel.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultado resultado;

  const QuizResultScreen({super.key, required this.resultado});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _efeitosCarimboTocados = false; // garante som/haptic da batida 1x

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioService>();
    final r = widget.resultado;
    if (r.aprovado) {
      audio.tocar(Som.confete);
      if (r.estrelas == 3) {
        // Nota máxima merece fanfarra
        audio.tocar(Som.fanfarra);
        audio.vibrar(Vibracao.pesada);
      }
    } else {
      // Reprovado: papel amassado, suave — sem punição sonora pesada
      audio.tocar(Som.papelAmassar);
    }
  }

  // Batida do carimbo completou: som + haptic, depois evolução (se houver)
  void _onCarimboBatida() {
    if (_efeitosCarimboTocados || !mounted) return;
    _efeitosCarimboTocados = true;
    final audio = context.read<AudioService>();
    audio.tocar(Som.carimbo);
    audio.vibrar(Vibracao.media);

    final alimentar = widget.resultado.alimentar;
    if (alimentar?.evoluiu == true) {
      // Respiro de 500ms entre a batida e o overlay de evolução
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        audio.tocar(Som.pixelEvolucao);
        audio.vibrar(Vibracao.pesada);
        mostrarEvolucao(context, alimentar!.bichinho);
      });
    }
  }

  void _refazerQuiz() {
    final r = widget.resultado;
    context.pushReplacement(
      '/quiz/${r.faseId}'
      '?nomeFase=${Uri.encodeComponent(r.nomeFase)}'
      '&nomeTema=${Uri.encodeComponent(r.nomeTema)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final aprovado = r.aprovado;

    return Scaffold(
      backgroundColor: AppColors.papel,
      body: FundoPapel(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Corpo centralizado com score
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Estrelas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final cheia = i < r.estrelas;
                            return Icon(
                              cheia
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 40,
                              color:
                                  cheia ? AppColors.amarelo : AppColors.grao,
                            );
                          }),
                        ),
                        const SizedBox(height: 12),

                        // Nota gigante manuscrita (Patrick Hand via displayLarge)
                        Text(
                          '${r.nota}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(fontSize: 88, height: 1.0),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'pontos',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.tintaSuave,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Carimbo só quando aprovado
                        if (aprovado) ...[
                          CarimboBatida(
                            texto: 'APROVADO',
                            cor: AppColors.verde,
                            fontSize: 32,
                            onBatida: _onCarimboBatida,
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

                        // Status
                        if (aprovado)
                          const Text(
                            'Próxima fase desbloqueada!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.verde,
                            ),
                          )
                        else ...[
                          // Texto encorajador em tinta
                          Text(
                            'Quase lá — você consegue!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mínimo 70 para avançar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tintaSuave,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botões
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24,
                        24 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: BotaoPapel(
                            cor: aprovado ? AppColors.verde : AppColors.laranja,
                            onPressed: aprovado
                                ? () => context.pop() // Continuar → volta para TrilhaScreen
                                : _refazerQuiz, // Tentar novamente → novo quiz
                            child: Center(
                              child: Text(
                                aprovado ? 'Continuar →' : 'Tentar novamente',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (aprovado)
                          SizedBox(
                            width: double.infinity,
                            child: BotaoPapel(
                              cor: AppColors.laranja,
                              onPressed: _refazerQuiz, // Refazer quiz → novo quiz
                              child: const Center(
                                child: Text(
                                  'Refazer quiz',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => context.pop(), // Voltar para trilha
                              child: const Text(
                                'Voltar para trilha',
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

            // Confete de papel por cima do conteúdo quando aprovado
            if (aprovado) const Positioned.fill(child: ConfetePapel()),
          ],
        ),
      ),
    );
  }
}
