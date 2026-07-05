// lib/widgets/papel/papel_util.dart
// Utilitários compartilhados dos widgets de papel.
import 'dart:math' as math;
import 'dart:ui';

/// Converte graus em radianos (rotação dos elementos de papel).
double grausParaRad(double graus) => graus * math.pi / 180;

/// Desenha um path tracejado (costura) — padrão visual do design system.
void desenharTracejado(
  Canvas canvas,
  Path path,
  Paint paint, {
  double dash = 8,
  double gap = 6,
}) {
  for (final metric in path.computeMetrics()) {
    double distancia = 0;
    while (distancia < metric.length) {
      final fim = (distancia + dash).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distancia, fim), paint);
      distancia += dash + gap;
    }
  }
}
