// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
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

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  bool _concluindo = false; // guard: evita concluir() duplo
  bool _navegandoParaResultado = false; // guard: evita múltiplos addPostFrameCallback

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizController>().carregarQuiz(
            widget.faseId,
            widget.nomeFase,
            widget.nomeTema,
          );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2040),
        title: const Text('Sair do quiz?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Esta tentativa será registrada como abandonada.',
          style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF90CAF9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<QuizController>().abandonar();
      if (mounted) context.pop();
    }
    return false;
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
        backgroundColor: const Color(0xFF151C35),
        body: Consumer<QuizController>(
          builder: (_, ctrl, __) {
            if (ctrl.carregando) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
            }

            // Quando última questão foi respondida, navega para resultado
            if (ctrl.quizConcluido && !_navegandoParaResultado) {
              _navegandoParaResultado = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _irParaResultado(ctrl);
              });
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
            } else if (ctrl.quizConcluido) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
            }

            final card = ctrl.questaoAtual!;
            final tempoEsgotado = ctrl.estado == EstadoQuestao.tempoEsgotado;
            final selecionada = ctrl.estado == EstadoQuestao.selecionada;

            return FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header azul
                    Container(
                      color: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.nomeTema} · ${widget.nomeFase}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Questão ${ctrl.indiceAtual + 1} / ${ctrl.totalQuestoes}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Barra de timer + número
                    QuizTimerBar(
                      percentual: ctrl.percentualTempo,
                      segundos: ctrl.segundosRestantes,
                    ),

                    // Card da pergunta
                    QuizQuestaoCard(pergunta: card.pergunta),

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
              ),
            );
          },
        ),
      ),
    );
  }
}
