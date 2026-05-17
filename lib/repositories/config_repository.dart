// lib/repositories/config_repository.dart
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/config.dart';

class ConfigRepository {
  final DatabaseHelper _db;
  ConfigRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<Config?> getConfig(String chave) async {
    final banco = await _db.banco;
    final rows = await banco.query('config', where: 'chave = ?', whereArgs: [chave]);
    if (rows.isEmpty) return null;
    return Config.fromMap(rows.first);
  }

  Future<int> getValorInt(String chave, {int padrao = 0}) async {
    final config = await getConfig(chave);
    return config?.valorInt ?? padrao;
  }

  Future<void> setConfig(String chave, String valor) async {
    final banco = await _db.banco;
    await banco.insert(
      'config',
      {'chave': chave, 'valor': valor, 'atualizado_em': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
