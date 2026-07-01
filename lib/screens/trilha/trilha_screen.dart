// lib/screens/trilha/trilha_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Posição ziguezague: começa no centro, vai pra direita, centro, esquerda
  double _posicaoHorizontal(int index) {
    const posicoes = [0.5, 0.78, 0.5, 0.22];
    return posicoes[index % posicoes.length];
  }

  void _abrirBottomSheetFase(BuildContext context, ItemTrilha item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetFase(
        item: item,
        onIniciar: () {
          context.push(
            '/flashcard/${item.fase.id}'
            '?nomeFase=${Uri.encodeComponent(item.fase.nome)}'
            '&nomeTema=${Uri.encodeComponent(widget.nomeTema)}',
          );
        },
      ),
    );
  }

  void _abrirBottomSheetQuiz(BuildContext context, ItemTrilha item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetQuiz(item: item, nomeTema: widget.nomeTema),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrilhaController>();
    final totalFases = ctrl.itens.where((i) => !i.ehQuiz).length;
    final fasesCompletas = ctrl.itens.where((i) => !i.ehQuiz && i.concluido).length;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 3 nós visíveis: rowHeight = 1/3 da altura útil (desconta AppBar ~110px)
    final rowHeight = (screenHeight - 110) / 3;
    final nodeSizeFase = rowHeight * 0.46;
    final nodeSizeQuiz = rowHeight * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFF151C35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2F6E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nomeTema,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(widget.nomeSecao,
                style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
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
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : SafeArea(
        top: false,
        child: CustomScrollView(
        reverse: true,
        slivers: [
          SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = ctrl.itens[index];
                    final posH = _posicaoHorizontal(index);
                    final nodeSize = item.ehQuiz ? nodeSizeQuiz : nodeSizeFase;

                    final temProximo = index < ctrl.itens.length - 1;
                    final nextPosH =
                        temProximo ? _posicaoHorizontal(index + 1) : posH;

                    return SizedBox(
                      height: rowHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Conector diagonal vai de baixo pra cima (reverse: true)
                          if (temProximo)
                            Positioned.fill(
                              child: ClipRect(
                                child: CustomPaint(
                                  painter: _ConectorPainter(
                                    xInicio: screenWidth * posH,
                                    yInicio: rowHeight - nodeSize, // topo do nó (nó fica embaixo)
                                    xFim: screenWidth * nextPosH,
                                    yFim: 0, // topo do widget = fundo do próximo item
                                    cor: item.concluido
                                        ? const Color(0xFF7C4DFF)
                                        : const Color(0xFF3A3A5A),
                                  ),
                                ),
                              ),
                            ),

                          // Nó no fundo do row, label acima
                          Positioned(
                            left: screenWidth * posH - (nodeSize + 16) / 2,
                            bottom: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: nodeSize + 16,
                                  child: Text(
                                    item.ehQuiz ? 'Quiz' : item.fase.nome,
                                    style: TextStyle(
                                      fontSize: 11,
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
                                const SizedBox(height: 4),
                                item.ehQuiz
                                    ? NoQuizWidget(
                                        item: item,
                                        size: nodeSizeQuiz,
                                        onTap: () =>
                                            _abrirBottomSheetQuiz(context, item),
                                      )
                                    : NoFaseWidget(
                                        item: item,
                                        size: nodeSizeFase,
                                        onTap: () =>
                                            _abrirBottomSheetFase(context, item),
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
      ),
    );
  }
}

class _ConectorPainter extends CustomPainter {
  final double xInicio;
  final double yInicio;
  final double xFim;
  final double yFim;
  final Color cor;

  const _ConectorPainter({
    required this.xInicio,
    required this.yInicio,
    required this.xFim,
    required this.yFim,
    required this.cor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mid = yInicio + (yFim - yInicio) * 0.5;

    final path = Path()
      ..moveTo(xInicio, yInicio)
      ..cubicTo(xInicio, mid, xFim, mid, xFim, yFim);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConectorPainter old) =>
      old.xInicio != xInicio ||
      old.xFim != xFim ||
      old.yInicio != yInicio ||
      old.yFim != yFim ||
      old.cor != cor;
}
