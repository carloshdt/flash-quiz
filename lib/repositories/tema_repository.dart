// lib/repositories/tema_repository.dart
import '../db/database_helper.dart';
import '../models/tema.dart';

class TemaRepository {
  final DatabaseHelper _db;
  TemaRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<Tema>> getTemas() async {
    final banco = await _db.banco;
    final rows = await banco.query('temas', orderBy: 'id ASC');
    return rows.map(Tema.fromMap).toList();
  }

  /// Busca tema pelo nome exato (rotas de flashcard/quiz só carregam o nome).
  Future<Tema?> getTemaPorNome(String nome) async {
    final banco = await _db.banco;
    final rows =
        await banco.query('temas', where: 'nome = ?', whereArgs: [nome]);
    if (rows.isEmpty) return null;
    return Tema.fromMap(rows.first);
  }
}
