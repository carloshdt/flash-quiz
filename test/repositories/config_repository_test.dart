// test/repositories/config_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/config_repository.dart';

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

  test('getValorInt retorna valor padrão do seed', () async {
    final repo = ConfigRepository();
    final tempo = await repo.getValorInt('quiz_tempo_por_questao');
    expect(tempo, 30);
  });

  test('setConfig atualiza valor existente', () async {
    final repo = ConfigRepository();
    await repo.setConfig('quiz_tempo_por_questao', '20');
    final tempo = await repo.getValorInt('quiz_tempo_por_questao');
    expect(tempo, 20);
  });

  test('getValorInt retorna padrao para chave inexistente', () async {
    final repo = ConfigRepository();
    final val = await repo.getValorInt('chave_inexistente', padrao: 99);
    expect(val, 99);
  });
}
