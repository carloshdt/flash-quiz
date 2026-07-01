import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/services/quiz_pontuacao.dart';

void main() {
  test('acertou rápido (< metade do tempo) = 10 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 10, tempoPorQuestao: 30), 10);
  });

  test('acertou devagar (>= metade do tempo) = 7 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 15, tempoPorQuestao: 30), 7);
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 30, tempoPorQuestao: 30), 7);
  });

  test('errou = 0 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: false, tempoGasto: 5, tempoPorQuestao: 30), 0);
  });

  test('nota é proporcional ao máximo possível', () {
    expect(QuizPontuacao.nota(50, 5), 100); // 5 questões × 10 = 50
    expect(QuizPontuacao.nota(35, 5), 70);
    expect(QuizPontuacao.nota(0, 5), 0);
  });

  test('nota com zero questões é 0', () {
    expect(QuizPontuacao.nota(0, 0), 0);
  });
}
