// lib/screens/desafio/desafio_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/desafio_controller.dart';
import '../../theme/app_theme.dart';
import '../quiz/widgets/quiz_alternativas.dart';
import '../quiz/widgets/quiz_questao_card.dart';
import '../quiz/widgets/quiz_timer_bar.dart';
import '../quiz/widgets/tempo_esgotado_banner.dart';

class DesafioScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const DesafioScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<DesafioScreen> createState() => _DesafioScreenState();
}

class _DesafioScreenState extends State<DesafioScreen> {
  bool _concluindo = false;
  bool _navegandoParaResultado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DesafioController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  Future<bool> _onWillPop() async {
    final ctrl = context.read<DesafioController>();
    // Pool vazio: sai direto, nada a abandonar
    if (ctrl.poolVazio) {
      if (mounted) context.pop();
      return false;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sheetBg,
        title: const Text('Sair do desafio?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'A tentativa será registrada como abandonada e o desafio de hoje continua disponível.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<DesafioController>().abandonar();
      if (mounted) context.pop();
    }
    return false;
  }

  Future<void> _irParaResultado(DesafioController ctrl) async {
    if (_concluindo) return;
    _concluindo = true;
    final resultado = await ctrl.concluir();
    if (!mounted) return;
    context.pushReplacement('/desafio-resultado', extra: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onWillPop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<DesafioController>(
          builder: (_, ctrl, __) {
            if (ctrl.carregando) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            if (ctrl.poolVazio) {
              return _EstadoVazio(onVoltar: () => context.pop());
            }

            if (ctrl.desafioConcluido) {
              if (!_navegandoParaResultado) {
                _navegandoParaResultado = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _irParaResultado(ctrl);
                });
              }
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            final card = ctrl.questaoAtual!;
            final tempoEsgotado = ctrl.estado == EstadoQuestaoDesafio.tempoEsgotado;
            final selecionada = ctrl.estado == EstadoQuestaoDesafio.selecionada;

            return SafeArea(
              child: Column(
                children: [
                  // Header laranja do desafio
                  Container(
                    color: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desafio Diário · ${widget.nomeTema}',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
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
                      ],
                    ),
                  ),
                  QuizTimerBar(
                    percentual: ctrl.percentualTempo,
                    segundos: ctrl.segundosRestantes,
                  ),
                  QuizQuestaoCard(pergunta: card.pergunta),
                  const SizedBox(height: 12),
                  if (tempoEsgotado)
                    TempoEsgotadoBanner(onTap: ctrl.avancarAposTempoEsgotado),
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
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onVoltar;

  const _EstadoVazio({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📖', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Nada por aqui ainda',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estude uma fase primeiro para liberar o desafio deste tema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onVoltar,
                  child: const Text('Voltar',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
