// lib/repositories/secao_repository.dart
import '../db/database_helper.dart';
import '../models/secao.dart';

// % da seção = média ponderada das melhores pontuações dos quizzes de cada fase
// Cards vistos não contam — só o desempenho no quiz importa
class _SecaoProgressoQuiz {
  final int totalFases;
  final int somaPontuacoes;
  const _SecaoProgressoQuiz({
    required this.totalFases,
    required this.somaPontuacoes,
  });
  double get percentual => totalFases > 0
      ? (somaPontuacoes / (totalFases * 100)).clamp(0.0, 1.0)
      : 0.0;
}

class SecaoRepository {
  final DatabaseHelper _db;
  SecaoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<Secao>> getSecoesPorTema(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.query(
      'secoes',
      where: 'tema_id = ?',
      whereArgs: [temaId],
      orderBy: 'ordem ASC',
    );
    return rows.map(Secao.fromMap).toList();
  }

  Future<Map<int, double>> getProgressoPorTema(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT
        s.id AS secao_id,
        COUNT(DISTINCT f.id) AS total_fases,
        COALESCE(SUM(COALESCE(qt.melhor_pontuacao, 0)), 0) AS soma_pontuacoes
      FROM secoes s
      JOIN fases f ON f.secao_id = s.id
      LEFT JOIN (
        SELECT fase_id, MAX(pontuacao) AS melhor_pontuacao
        FROM quiz_tentativas
        WHERE concluido = 1
        GROUP BY fase_id
      ) qt ON qt.fase_id = f.id
      WHERE s.tema_id = ?
      GROUP BY s.id
    ''', [temaId]);

    final prog = <int, _SecaoProgressoQuiz>{
      for (final r in rows)
        r['secao_id'] as int: _SecaoProgressoQuiz(
          totalFases: r['total_fases'] as int,
          somaPontuacoes: r['soma_pontuacoes'] as int? ?? 0,
        ),
    };
    return prog.map((k, v) => MapEntry(k, v.percentual));
  }
}
