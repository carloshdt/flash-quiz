// lib/screens/secoes/secoes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../controllers/secoes_controller.dart';
import '../../models/secao.dart';
import '../../services/metrica_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bichinho/bichinho_popup.dart';
import '../../widgets/bichinho/bichinho_widget.dart';
import '../../widgets/papel/barra_papel.dart';
import '../../widgets/papel/entrada_cascata.dart';
import '../../widgets/papel/fundo_papel.dart';
import '../../widgets/papel/papel_card.dart';
import '../../widgets/papel/post_it.dart';

class SecoesScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const SecoesScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<SecoesScreen> createState() => _SecoesScreenState();
}

class _SecoesScreenState extends State<SecoesScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecoesController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Chamado quando uma rota acima desta é removida e esta volta ao topo
  @override
  void didPopNext() {
    context.read<SecoesController>().carregar(widget.temaId, widget.nomeTema);
  }

  void _navegarParaTrilha(BuildContext context, Secao secao) {
    MetricaService().secaoSelecionada(secao.id, secao.nome, widget.nomeTema);
    context.push(
      '/tema/${widget.temaId}/secao/${secao.id}/trilha'
      '?nomeSecao=${Uri.encodeComponent(secao.nome)}'
      '&nomeTema=${Uri.encodeComponent(widget.nomeTema)}',
    );
  }

  void _abrirModo(BuildContext context, String rota) {
    context.push('$rota/${widget.temaId}?nomeTema=${Uri.encodeComponent(widget.nomeTema)}');
  }

  void _abrirPopupBichinho(BuildContext context, SecoesController ctrl) {
    ctrl.registrarPopupAberto();
    mostrarBichinhoPopup(
      context,
      bichinho: ctrl.bichinho!,
      humor: ctrl.humorBichinho,
      proximoThreshold: ctrl.proximoThreshold,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SecoesController>();
    final acento = AppColors.accentFor(widget.temaId);

    return Scaffold(
      backgroundColor: AppColors.papel,
      appBar: AppBar(
        backgroundColor: AppColors.papel,
        elevation: 0,
        title: Text(widget.nomeTema),
      ),
      body: FundoPapel(
        child: ctrl.carregando
            ? const Center(child: CircularProgressIndicator(color: AppColors.laranja))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bichinho do tema com barra de energia
                  if (ctrl.bichinho != null) ...[
                    BichinhoHeader(
                      bichinho: ctrl.bichinho!,
                      humor: ctrl.humorBichinho,
                      proximoThreshold: ctrl.proximoThreshold,
                      onTap: () => _abrirPopupBichinho(context, ctrl),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Barra de progresso geral
                  PapelCard(
                    seed: widget.temaId,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progresso geral',
                                style: TextStyle(fontSize: 11, color: AppColors.tintaSuave)),
                            Text(
                              '${(ctrl.progressoGeral * 100).round()}% concluído',
                              style: const TextStyle(fontSize: 11, color: AppColors.tintaSuave),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        BarraPapel(ctrl.progressoGeral, acento, altura: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Modos de estudo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.tintaSuave),
                  ),
                  const SizedBox(height: 8),
                  _ModoPostIt(
                    emoji: '⚡',
                    titulo: 'Desafio Diário',
                    subtitulo: ctrl.notaDesafioHoje != null
                        ? '✓ Feito hoje · ${ctrl.notaDesafioHoje} pontos'
                        : '${ctrl.desafioNumQuestoes} questões · uma vez por dia',
                    cor: AppColors.amarelo,
                    angulo: -1.5,
                    desabilitado: ctrl.notaDesafioHoje != null,
                    onTap: () => _abrirModo(context, '/desafio'),
                  ),
                  const SizedBox(height: 10),
                  _ModoPostIt(
                    emoji: '🧠',
                    titulo: 'Revisão Inteligente',
                    subtitulo: ctrl.cardsVencidos > 0
                        ? '${ctrl.cardsVencidos} cards para revisar'
                        : 'Tudo em dia',
                    cor: AppColors.postItAzul,
                    angulo: 1,
                    onTap: () => _abrirModo(context, '/revisao'),
                  ),
                  const SizedBox(height: 10),
                  _ModoPostIt(
                    emoji: '🏃',
                    titulo: 'Maratona',
                    subtitulo: ctrl.recordeMaratona > 0
                        ? 'Recorde: ${ctrl.recordeMaratona} acertos'
                        : 'Responda até errar ${ctrl.maratonaMaxErros}',
                    cor: AppColors.postItVerde,
                    angulo: -1,
                    onTap: () => _abrirModo(context, '/maratona'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Escolha uma seção',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.tintaSuave),
                  ),
                  const SizedBox(height: 8),
                  ...ctrl.secoes.asMap().entries.map((entry) => EntradaCascata(
                        index: entry.key,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SecaoCard(
                            secao: entry.value,
                            destaque: entry.value.ordem == 0,
                            percentual: ctrl.progressoPorSecao[entry.value.id] ?? 0.0,
                            acento: acento,
                            onTap: () => _navegarParaTrilha(context, entry.value),
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}

class _SecaoCard extends StatelessWidget {
  final Secao secao;
  final bool destaque;
  final double percentual;
  final Color acento;
  final VoidCallback onTap;

  const _SecaoCard({
    required this.secao,
    required this.destaque,
    required this.percentual,
    required this.acento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: PapelCard(
        seed: secao.id,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(secao.icone, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    secao.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.chevron_right, color: destaque ? acento : AppColors.tintaSuave),
              ],
            ),
            const SizedBox(height: 8),
            BarraPapel(percentual, acento, altura: 8),
            const SizedBox(height: 2),
            Text(
              '${(percentual * 100).round()}%',
              style: const TextStyle(fontSize: 9, color: AppColors.tintaSuave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModoPostIt extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final double angulo;
  final bool desabilitado;
  final VoidCallback onTap;

  const _ModoPostIt({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.angulo,
    this.desabilitado = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: desabilitado ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: desabilitado ? null : onTap,
        child: PostIt(
          cor: cor,
          angulo: angulo,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.tintaSuave),
                    ),
                  ],
                ),
              ),
              if (!desabilitado) const Icon(Icons.chevron_right, color: AppColors.tinta),
            ],
          ),
        ),
      ),
    );
  }
}
