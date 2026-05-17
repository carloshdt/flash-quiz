// lib/models/quiz_resposta.dart
class QuizResposta {
  final int? id;
  final int tentativaId;
  final int cardId;
  final String? respostaEscolhida;
  final bool acertou;
  final int? tempoSegundos;

  const QuizResposta({
    this.id,
    required this.tentativaId,
    required this.cardId,
    this.respostaEscolhida,
    this.acertou = false,
    this.tempoSegundos,
  });

  factory QuizResposta.fromMap(Map<String, dynamic> m) => QuizResposta(
    id: m['id'] as int?,
    tentativaId: m['tentativa_id'] as int,
    cardId: m['card_id'] as int,
    respostaEscolhida: m['resposta_escolhida'] as String?,
    acertou: (m['acertou'] as int) == 1,
    tempoSegundos: m['tempo_segundos'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'tentativa_id': tentativaId,
    'card_id': cardId,
    'resposta_escolhida': respostaEscolhida,
    'acertou': acertou ? 1 : 0,
    'tempo_segundos': tempoSegundos,
  };
}
