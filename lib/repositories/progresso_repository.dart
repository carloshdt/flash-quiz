// lib/repositories/progresso_repository.dart
import '../db/database_helper.dart';
import '../models/card_model.dart';

class ProgressoRepository {
  final DatabaseHelper _db;
  ProgressoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  // Cards da fase que devem aparecer na sessão:
  // 1. Cards vencidos (proxima_revisao <= hoje) — primeiro
  // 2. Cards novos (nunca vistos) — depois
  // Limite = flashcard_cards_por_sessao (padrão 20)
  Future<List<CardModel>> getCardsParaSessao(int faseId, int limite) async {
    final banco = await _db.banco;
    final hoje = DateTime.now().toIso8601String().split('T').first;

    final rows = await banco.rawQuery('''
      SELECT c.*
      FROM cards c
      LEFT JOIN progresso_flashcard pf ON pf.card_id = c.id
      WHERE c.fase_id = ?
        AND (
          pf.id IS NULL
          OR pf.total_visto = 0
          OR pf.proxima_revisao <= ?
        )
      ORDER BY
        CASE WHEN pf.total_visto > 0 THEN 0 ELSE 1 END ASC,
        pf.proxima_revisao ASC
      LIMIT ?
    ''', [faseId, hoje, limite]);

    return rows.map(CardModel.fromMap).toList();
  }

  // Conta quantos cards da fase já foram vistos pelo menos uma vez
  Future<int> getCardsVistosCount(int faseId) async {
    final banco = await _db.banco;
    final result = await banco.rawQuery('''
      SELECT COUNT(DISTINCT pf.card_id) AS vistos
      FROM progresso_flashcard pf
      JOIN cards c ON c.id = pf.card_id
      WHERE c.fase_id = ? AND pf.total_visto > 0
    ''', [faseId]);
    return (result.first['vistos'] as int?) ?? 0;
  }

  // Cria ou atualiza o progresso de um card após avaliação SRS
  // nivelSrs: 0=Difícil (revisão hoje), 1=Médio (+1 dia), 2=Fácil (+3 dias)
  Future<void> salvarProgresso(int cardId, int nivelSrs) async {
    final banco = await _db.banco;
    final agora = DateTime.now();
    const intervaloDias = {0: 0, 1: 1, 2: 3};
    final proxima = agora.add(Duration(days: intervaloDias[nivelSrs] ?? 0));

    final existing = await banco.query(
      'progresso_flashcard',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    if (existing.isEmpty) {
      await banco.insert('progresso_flashcard', {
        'card_id': cardId,
        'nivel_srs': nivelSrs,
        'total_visto': 1,
        'total_acerto': nivelSrs > 0 ? 1 : 0,
        'proxima_revisao': proxima.toIso8601String(),
        'atualizado_em': agora.toIso8601String(),
      });
    } else {
      final old = existing.first;
      await banco.update(
        'progresso_flashcard',
        {
          'nivel_srs': nivelSrs,
          'total_visto': (old['total_visto'] as int) + 1,
          'total_acerto': (old['total_acerto'] as int) + (nivelSrs > 0 ? 1 : 0),
          'proxima_revisao': proxima.toIso8601String(),
          'atualizado_em': agora.toIso8601String(),
        },
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
    }
  }
}
