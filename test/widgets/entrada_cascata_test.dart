// test/widgets/entrada_cascata_test.dart
// EntradaCascata: invisível antes do delay proporcional ao índice,
// visível depois, e desmontar antes do delay não explode.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/widgets/papel/entrada_cascata.dart';

void main() {
  testWidgets('child invisível no pump inicial e visível após delay + animação',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EntradaCascata(index: 5, child: Text('oi')),
    ));

    // Antes do delay (5 * 40ms = 200ms) o alvo de opacidade ainda é 0
    final antes = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(antes.opacity, 0);

    // Após o delay o setState dispara e a animação (250ms) completa
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 250));
    final depois = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(depois.opacity, 1);
  });

  testWidgets('desmontar antes do delay não explode', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EntradaCascata(index: 10, child: Text('oi')),
    ));

    // Remove o widget antes do delay (10 * 40ms = 400ms) disparar
    await tester.pumpWidget(const SizedBox());

    // Deixa o timer pendente disparar — com mounted=false nada pode lançar
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
