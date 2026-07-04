// lib/widgets/papel/entrada_cascata.dart
// Entrada em cascata: fade + deslize curto, com delay proporcional ao índice.
import 'package:flutter/material.dart';

class EntradaCascata extends StatefulWidget {
  final int index;
  final Widget child;
  const EntradaCascata({super.key, required this.index, required this.child});

  @override
  State<EntradaCascata> createState() => _EntradaCascataState();
}

class _EntradaCascataState extends State<EntradaCascata> {
  bool _visivel = false;

  @override
  void initState() {
    super.initState();
    // Delay proporcional ao índice cria o efeito cascata na lista
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) setState(() => _visivel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visivel ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: AnimatedSlide(
        offset: _visivel ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
