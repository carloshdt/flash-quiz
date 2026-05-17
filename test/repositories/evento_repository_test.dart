// test/repositories/evento_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/evento_repository.dart';
import 'package:flashquiz/models/evento.dart';

/// Apaga o arquivo do banco e reseta o singleton para garantir banco limpo
Future<void> _resetarBanco() async {
  await DatabaseHelper().fecharParaTeste();
  final dir = await databaseFactoryFfi.getDatabasesPath();
  await databaseFactoryFfi.deleteDatabase(join(dir, 'flashquiz.db'));
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(_resetarBanco);
  tearDown(_resetarBanco);

  test('registrar salva evento no banco', () async {
    final repo = EventoRepository();
    await repo.registrar(Evento(
      evento: 'app_aberto',
      metadata: {'versao': '1.0.0'},
    ));
    final db = await DatabaseHelper().banco;
    final rows = await db.query('eventos', where: "evento = 'app_aberto'");
    expect(rows.length, 1);
  });

  test('registrar salva metadata como JSON', () async {
    final repo = EventoRepository();
    await repo.registrar(Evento(
      evento: 'tema_selecionado',
      tema: 'CFC',
      metadata: {'tema_id': 1},
    ));
    final db = await DatabaseHelper().banco;
    final rows = await db.query('eventos', where: "evento = 'tema_selecionado'");
    expect(rows.first['metadata'], contains('tema_id'));
  });
}
