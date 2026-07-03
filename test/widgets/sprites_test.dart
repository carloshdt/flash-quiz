// test/widgets/sprites_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/widgets/bichinho/sprites.dart';

void main() {
  test('todas as matrizes são 16x16 com índices de cor válidos', () {
    for (final especie in Sprites.especies) {
      for (final estagio in especie.estagios) {
        expect(estagio.length, 16, reason: 'altura deve ser 16');
        for (final linha in estagio) {
          expect(linha.length, 16, reason: 'largura deve ser 16');
          for (final pixel in linha) {
            expect(pixel >= 0 && pixel < especie.palette.length + 1, isTrue,
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
}
