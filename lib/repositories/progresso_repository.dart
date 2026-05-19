// lib/repositories/progresso_repository.dart
import '../db/database_helper.dart';
import '../models/card_model.dart';
import '../models/progresso_flashcard.dart';

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
          OR DATE(pf.proxima_revisao) <= ?
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
    const intervaloDias = {0: 0, 1: 1, 2: 3};
    final proxima = DateTime.now().add(Duration(days: intervaloDias[nivelSrs] ?? 0));

    final existing = await banco.query(
      'progresso_flashcard',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    if (existing.isEmpty) {
      final novo = ProgressoFlashcard(
        cardId: cardId,
        nivelSrs: nivelSrs,
        totalVisto: 1,
        totalAcerto: nivelSrs > 0 ? 1 : 0,
        proximaRevisao: proxima,
      );
      await banco.insert('progresso_flashcard', novo.toMap());
    } else {
      final old = ProgressoFlashcard.fromMap(existing.first);
      final atualizado = ProgressoFlashcard(
        cardId: cardId,
        nivelSrs: nivelSrs,
        totalVisto: old.totalVisto + 1,
        totalAcerto: old.totalAcerto + (nivelSrs > 0 ? 1 : 0),
        proximaRevisao: proxima,
      );
      await banco.update(
        'progresso_flashcard',
        atualizado.toMap(),
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
    }
  }
}
