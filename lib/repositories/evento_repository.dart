// lib/repositories/evento_repository.dart
import '../db/database_helper.dart';
import '../models/evento.dart';

class EventoRepository {
  final DatabaseHelper _db;
  EventoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<void> registrar(Evento evento) async {
    final banco = await _db.banco;
    await banco.insert('eventos', evento.toMap());
  }
}
