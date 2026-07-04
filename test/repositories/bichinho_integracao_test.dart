// test/repositories/bichinho_integracao_test.dart
// Confere que os valores de energia por atividade vêm da config e que o
// BichinhoService grava as métricas de alimentação/nascimento em eventos.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/config_repository.dart';
import 'package:flashquiz/services/bichinho_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('energias por atividade seedadas: card=2, quiz=15, modo=10', () async {
    final config = ConfigRepository();
    expect(await config.getValorInt('bichinho_energia_card'), 2);
    expect(await config.getValorInt('bichinho_energia_quiz'), 15);
    expect(await config.getValorInt('bichinho_energia_modo'), 10);
  });

  test('alimentarComMetricas grava bichinho_nasceu (1ª vez) e bichinho_alimentado',
      () async {
    final db = await DatabaseHelper().banco;
    final temaId =
        await db.insert('temas', {'nome': 'TemaBichinho', 'icone': '🐣'});

    Future<int> contarEventos(String evento) async {
      final rows = await db
          .query('eventos', where: 'evento = ?', whereArgs: [evento]);
      return rows.length;
    }

    final service = BichinhoService();

    // Primeira alimentação: bichinho nasce e é alimentado
    final r1 = await service.alimentarComMetricas(
      temaId: temaId,
      nomeTema: 'TemaBichinho',
      chaveEnergia: 'bichinho_energia_modo',
      padrao: 10,
    );
    expect(r1, isNotNull);
    expect(r1!.nasceuAgora, isTrue);
    expect(await contarEventos('bichinho_nasceu'), 1);
    expect(await contarEventos('bichinho_alimentado'), 1);

    // Segunda alimentação: não nasce de novo
    final r2 = await service.alimentarComMetricas(
      temaId: temaId,
      nomeTema: 'TemaBichinho',
      chaveEnergia: 'bichinho_energia_modo',
      padrao: 10,
    );
    expect(r2!.nasceuAgora, isFalse);
    expect(await contarEventos('bichinho_nasceu'), 1);
    expect(await contarEventos('bichinho_alimentado'), 2);
  });

  test('alimentarComMetricas com temaId null retorna null sem gravar eventos',
      () async {
    final db = await DatabaseHelper().banco;
    final service = BichinhoService();

    final r = await service.alimentarComMetricas(
      temaId: null,
      nomeTema: 'TemaFantasma',
      chaveEnergia: 'bichinho_energia_modo',
      padrao: 10,
    );
    expect(r, isNull);

    final rows = await db.query('eventos',
        where: 'evento LIKE ?', whereArgs: ['bichinho%']);
    expect(rows, isEmpty);
  });
}
