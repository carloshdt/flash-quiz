// lib/repositories/fase_repository.dart
import '../db/database_helper.dart';
import '../models/fase.dart';

class FaseRepository {
  final DatabaseHelper _db;
  FaseRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<Fase>> getFasesPorSecao(int secaoId) async {
    final banco = await _db.banco;
    final rows = await banco.query(
      'fases',
      where: 'secao_id = ?',
      whereArgs: [secaoId],
      orderBy: 'ordem ASC',
    );
    return rows.map(Fase.fromMap).toList();
  }
}
