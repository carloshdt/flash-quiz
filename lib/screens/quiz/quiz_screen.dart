// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/papel/fundo_papel.dart';
import 'widgets/quiz_timer_bar.dart';
import 'widgets/quiz_questao_card.dart';
import 'widgets/quiz_alternativas.dart';
import 'widgets/tempo_esgotado_banner.dart';

class QuizScreen extends StatefulWidget {
  final int faseId;
  final String nomeFase;
  final String nomeTema;

  const QuizScreen({
    super.key,
    required this.faseId,
    required this.nomeFase,
    required this.nomeTema,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _concluindo = false; // guard: evita concluir() duplo
  bool _navegandoParaResultado = false; // guard: evita múltiplos addPostFrameCallback
  int _ultimoIndice = -1; // detecta avanço de questão pra vibrar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizController>().carregarQuiz(
            widget.faseId,
            widget.nomeFase,
            widget.nomeTema,
          );
    });
  }

  Future<void> _onWillPop() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cartao,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Sair do quiz?',
            style: Theme.of(context).textTheme.titleLarge),
        content: const Text(
          'Esta tentativa será registrada como abandonada.',
          style: TextStyle(color: AppColors.tintaSuave, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(
                    color: AppColors.tintaSuave, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair',
                style: TextStyle(
                    color: AppColors.laranja, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<QuizController>().abandonar();
      if (mounted) context.pop();
    }
  }

  Future<void> _irParaResultado(QuizController ctrl) async {
    if (_concluindo) return;
    _concluindo = true;
    final resultado = await ctrl.concluir();
    if (!mounted) return;
    context.pushReplacement('/quiz-resultado', extra: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onWillPop(),
      child: Scaffold(
        backgroundColor: AppColors.papel,
        body: FundoPapel(
          child: Consumer<QuizController>(
            builder: (_, ctrl, __) {
              if (ctrl.carregando) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.laranja));
              }

              // Quando última questão foi respondida, navega para resultado
              if (ctrl.quizConcluido && !_navegandoParaResultado) {
                _navegandoParaResultado = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _irParaResultado(ctrl);
                });
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.laranja));
              } else if (ctrl.quizConcluido) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.laranja));
              }

              // Avançou de questão → haptic de seleção
              if (_ultimoIndice != -1 && ctrl.indiceAtual != _ultimoIndice) {
                vibrarSeDisponivel(context, Vibracao.selecao);
              }
              _ultimoIndice = ctrl.indiceAtual;

              final card = ctrl.questaoAtual!;
              final tempoEsgotado = ctrl.estado == EstadoQuestao.tempoEsgotado;
              final selecionada = ctrl.estado == EstadoQuestao.selecionada;

              return SafeArea(
                child: Column(
                  children: [
                    // Header papel: contexto + questão atual, sublinhado azul
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.nomeTema} · ${widget.nomeFase}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.tintaSuave),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Questão ${ctrl.indiceAtual + 1} / ${ctrl.totalQuestoes}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 3,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppColors.azul,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Barra de timer + número
                    QuizTimerBar(
                      percentual: ctrl.percentualTempo,
                      segundos: ctrl.segundosRestantes,
                    ),

                    // Card da pergunta
                    QuizQuestaoCard(pergunta: card.pergunta, seed: card.id),

                    const SizedBox(height: 12),

                    // Timer esgotado: mensagem
                    if (tempoEsgotado)
                      TempoEsgotadoBanner(onTap: ctrl.avancarAposTempoEsgotado),

                    // Alternativas
                    Expanded(
                      child: QuizAlternativas(
                        alternativas: ctrl.alternativasAtual,
                        respostaSelecionada: ctrl.respostaSelecionada,
                        desabilitada: tempoEsgotado || selecionada,
                        onSelecionar: ctrl.selecionarResposta,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
