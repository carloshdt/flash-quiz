// lib/widgets/papel/botao_papel.dart
// Botão que "afunda" ao pressionar: scale 0.97 + sombra some. Substitui ripple.
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';

class BotaoPapel extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color cor;
  final EdgeInsetsGeometry padding;

  const BotaoPapel({
    super.key,
    required this.onPressed,
    required this.child,
    this.cor = AppColors.laranja,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  State<BotaoPapel> createState() => _BotaoPapelState();
}

class _BotaoPapelState extends State<BotaoPapel> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: habilitado,
      child: GestureDetector(
      onTapDown: habilitado ? (_) => setState(() => _pressionado = true) : null,
      onTapCancel: () => setState(() => _pressionado = false),
      onTapUp: habilitado
          ? (_) {
              setState(() => _pressionado = false);
              // Haptic via AudioService — respeita o toggle haptics_ativo
              vibrarSeDisponivel(context, Vibracao.leve);
              widget.onPressed!();
            }
          : null,
        child: AnimatedScale(
          scale: _pressionado ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: ConstrainedBox(
            // alvo mínimo de toque (acessibilidade)
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: habilitado ? widget.cor : AppColors.grao,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _pressionado || !habilitado
                    ? []
                    : const [
                        BoxShadow(color: Color(0x40000000), offset: Offset(2, 3), blurRadius: 0)
                      ],
              ),
              child: DefaultTextStyle(
                style: (Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(fontSize: 18))
                    .copyWith(color: Colors.white),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
