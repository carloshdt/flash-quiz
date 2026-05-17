// lib/models/quiz_tentativa.dart
class QuizTentativa {
  final int? id;
  final int faseId;
  final int pontuacao;
  final int estrelas;
  final int? tempoTotalSegundos;
  final bool concluido;
  final DateTime? criadoEm;

  const QuizTentativa({
    this.id,
    required this.faseId,
    this.pontuacao = 0,
    this.estrelas = 0,
    this.tempoTotalSegundos,
    this.concluido = false,
    this.criadoEm,
  });

  factory QuizTentativa.fromMap(Map<String, dynamic> m) => QuizTentativa(
    id: m['id'] as int?,
    faseId: m['fase_id'] as int,
    pontuacao: m['pontuacao'] as int,
    estrelas: m['estrelas'] as int,
    tempoTotalSegundos: m['tempo_total_segundos'] as int?,
    concluido: (m['concluido'] as int) == 1,
    criadoEm: m['criado_em'] != null
        ? DateTime.parse(m['criado_em'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'fase_id': faseId,
    'pontuacao': pontuacao,
    'estrelas': estrelas,
    'tempo_total_segundos': tempoTotalSegundos,
    'concluido': concluido ? 1 : 0,
  };
}
