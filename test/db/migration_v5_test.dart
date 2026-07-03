// test/db/migration_v5_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('tabela bichinhos existe com colunas esperadas', () async {
    final db = await DatabaseHelper().banco;
    final info = await db.rawQuery('PRAGMA table_info(bichinhos)');
    final colunas = info.map((c) => c['name']).toSet();
    expect(
      colunas.containsAll(
          {'id', 'tema_id', 'especie', 'estagio', 'energia', 'criado_em', 'atualizado_em'}),
      isTrue,
    );
  });

  test('configs do bichinho seedadas', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('config', where: "chave LIKE 'bichinho_%'");
    final chaves = rows.map((r) => r['chave']).toSet();
    expect(chaves, {
      'bichinho_energia_card',
      'bichinho_energia_quiz',
      'bichinho_energia_modo',
      'bichinho_threshold_1',
      'bichinho_threshold_2',
      'bichinho_threshold_3',
      'bichinho_threshold_4',
      'bichinho_streak_multiplicador',
      'bichinho_dias_fome',
      'bichinho_dias_dormindo',
    });
  });

  test('configs de som e haptics seedadas', () async {
    final db = await DatabaseHelper().banco;
    final som = await db.query('config', where: "chave = 'som_ativo'");
    final hap = await db.query('config', where: "chave = 'haptics_ativo'");
    expect(som.first['valor'], '1');
    expect(hap.first['valor'], '1');
  });
}
