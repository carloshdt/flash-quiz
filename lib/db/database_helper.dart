// lib/db/database_helper.dart
// Singleton que gerencia conexão e migrations do SQLite

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migrations/migration_v1.dart';
import 'migrations/migration_v2.dart';
import 'migrations/migration_v3.dart';

class DatabaseHelper {
  static final DatabaseHelper _instancia = DatabaseHelper._interno();
  static Database? _db;
  static String? _caminhoTeste;

  DatabaseHelper._interno();
  factory DatabaseHelper() => _instancia;

  // Apenas para testes — define caminho alternativo (ex: inMemoryDatabasePath)
  static void setCaminhoParaTeste(String caminho) => _caminhoTeste = caminho;

  Future<Database> get banco async {
    _db ??= await _inicializar();
    return _db!;
  }

  Future<Database> _inicializar() async {
    final caminho = _caminhoTeste ?? join(await getDatabasesPath(), 'flashquiz.db');
    return openDatabase(
      caminho,
      version: 3,
      onCreate: (db, version) async {
        await MigrationV1.executar(db);
        await MigrationV2.executar(db);
        await MigrationV3.executar(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await MigrationV2.executar(db);
        if (oldVersion < 3) await MigrationV3.executar(db);
      },
    );
  }

  // Apenas para testes — fecha e apaga o banco
  Future<void> fecharParaTeste() async {
    await _db?.close();
    _db = null;
  }
}
