// lib/screens/trilha/trilha_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trilha_controller.dart';
import 'widgets/no_fase_widget.dart';
import 'widgets/no_quiz_widget.dart';
import 'widgets/bottom_sheet_fase.dart';
import 'widgets/bottom_sheet_quiz.dart';

class TrilhaScreen extends StatefulWidget {
  final int temaId;
  final int secaoId;
  final String nomeSecao;
  final String nomeTema;

  const TrilhaScreen({
    super.key,
    required this.temaId,
    required this.secaoId,
    required this.nomeSecao,
    required this.nomeTema,
  });

  @override
  State<TrilhaScreen> createState() => _TrilhaScreenState();
}

class _TrilhaScreenState extends State<TrilhaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrilhaController>().carregar(widget.secaoId);
    });
  }

  // Posição ziguezague: cicla entre [0.15, 0.5, 0.85, 0.5]
  double _posicaoHorizontal(int index) {
    const posicoes = [0.15, 0.5, 0.85, 0.5];
    return posicoes[index % posicoes.length];
  }

  void _abrirBottomSheetFase(BuildContext context, ItemTrilha item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetFase(item: item),
    );
  }

  void _abrirBottomSheetQuiz(BuildContext context, ItemTrilha item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetQuiz(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrilhaController>();
    final totalFases = ctrl.itens.where((i) => !i.ehQuiz).length;
    final fasesCompletas = ctrl.itens.where((i) => !i.ehQuiz && i.concluido).length;

    return Scaffold(
      backgroundColor: const Color(0xFF12122A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF1565C0),
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nomeTema, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(widget.nomeSecao, style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: LinearProgressIndicator(
                  value: totalFases > 0 ? fasesCompletas / totalFases : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          if (ctrl.carregando)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = ctrl.itens[index];
                    final screenWidth = MediaQuery.of(context).size.width;
                    final posH = _posicaoHorizontal(index);
                    final nodeWidth = item.ehQuiz ? 46.0 : 56.0;
                    final nodeHeight = item.ehQuiz ? 46.0 : 56.0;

                    return SizedBox(
                      height: 90,
                      child: Stack(
                        children: [
                          // Conector vertical entre nós
                          if (index < ctrl.itens.length - 1)
                            Positioned(
                              left: screenWidth * posH - 1.5,
                              top: nodeHeight,
                              child: Container(
                                width: 3,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      item.concluido
                                          ? const Color(0xFF7C4DFF)
                                          : const Color(0xFF2A2A45),
                                      const Color(0xFF2A2A45),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                          // Nó principal
                          Positioned(
                            left: screenWidth * posH - nodeWidth / 2,
                            top: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                item.ehQuiz
                                    ? NoQuizWidget(
                                        item: item,
                                        onTap: () => _abrirBottomSheetQuiz(context, item),
                                      )
                                    : NoFaseWidget(
                                        item: item,
                                        onTap: () => _abrirBottomSheetFase(context, item),
                                      ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    item.ehQuiz ? 'Quiz' : item.fase.nome,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: item.desbloqueado
                                          ? const Color(0xFFE0E0E0)
                                          : const Color(0xFF555555),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: ctrl.itens.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
