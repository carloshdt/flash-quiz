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
}
