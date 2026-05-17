// lib/models/card_model.dart
class CardModel {
  final int id;
  final int faseId;
  final String pergunta;
  final String resposta;
  final String alternativaB;
  final String alternativaC;
  final String alternativaD;

  const CardModel({
    required this.id,
    required this.faseId,
    required this.pergunta,
    required this.resposta,
    required this.alternativaB,
    required this.alternativaC,
    required this.alternativaD,
  });

  factory CardModel.fromMap(Map<String, dynamic> m) => CardModel(
    id: m['id'] as int,
    faseId: m['fase_id'] as int,
    pergunta: m['pergunta'] as String,
    resposta: m['resposta'] as String,
    alternativaB: m['alternativa_b'] as String,
    alternativaC: m['alternativa_c'] as String,
    alternativaD: m['alternativa_d'] as String,
  );

  // Retorna as 4 alternativas embaralhadas (para quiz)
  List<String> alternativasEmbaralhadas() {
    final lista = [resposta, alternativaB, alternativaC, alternativaD];
    lista.shuffle();
    return lista;
  }
}
