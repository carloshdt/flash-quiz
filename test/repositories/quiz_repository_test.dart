// test/repositories/quiz_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/quiz_repository.dart';

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

  test('iniciarTentativa retorna id válido', () async {
    final repo = QuizRepository();
    final id = await repo.iniciarTentativa(1);
    expect(id, greaterThan(0));
  });

  test('concluirTentativa salva pontuacao e estrelas', () async {
    final repo = QuizRepository();
    final tentativaId = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(tentativaId, pontuacao: 85, estrelas: 2, tempoTotalSegundos: 120);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('quiz_tentativas', where: 'id = ?', whereArgs: [tentativaId]);
    expect(rows.first['pontuacao'], 85);
    expect(rows.first['estrelas'], 2);
    expect(rows.first['concluido'], 1);
  });

  test('melhorTentativa retorna tentativa com maior pontuacao', () async {
    final repo = QuizRepository();
    final id1 = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(id1, pontuacao: 70, estrelas: 1, tempoTotalSegundos: 100);
    final id2 = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(id2, pontuacao: 90, estrelas: 3, tempoTotalSegundos: 80);

    final melhor = await repo.melhorTentativa(1);
    expect(melhor?.pontuacao, 90);
  });

  test('melhorTentativa retorna null quando não há tentativas', () async {
    final repo = QuizRepository();
    final melhor = await repo.melhorTentativa(999);
    expect(melhor, isNull);
  });

  test('abandonarTentativa marca concluido como false', () async {
    final repo = QuizRepository();
    final id = await repo.iniciarTentativa(1);
    await repo.abandonarTentativa(id);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('quiz_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['concluido'], 0);
  });

  test('contarTentativas conta apenas tentativas da fase', () async {
    final repo = QuizRepository();
    await repo.iniciarTentativa(1);
    await repo.iniciarTentativa(1);
    await repo.iniciarTentativa(2);

    expect(await repo.contarTentativas(1), 2);
    expect(await repo.contarTentativas(2), 1);
  });
}
