// lib/db/database_helper.dart
// Singleton que gerencia conexão e migrations do SQLite

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migrations/migration_v1.dart';

class DatabaseHelper {
  static final DatabaseHelper _instancia = DatabaseHelper._interno();
  static Database? _db;

  DatabaseHelper._interno();
  factory DatabaseHelper() => _instancia;

  Future<Database> get banco async {
    _db ??= await _inicializar();
    return _db!;
  }

  Future<Database> _inicializar() async {
    final caminho = join(await getDatabasesPath(), 'flashquiz.db');
    return openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await MigrationV1.executar(db);
      },
    );
  }

  // Apenas para testes — fecha e apaga o banco
  Future<void> fecharParaTeste() async {
    await _db?.close();
    _db = null;
  }
}
