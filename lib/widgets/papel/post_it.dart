// lib/widgets/papel/post_it.dart
// Post-it com dobra de canto e leve rotação.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'papel_util.dart';

class PostIt extends StatelessWidget {
  final Widget child;
  final Color cor;
  final double angulo; // graus

  const PostIt({super.key, required this.child, this.cor = AppColors.amarelo, this.angulo = -2});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: grausParaRad(angulo),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor,
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), offset: Offset(1, 2), blurRadius: 0),
              ],
            ),
            child: child,
          ),
          // dobra do canto inferior direito
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(size: const Size(14, 14), painter: _DobraPainter(cor)),
          ),
        ],
      ),
    );
  }
}

class _DobraPainter extends CustomPainter {
  final Color cor;
  _DobraPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final sombra = Paint()..color = Colors.black.withValues(alpha: 0.15);
    final dobra = Paint()..color = Color.lerp(cor, Colors.black, 0.18)!;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, sombra);
    canvas.drawPath(path, dobra);
  }

  @override
  bool shouldRepaint(covariant _DobraPainter old) => old.cor != cor;
}
