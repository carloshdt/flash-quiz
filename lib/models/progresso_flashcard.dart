// lib/models/progresso_flashcard.dart
class ProgressoFlashcard {
  final int? id;
  final int cardId;
  final int nivelSrs; // 0=difícil, 1=médio, 2=fácil
  final int totalVisto;
  final int totalAcerto;
  final DateTime? proximaRevisao;

  const ProgressoFlashcard({
    this.id,
    required this.cardId,
    this.nivelSrs = 0,
    this.totalVisto = 0,
    this.totalAcerto = 0,
    this.proximaRevisao,
  });

  factory ProgressoFlashcard.fromMap(Map<String, dynamic> m) => ProgressoFlashcard(
    id: m['id'] as int?,
    cardId: m['card_id'] as int,
    nivelSrs: m['nivel_srs'] as int,
    totalVisto: m['total_visto'] as int,
    totalAcerto: m['total_acerto'] as int,
    proximaRevisao: m['proxima_revisao'] != null
        ? DateTime.parse(m['proxima_revisao'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'card_id': cardId,
    'nivel_srs': nivelSrs,
    'total_visto': totalVisto,
    'total_acerto': totalAcerto,
    'proxima_revisao': proximaRevisao?.toIso8601String(),
    'atualizado_em': DateTime.now().toIso8601String(),
  };
}
