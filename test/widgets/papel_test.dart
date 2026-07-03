// test/widgets/papel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flashquiz/widgets/papel/papel_card.dart';
import 'package:flashquiz/widgets/papel/botao_papel.dart';
import 'package:flashquiz/widgets/papel/post_it.dart';
import 'package:flashquiz/widgets/papel/carimbo.dart';
import 'package:flashquiz/widgets/papel/linha_costura.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() {
    // Carimbo usa GoogleFonts (Patrick Hand): sem rede em teste, o fetch da
    // fonte falharia num erro assíncrono — desligamos e caímos no fallback.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('PapelCard renderiza filho e rotação é determinística', (tester) async {
    await tester.pumpWidget(_wrap(const PapelCard(seed: 42, child: Text('oi'))));
    expect(find.text('oi'), findsOneWidget);
    final t1 = tester.widget<Transform>(find.byType(Transform).first).transform;
    await tester.pumpWidget(_wrap(const PapelCard(seed: 42, child: Text('oi'))));
    final t2 = tester.widget<Transform>(find.byType(Transform).first).transform;
    expect(t1, t2); // mesma seed = mesma rotação
  });

  testWidgets('BotaoPapel dispara onPressed', (tester) async {
    var apertou = false;
    await tester.pumpWidget(_wrap(BotaoPapel(
      onPressed: () => apertou = true,
      child: const Text('Bora'),
    )));
    await tester.tap(find.text('Bora'));
    await tester.pumpAndSettle();
    expect(apertou, isTrue);
  });

  testWidgets('BotaoPapel desabilitado não dispara nada ao tap', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const BotaoPapel(
      onPressed: null,
      child: Text('Bora'),
    )));
    // tap não lança nem dispara nada (onPressed é null)
    await tester.tap(find.text('Bora'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Bora'), findsOneWidget);
    // e o leitor de tela enxerga um botão desabilitado
    expect(
      tester.getSemantics(find.text('Bora')),
      isSemantics(isButton: true, isEnabled: false),
    );
    semantics.dispose();
  });

  testWidgets('PostIt e Carimbo renderizam texto', (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [
      PostIt(child: Text('lembrete')),
      Carimbo(texto: 'APROVADO'),
      LinhaCostura(),
    ])));
    expect(find.text('lembrete'), findsOneWidget);
    expect(find.text('APROVADO'), findsOneWidget);
  });
}
