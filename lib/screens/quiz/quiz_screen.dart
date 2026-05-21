// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';

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
        backgroundColor: const Color(0xFF1E1E3A),
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
        backgroundColor: const Color(0xFF12122A),
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

            // Cor da barra de timer: roxo → vermelho quando < 30%
            final corTimer = ctrl.percentualTempo < 0.30
                ? const Color(0xFFFF3D00)
                : const Color(0xFF7C4DFF);

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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ctrl.percentualTempo,
                                backgroundColor: const Color(0xFF1A1A3A),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(corTimer),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${ctrl.segundosRestantes}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: corTimer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card da pergunta
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.pergunta,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white, height: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Timer esgotado: mensagem
                    if (tempoEsgotado)
                      GestureDetector(
                        onTap: ctrl.avancarAposTempoEsgotado,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF5252)),
                          ),
                          child: const Text(
                            'Tempo esgotado — toque para continuar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                      ),

                    // Alternativas
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: ctrl.alternativasAtual.length,
                        itemBuilder: (_, i) {
                          final letras = ['A', 'B', 'C', 'D'];
                          final selecionadaEsta =
                              ctrl.respostaSelecionada == i;
                          final desabilitada = tempoEsgotado || selecionada;

                          return GestureDetector(
                            onTap: desabilitada
                                ? null
                                : () => ctrl.selecionarResposta(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: selecionadaEsta
                                    ? const Color(0xFF7C4DFF).withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selecionadaEsta
                                      ? const Color(0xFF7C4DFF)
                                      : const Color(0xFF2A2A5A),
                                  width: selecionadaEsta ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    letras[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selecionadaEsta
                                          ? const Color(0xFF7C4DFF)
                                          : const Color(0xFF90CAF9),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      ctrl.alternativasAtual[i],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: selecionadaEsta
                                            ? Colors.white
                                            : const Color(0xFFCCCCCC),
                                        fontWeight: selecionadaEsta
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
