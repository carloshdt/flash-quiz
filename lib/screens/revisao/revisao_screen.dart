// lib/screens/revisao/revisao_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/revisao_controller.dart';
import '../../theme/app_theme.dart';
import '../flashcard/widgets/botao_avaliacao.dart';
import '../flashcard/widgets/card_face.dart';

class RevisaoScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const RevisaoScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<RevisaoScreen> createState() => _RevisaoScreenState();
}

class _RevisaoScreenState extends State<RevisaoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _mostrandoFrente = true;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<RevisaoController>()
          .carregarSessao(widget.temaId, widget.nomeTema);
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _virar() {
    if (!_mostrandoFrente) return;
    _flipCtrl.forward();
    setState(() => _mostrandoFrente = false);
    context.read<RevisaoController>().virar();
  }

  Future<void> _avaliar(int nivelSrs) async {
    await context.read<RevisaoController>().avaliar(nivelSrs);
    _flipCtrl.reset();
    setState(() => _mostrandoFrente = true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RevisaoController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revisão Inteligente 🧠',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(widget.nomeTema,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: ctrl.carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : ctrl.tudoEmDia
              ? _buildTudoEmDia(context)
              : ctrl.sessaoConcluida
                  ? _buildSessaoConcluida(context, ctrl)
                  : _buildSessao(context, ctrl),
    );
  }

  Widget _buildSessao(BuildContext context, RevisaoController ctrl) {
    final card = ctrl.cardAtual!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: ctrl.virado ? null : _virar,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  final angulo = _flipAnim.value;
                  final mostrarFrente = angulo < pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angulo),
                    child: mostrarFrente
                        ? CardFace(
                            texto: card.pergunta,
                            label: 'PERGUNTA',
                            cor: const Color(0xFF1C2040),
                            corBorda: const Color(0xFF3A3A5A),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: CardFace(
                              texto: card.resposta,
                              label: 'RESPOSTA',
                              cor: const Color(0xFF1A2A1A),
                              corBorda: const Color(0xFF2A5A2A),
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: ctrl.virado ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'Toque no card para ver a resposta',
                style: TextStyle(fontSize: 12, color: Color(0xFF555577)),
              ),
            ),
            const Spacer(),
            _buildBotoesAvaliacao(ctrl),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAvaliacao(RevisaoController ctrl) {
    return AnimatedOpacity(
      opacity: ctrl.virado ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !ctrl.virado,
        child: Row(
          children: [
            BotaoAvaliacao(
              emoji: '😓',
              label: 'Difícil',
              cor: const Color(0xFFB71C1C),
              corBorda: const Color(0xFFEF9A9A),
              onTap: () => _avaliar(0),
            ),
            const SizedBox(width: 10),
            BotaoAvaliacao(
              emoji: '🤔',
              label: 'Médio',
              cor: const Color(0xFFE65100),
              corBorda: const Color(0xFFFFCC80),
              onTap: () => _avaliar(1),
            ),
            const SizedBox(width: 10),
            BotaoAvaliacao(
              emoji: '😊',
              label: 'Fácil',
              cor: const Color(0xFF1B5E20),
              corBorda: const Color(0xFFA5D6A7),
              onTap: () => _avaliar(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTudoEmDia(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Tudo em dia!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nenhum card para revisar agora. Volte mais tarde.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessaoConcluida(BuildContext context, RevisaoController ctrl) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Revisão concluída!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctrl.totalSessao} cards revisados',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar ao tema',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
