// lib/screens/flashcard/widgets/botao_avaliacao.dart
// Botão de autoavaliação SRS (Difícil / Médio / Fácil) — estilo papel:
// sombra dura que some + scale 0.97 ao pressionar (mesmo padrão do BotaoPapel).
import 'package:flutter/material.dart';

class BotaoAvaliacao extends StatefulWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corTexto;
  final VoidCallback onTap;

  const BotaoAvaliacao({
    super.key,
    required this.emoji,
    required this.label,
    required this.cor,
    this.corTexto = Colors.white,
    required this.onTap,
  });

  @override
  State<BotaoAvaliacao> createState() => _BotaoAvaliacaoState();
}

class _BotaoAvaliacaoState extends State<BotaoAvaliacao> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressionado = true),
          onTapCancel: () => setState(() => _pressionado = false),
          onTapUp: (_) {
            setState(() => _pressionado = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressionado ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: widget.cor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _pressionado
                    ? []
                    : const [
                        BoxShadow(
                            color: Color(0x40000000),
                            offset: Offset(2, 3),
                            blurRadius: 0),
                      ],
              ),
              child: Column(
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(widget.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.corTexto,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
