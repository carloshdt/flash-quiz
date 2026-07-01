// test/db/migration_v4_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath);
  });

  setUp(() async {
    await DatabaseHelper().fecharParaTeste();
  });

  tearDown(() async {
    await DatabaseHelper().fecharParaTeste();
  });

  test('tabela modo_tentativas existe com colunas esperadas', () async {
    final db = await DatabaseHelper().banco;
    final cols = await db.rawQuery('PRAGMA table_info(modo_tentativas)');
    final nomes = cols.map((c) => c['name']).toSet();
    expect(nomes.containsAll(['id', 'modo', 'tema_id', 'pontuacao', 'tempo_total_segundos', 'concluido', 'criado_em', 'atualizado_em']), isTrue);
  });

  test('configs dos modos seedadas', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('config',
        where: "chave IN ('desafio_num_questoes', 'revisao_max_cards', 'maratona_max_erros')");
    expect(rows.length, 3);
    final mapa = {for (final r in rows) r['chave']: r['valor']};
    expect(mapa['desafio_num_questoes'], '5');
    expect(mapa['revisao_max_cards'], '20');
    expect(mapa['maratona_max_erros'], '3');
  });
}
