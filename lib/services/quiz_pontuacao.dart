// Pontuação padrão por questão (regra do Plano.md):
// acertou em < metade do tempo = 10 | acertou em >= metade = 7 | errou/estourou = 0

class QuizPontuacao {
  static int pontosQuestao({
    required bool acertou,
    required int tempoGasto,
    required int tempoPorQuestao,
  }) {
    if (!acertou) return 0;
    return tempoGasto < tempoPorQuestao / 2 ? 10 : 7;
  }

  // Nota 0–100 proporcional ao máximo possível (totalQuestoes × 10)
  static int nota(int somaPontos, int totalQuestoes) {
    final totalPossivel = totalQuestoes * 10;
    if (totalPossivel == 0) return 0;
    return (somaPontos / totalPossivel * 100).round();
  }
}
