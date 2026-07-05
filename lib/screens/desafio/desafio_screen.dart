// lib/screens/desafio/desafio_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/desafio_controller.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/papel/botao_papel.dart';
import '../../widgets/papel/fundo_papel.dart';
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
  int _ultimoIndice = -1; // detecta avanço de questão pra vibrar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DesafioController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  // Haptic de avanço de questão — respeita o toggle haptics_ativo
  void _vibrarAvanco() {
    try {
      context.read<AudioService>().vibrar(Vibracao.selecao);
    } on ProviderNotFoundException {
      // sem provider (testes) — sem haptic
    }
  }

  Future<bool> _onWillPop() async {
    final ctrl = context.read<DesafioController>();
    // Carregando ou pool vazio: sai direto, nada a abandonar
    if (ctrl.carregando || ctrl.poolVazio) {
      if (mounted) context.pop();
      return false;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cartao,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Sair do desafio?',
            style: Theme.of(context).textTheme.titleLarge),
        content: const Text(
          'A tentativa será registrada como abandonada e o desafio de hoje continua disponível.',
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
        backgroundColor: AppColors.papel,
        body: FundoPapel(
          child: Consumer<DesafioController>(
            builder: (_, ctrl, __) {
              if (ctrl.carregando) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.laranja));
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
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.laranja));
              }

              // Avançou de questão → haptic de seleção
              if (_ultimoIndice != -1 && ctrl.indiceAtual != _ultimoIndice) {
                _vibrarAvanco();
              }
              _ultimoIndice = ctrl.indiceAtual;

              final card = ctrl.questaoAtual!;
              final tempoEsgotado = ctrl.estado == EstadoQuestaoDesafio.tempoEsgotado;
              final selecionada = ctrl.estado == EstadoQuestaoDesafio.selecionada;

              return SafeArea(
                child: Column(
                  children: [
                    // Header papel do desafio: acento laranja no sublinhado
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.tintaSuave),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Questão ${ctrl.indiceAtual + 1} / ${ctrl.totalQuestoes}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 3,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.laranja,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
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
                    QuizQuestaoCard(pergunta: card.pergunta, seed: card.id),
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
              Text(
                'Nada por aqui ainda',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Estude uma fase primeiro para liberar o desafio deste tema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.tintaSuave),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: BotaoPapel(
                  onPressed: onVoltar,
                  child: const Center(child: Text('Voltar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
