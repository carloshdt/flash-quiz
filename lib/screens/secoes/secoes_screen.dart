// lib/screens/secoes/secoes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/secoes_controller.dart';
import '../../models/secao.dart';
import '../../services/metrica_service.dart';
import '../../theme/app_theme.dart';

class SecoesScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const SecoesScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<SecoesScreen> createState() => _SecoesScreenState();
}

class _SecoesScreenState extends State<SecoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecoesController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  void _navegarParaTrilha(BuildContext context, Secao secao) {
    MetricaService().secaoSelecionada(secao.id, secao.nome, widget.nomeTema);
    context.push(
      '/tema/${widget.temaId}/secao/${secao.id}/trilha'
      '?nomeSecao=${Uri.encodeComponent(secao.nome)}'
      '&nomeTema=${Uri.encodeComponent(widget.nomeTema)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SecoesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.nomeTema, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Barra de progresso geral
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progresso geral',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${(ctrl.progressoGeral * 100).round()}% concluído',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ctrl.progressoGeral,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Escolha uma seção',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 8),
                ...ctrl.secoes.map((secao) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SecaoCard(
                    secao: secao,
                    destaque: secao.ordem == 0,
                    percentual: ctrl.progressoPorSecao[secao.id] ?? 0.0,
                    onTap: () => _navegarParaTrilha(context, secao),
                  ),
                )),
              ],
            ),
    );
  }
}

class _SecaoCard extends StatelessWidget {
  final Secao secao;
  final bool destaque;
  final double percentual;
  final VoidCallback onTap;

  const _SecaoCard({
    required this.secao,
    required this.destaque,
    required this.percentual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: destaque
              ? AppColors.headerBg.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destaque
                ? AppColors.purple.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.purple),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentual,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(percentual * 100).round()}%',
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
