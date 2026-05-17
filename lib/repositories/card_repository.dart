// lib/repositories/card_repository.dart
import '../db/database_helper.dart';
import '../models/card_model.dart';

class CardRepository {
  final DatabaseHelper _db;
  CardRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<CardModel>> getCardsPorFase(int faseId) async {
    final banco = await _db.banco;
    final rows = await banco.query(
      'cards',
      where: 'fase_id = ?',
      whereArgs: [faseId],
    );
    return rows.map(CardModel.fromMap).toList();
  }

  Future<int> contarCardsPorFase(int faseId) async {
    final banco = await _db.banco;
    final result = await banco.rawQuery(
      'SELECT COUNT(*) as total FROM cards WHERE fase_id = ?',
      [faseId],
    );
    return result.first['total'] as int;
  }
}
