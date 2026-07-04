// lib/widgets/papel/barra_papel.dart
// Barra de progresso estilo papel: borda de tinta com preenchimento colorido.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BarraPapel extends StatelessWidget {
  final double progresso;
  final Color cor;
  final double altura;

  const BarraPapel(this.progresso, this.cor, {super.key, this.altura = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.tinta, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progresso.clamp(0.0, 1.0),
          child: Container(color: cor),
        ),
      ),
    );
  }
}
