// lib/widgets/papel/carimbo_batida.dart
// Carimbo com animação de batida: cai de cima (scale 1.6 → 1.0) como se
// estampado na página. Som + haptic da batida são do próprio widget;
// onBatida (opcional) dispara depois, para efeitos extras da tela.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import 'carimbo.dart';

class CarimboBatida extends StatefulWidget {
  final String texto;
  final Color cor;
  final double fontSize;
  final VoidCallback? onBatida;

  const CarimboBatida({
    super.key,
    required this.texto,
    this.cor = AppColors.verde,
    this.fontSize = 32,
    this.onBatida,
  });

  @override
  State<CarimboBatida> createState() => _CarimboBatidaState();
}

class _CarimboBatidaState extends State<CarimboBatida> {
  bool _bateu = false; // garante efeitos da batida 1x

  void _aoCompletarBatida() {
    if (_bateu || !mounted) return;
    _bateu = true;
    // Efeito do próprio carimbo — sem AudioService no Provider (testes): no-op
    try {
      context.read<AudioService>()
        ..tocar(Som.carimbo)
        ..vibrar(Vibracao.media);
    } on ProviderNotFoundException {
      // sem provider — segue sem som/haptic
    }
    widget.onBatida?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.6, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      onEnd: _aoCompletarBatida,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Carimbo(
        texto: widget.texto,
        cor: widget.cor,
        fontSize: widget.fontSize,
      ),
    );
  }
}
