// test/widgets/bichinho_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flashquiz/models/bichinho.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_widget.dart';

void main() {
  setUpAll(() {
    // Header usa GoogleFonts (VT323): sem rede em teste, o fetch da fonte
    // falharia num erro assíncrono — desligamos e caímos no fallback.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('BichinhoHeader mostra estágio e barra de energia', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 1, energia: 80);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BichinhoHeader(
          bichinho: b,
          humor: HumorBichinho.feliz,
          proximoThreshold: 200,
          animado: false, // sem bounce — evita pending timer no teste
        ),
      ),
    ));
    expect(find.text('Filhote'), findsOneWidget);
    expect(find.text('80/200'), findsOneWidget);
  });

  testWidgets('BichinhoHeader lendário não mostra barra', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 4, energia: 1500);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BichinhoHeader(
          bichinho: b,
          humor: HumorBichinho.feliz,
          proximoThreshold: null,
          animado: false,
        ),
      ),
    ));
    expect(find.text('Lendário'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('BichinhoMini renderiza sprite compacto', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 2, energia: 300);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BichinhoMini(bichinho: b, humor: HumorBichinho.neutro, animado: false),
      ),
    ));
    expect(find.byType(BichinhoMini), findsOneWidget);
  });
}
