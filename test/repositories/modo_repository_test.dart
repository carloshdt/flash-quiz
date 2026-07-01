// test/repositories/modo_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/modo_repository.dart';

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
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    expect(id, greaterThan(0));
  });

  test('concluirTentativa salva pontuacao e marca concluido', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.concluirTentativa(id, pontuacao: 84, tempoTotalSegundos: 90);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('modo_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['pontuacao'], 84);
    expect(rows.first['concluido'], 1);
  });

  test('abandonarTentativa mantém concluido = 0', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('maratona', 1);
    await repo.abandonarTentativa(id);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('modo_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['concluido'], 0);
  });

  test('notaDesafioHoje retorna null sem desafio concluído hoje', () async {
    final repo = ModoRepository();
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('notaDesafioHoje retorna nota do desafio concluído hoje', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.concluirTentativa(id, pontuacao: 76, tempoTotalSegundos: 60);
    expect(await repo.notaDesafioHoje(1), 76);
  });

  test('desafio abandonado não conta como feito hoje', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.abandonarTentativa(id);
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('notaDesafioHoje ignora outros temas e maratonas', () async {
    final repo = ModoRepository();
    final m = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(m, pontuacao: 15, tempoTotalSegundos: 200);
    final outroTema = await repo.iniciarTentativa('desafio', 2);
    await repo.concluirTentativa(outroTema, pontuacao: 90, tempoTotalSegundos: 50);
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('recordeMaratona retorna 0 sem partidas e MAX com partidas', () async {
    final repo = ModoRepository();
    expect(await repo.recordeMaratona(1), 0);

    final a = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(a, pontuacao: 12, tempoTotalSegundos: 100);
    final b = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(b, pontuacao: 20, tempoTotalSegundos: 150);

    expect(await repo.recordeMaratona(1), 20);
  });
}
