// lib/widgets/bichinho/bichinho_sprite.dart
// Renderiza uma matriz pixel via CustomPainter, com bounce idle opcional e humor.
import 'dart:async';
import 'package:flutter/material.dart';
import 'sprites.dart';

/// Humor do bichinho — muda opacidade/efeitos, não o sprite inteiro.
enum HumorBichinho { feliz, neutro, comFome, dormindo }

class BichinhoSprite extends StatefulWidget {
  final int temaId;
  final int estagio; // 0=ovo..4=lendário
  final HumorBichinho humor;
  final double tamanho;
  final bool animado; // bounce idle de 1px

  const BichinhoSprite({
    super.key,
    required this.temaId,
    required this.estagio,
    this.humor = HumorBichinho.feliz,
    this.tamanho = 48,
    this.animado = true,
  });

  @override
  State<BichinhoSprite> createState() => _BichinhoSpriteState();
}

class _BichinhoSpriteState extends State<BichinhoSprite> {
  bool _up = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animado) {
      _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
        if (mounted) setState(() => _up = !_up);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final especie = Sprites.especiePara(widget.temaId);
    final matriz =
        widget.estagio == 0 ? Sprites.ovo : especie.estagios[widget.estagio - 1];
    final deslocamento = _up ? -widget.tamanho / 48 : 0.0;

    return SizedBox(
      width: widget.tamanho,
      height: widget.tamanho,
      child: Transform.translate(
        offset: Offset(0, deslocamento),
        child: Opacity(
          // dormindo = esmaecido
          opacity: widget.humor == HumorBichinho.dormindo ? 0.55 : 1.0,
          child: CustomPaint(painter: _PixelPainter(matriz, especie.palette)),
        ),
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  final List<List<int>> matriz;
  final List<Color> palette;
  _PixelPainter(this.matriz, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 16;
    final paint = Paint();
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final v = matriz[y][x];
        if (v == 0) continue;
        paint.color = palette[v - 1];
        canvas.drawRect(Rect.fromLTWH(x * px, y * px, px + 0.5, px + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) =>
      old.matriz != matriz || old.palette != palette;
}
