// test/widgets/evolucao_confete_test.dart
// Cobre mostrarEvolucao (fases da animação + auto-close), ConfetePapel e
// mostrarBichinhoPopup (conteúdo do bottom sheet).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flashquiz/models/bichinho.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_popup.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_sprite.dart';
import 'package:flashquiz/widgets/bichinho/evolucao_overlay.dart';
import 'package:flashquiz/widgets/confete/confete_papel.dart';

void main() {
  setUpAll(() {
    // Sem rede em teste — evita fetch assíncrono da VT323 falhar.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('mostrarEvolucao passa pelas 3 fases e fecha sozinho', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 2, energia: 300);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => mostrarEvolucao(context, b),
              child: const Text('evoluir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('evoluir'));
    await tester.pump(); // monta o diálogo — controller em t=0

    // fase 1 (t < 0.4): sprite antigo tremendo, sem texto ainda
    expect(find.byType(BichinhoSprite), findsOneWidget);
    expect(find.text('EVOLUIU!'), findsNothing);

    // fase 2 (0.4 <= t < 0.6): flash branco, sem sprite
    await tester.pump(const Duration(milliseconds: 900)); // t = 0.5
    expect(find.byType(BichinhoSprite), findsNothing);
    expect(find.text('EVOLUIU!'), findsNothing);

    // fase 3 (t >= 0.6): sprite novo saltando + texto
    await tester.pump(const Duration(milliseconds: 700)); // t ≈ 0.89
    expect(find.text('EVOLUIU!'), findsOneWidget);
    expect(find.byType(BichinhoSprite), findsOneWidget);

    // controller completa neste frame (>=1800ms) e agenda o pop pra +800ms
    await tester.pump(const Duration(milliseconds: 300)); // 1900ms
    await tester.pump(const Duration(milliseconds: 900)); // 2800ms — pop dispara
    await tester.pumpAndSettle(); // transição reversa do diálogo
    expect(find.text('EVOLUIU!'), findsNothing);
    expect(find.byType(BichinhoSprite), findsNothing);
  });

  testWidgets('ConfetePapel renderiza e completa a animação sem erro', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ConfetePapel())));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ConfetePapel),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    // avança além dos 2000ms do controller — não pode lançar nem vazar timer
    await tester.pump(const Duration(milliseconds: 2100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostrarBichinhoPopup mostra estágio, energia e dica do humor',
      (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 1, energia: 80);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => mostrarBichinhoPopup(
                context,
                bichinho: b,
                humor: HumorBichinho.comFome,
                proximoThreshold: 200,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    // O sprite do popup anima (timer periódico) — pumps fixos em vez de
    // pumpAndSettle pra não depender do timer assentar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Filhote'), findsOneWidget);
    expect(find.text('80/200 energia'), findsOneWidget);
    expect(find.text('Tá com fome! Alimente com 3 cards.'), findsOneWidget);

    // fecha o sheet — descarta o sprite e cancela o timer antes do fim do teste
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Filhote'), findsNothing);
  });
}
