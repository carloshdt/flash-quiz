// lib/repositories/perfil_repository.dart
import '../db/database_helper.dart';
import '../models/perfil.dart';

class PerfilRepository {
  final DatabaseHelper _db;
  PerfilRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<Perfil?> getPerfil() async {
    final banco = await _db.banco;
    final rows = await banco.query('perfil', limit: 1);
    if (rows.isEmpty) return null;
    return Perfil.fromMap(rows.first);
  }

  Future<void> atualizarPerfil(Perfil perfil) async {
    final banco = await _db.banco;
    await banco.update(
      'perfil',
      perfil.toMap(),
      where: 'id = ?',
      whereArgs: [perfil.id],
    );
  }
}
