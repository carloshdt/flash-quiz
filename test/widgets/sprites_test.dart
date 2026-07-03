// test/widgets/sprites_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/models/bichinho.dart';
import 'package:flashquiz/widgets/bichinho/sprites.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_sprite.dart';

void main() {
  test('todas as matrizes são 16x16 com índices de cor válidos', () {
    for (final especie in Sprites.especies) {
      // ovo é pintado com a palette da espécie — valida junto dos estágios
      for (final estagio in [...especie.estagios, Sprites.ovo]) {
        expect(estagio.length, 16, reason: 'altura deve ser 16');
        for (final linha in estagio) {
          expect(linha.length, 16, reason: 'largura deve ser 16');
          for (final pixel in linha) {
            expect(pixel >= 0 && pixel <= especie.palette.length, isTrue,
                reason: 'índice $pixel fora da palette');
          }
        }
      }
    }
  });

  test('ovo é 16x16', () {
    expect(Sprites.ovo.length, 16);
    for (final linha in Sprites.ovo) {
      expect(linha.length, 16);
    }
  });

  test('existem pelo menos 3 espécies com 4 estágios cada', () {
    expect(Sprites.especies.length, greaterThanOrEqualTo(3));
    for (final e in Sprites.especies) {
      expect(e.estagios.length, 4); // filhote, jovem, adulto, lendário
    }
  });

  group('BichinhoSprite', () {
    testWidgets('renderiza e faz dispose limpo do timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BichinhoSprite(temaId: 1, estagio: 2)),
      );
      expect(find.byType(BichinhoSprite), findsOneWidget);
      // desmonta — flutter_test acusaria timer pendente/vazado no fim do teste
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('estagio 0 renderiza o ovo sem crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BichinhoSprite(temaId: 0, estagio: 0, animado: false),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(BichinhoSprite),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('humor dormindo aplica opacidade 0.55', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BichinhoSprite(
            temaId: 0,
            estagio: 1,
            humor: HumorBichinho.dormindo,
            animado: false,
          ),
        ),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(BichinhoSprite),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.55);
    });

    testWidgets('animado false não agenda timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BichinhoSprite(temaId: 0, estagio: 1, animado: false),
        ),
      );
      // sem timer periódico, settle não entra em loop de frames
      await tester.pumpAndSettle();
      expect(find.byType(BichinhoSprite), findsOneWidget);
    });

    testWidgets('toggle animado true→false para o bounce e reseta posição',
        (tester) async {
      await tester.pumpWidget(_monta(animado: true));
      await tester.pump(const Duration(milliseconds: 900)); // 1 tick: subiu
      expect(_deslocamentoY(tester), isNot(0.0));

      await tester.pumpWidget(_monta(animado: false));
      // se o timer tivesse vazado, alternaria de novo em 1600ms e 2400ms
      await tester.pump(const Duration(seconds: 2));
      expect(_deslocamentoY(tester), 0.0);
    });

    testWidgets('toggle animado false→true inicia o bounce', (tester) async {
      await tester.pumpWidget(_monta(animado: false));
      await tester.pumpWidget(_monta(animado: true));
      await tester.pump(const Duration(milliseconds: 900)); // 1 tick: subiu
      expect(_deslocamentoY(tester), isNot(0.0));
    });
  });
}

/// Monta o sprite num MaterialApp mínimo pra testar o toggle de [animado].
Widget _monta({required bool animado}) => MaterialApp(
      home: BichinhoSprite(temaId: 0, estagio: 1, animado: animado),
    );

/// Lê o deslocamento vertical do Transform.translate interno do sprite.
double _deslocamentoY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(BichinhoSprite),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().y;
}
