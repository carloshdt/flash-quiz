// lib/repositories/secao_repository.dart
import '../db/database_helper.dart';
import '../models/secao.dart';

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
}
