// lib/screens/flashcard/flashcard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/flashcard_controller.dart';

class FlashcardScreen extends StatefulWidget {
  final int faseId;
  final String nomeFase;
  final String nomeTema;

  const FlashcardScreen({
    super.key,
    required this.faseId,
    required this.nomeFase,
    required this.nomeTema,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
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
      context.read<FlashcardController>().carregarSessao(
            widget.faseId,
            widget.nomeFase,
            widget.nomeTema,
          );
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
    context.read<FlashcardController>().virar();
  }

  Future<void> _avaliar(int nivelSrs) async {
    await context.read<FlashcardController>().avaliar(nivelSrs);
    _flipCtrl.reset();
    setState(() => _mostrandoFrente = true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FlashcardController>();

    return Scaffold(
      backgroundColor: const Color(0xFF151C35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nomeFase,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(widget.nomeTema,
                style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
          ],
        ),
      ),
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : ctrl.sessaoConcluida
              ? _buildSessaoConcluida(context, ctrl)
              : _buildSessao(context, ctrl),
    );
  }

  Widget _buildSessao(BuildContext context, FlashcardController ctrl) {
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
                        ? _CardFace(
                            texto: card.pergunta,
                            label: 'PERGUNTA',
                            cor: const Color(0xFF1C2040),
                            corBorda: const Color(0xFF3A3A5A),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: _CardFace(
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

  Widget _buildBotoesAvaliacao(FlashcardController ctrl) {
    return AnimatedOpacity(
      opacity: ctrl.virado ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !ctrl.virado,
        child: Row(
          children: [
            _BotaoAvaliacao(
              emoji: '😓',
              label: 'Difícil',
              cor: const Color(0xFFB71C1C),
              corBorda: const Color(0xFFEF9A9A),
              onTap: () => _avaliar(0),
            ),
            const SizedBox(width: 10),
            _BotaoAvaliacao(
              emoji: '🤔',
              label: 'Médio',
              cor: const Color(0xFFE65100),
              corBorda: const Color(0xFFFFCC80),
              onTap: () => _avaliar(1),
            ),
            const SizedBox(width: 10),
            _BotaoAvaliacao(
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

  Widget _buildSessaoConcluida(BuildContext context, FlashcardController ctrl) {
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
                'Sessão concluída!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctrl.totalSessao} cards revisados',
                style: const TextStyle(fontSize: 14, color: Color(0xFF90CAF9)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar à trilha',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
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

class _CardFace extends StatelessWidget {
  final String texto;
  final String label;
  final Color cor;
  final Color corBorda;

  const _CardFace({
    required this.texto,
    required this.label,
    required this.cor,
    required this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Text(
            texto,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BotaoAvaliacao extends StatelessWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corBorda;
  final VoidCallback onTap;

  const _BotaoAvaliacao({
    required this.emoji,
    required this.label,
    required this.cor,
    required this.corBorda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: corBorda, width: 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
