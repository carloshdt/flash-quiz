// test/repositories/bichinho_integracao_test.dart
// Confere que os valores de energia por atividade vêm da config.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/config_repository.dart';

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
}
