// lib/repositories/quiz_repository.dart
import '../db/database_helper.dart';
import '../models/quiz_tentativa.dart';

class QuizRepository {
  final DatabaseHelper _db;
  QuizRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<int> iniciarTentativa(int faseId) async {
    final banco = await _db.banco;
    return banco.insert('quiz_tentativas', {
      'fase_id': faseId,
      'pontuacao': 0,
      'estrelas': 0,
      'concluido': 0,
    });
  }

  Future<void> concluirTentativa(
    int tentativaId, {
    required int pontuacao,
    required int estrelas,
    required int tempoTotalSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.update(
      'quiz_tentativas',
      {
        'pontuacao': pontuacao,
        'estrelas': estrelas,
        'tempo_total_segundos': tempoTotalSegundos,
        'concluido': 1,
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  Future<void> abandonarTentativa(int tentativaId) async {
    final banco = await _db.banco;
    await banco.update(
      'quiz_tentativas',
      {'concluido': 0},
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  Future<QuizTentativa?> melhorTentativa(int faseId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery(
      '''SELECT * FROM quiz_tentativas
         WHERE fase_id = ? AND concluido = 1
         ORDER BY pontuacao DESC
         LIMIT 1''',
      [faseId],
    );
    if (rows.isEmpty) return null;
    return QuizTentativa.fromMap(rows.first);
  }

  Future<int> contarTentativas(int faseId) async {
    final banco = await _db.banco;
    final result = await banco.rawQuery(
      'SELECT COUNT(*) as total FROM quiz_tentativas WHERE fase_id = ?',
      [faseId],
    );
    return result.first['total'] as int;
  }

  Future<void> salvarResposta({
    required int tentativaId,
    required int cardId,
    String? respostaEscolhida,
    required bool acertou,
    required int tempoSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.insert('quiz_respostas', {
      'tentativa_id': tentativaId,
      'card_id': cardId,
      'resposta_escolhida': respostaEscolhida,
      'acertou': acertou ? 1 : 0,
      'tempo_segundos': tempoSegundos,
    });
  }
}
