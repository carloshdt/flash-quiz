// lib/repositories/modo_repository.dart
// Repositório para tentativas de Desafio e Maratona (tabela modo_tentativas).
import '../db/database_helper.dart';

class ModoRepository {
  final DatabaseHelper _db;
  ModoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  /// Cria uma nova tentativa em aberto e retorna o id gerado.
  Future<int> iniciarTentativa(String modo, int temaId) async {
    final banco = await _db.banco;
    return banco.insert('modo_tentativas', {
      'modo': modo,
      'tema_id': temaId,
      'pontuacao': 0,
      'concluido': 0,
    });
  }

  /// Salva pontuação e tempo, marcando a tentativa como concluída.
  Future<void> concluirTentativa(
    int tentativaId, {
    required int pontuacao,
    required int tempoTotalSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.update(
      'modo_tentativas',
      {
        'pontuacao': pontuacao,
        'tempo_total_segundos': tempoTotalSegundos,
        'concluido': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  /// Marca a tentativa como abandonada (concluido permanece 0).
  Future<void> abandonarTentativa(int tentativaId) async {
    final banco = await _db.banco;
    await banco.update(
      'modo_tentativas',
      {
        'concluido': 0,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  /// Retorna a nota do desafio concluído hoje para o tema, ou null se ainda
  /// não fez. criado_em é gravado em UTC (CURRENT_TIMESTAMP) — converter com
  /// 'localtime' para comparar com a data local do dispositivo.
  Future<int?> notaDesafioHoje(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT pontuacao FROM modo_tentativas
      WHERE modo = 'desafio' AND tema_id = ? AND concluido = 1
        AND DATE(criado_em, 'localtime') = DATE('now', 'localtime')
      ORDER BY pontuacao DESC
      LIMIT 1
    ''', [temaId]);
    if (rows.isEmpty) return null;
    return rows.first['pontuacao'] as int;
  }

  /// Retorna o maior pontuacao de maratona concluída para o tema, ou 0 se
  /// ainda não há partidas concluídas.
  Future<int> recordeMaratona(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT MAX(pontuacao) AS recorde FROM modo_tentativas
      WHERE modo = 'maratona' AND tema_id = ? AND concluido = 1
    ''', [temaId]);
    return (rows.first['recorde'] as int?) ?? 0;
  }
}
