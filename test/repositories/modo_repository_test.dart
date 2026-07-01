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

  // Helper: monta tema isolado com 1 seção e 2 fases (2 cards cada)
  Future<({int temaId, int fase1, int fase2, List<int> cardsF1, List<int> cardsF2})>
      seedTema() async {
    final db = await DatabaseHelper().banco;
    final temaId = await db.insert('temas', {'nome': 'TesteModo', 'icone': '🧪'});
    final secaoId = await db.insert('secoes', {'tema_id': temaId, 'nome': 'S1', 'ordem': 0});
    final fase1 = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F1', 'ordem': 1});
    final fase2 = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F2', 'ordem': 2});
    Future<int> card(int faseId, String p) => db.insert('cards', {
          'fase_id': faseId,
          'pergunta': p,
          'resposta': 'R',
          'alternativa_b': 'B',
          'alternativa_c': 'C',
          'alternativa_d': 'D',
        });
    final cardsF1 = [await card(fase1, 'p1'), await card(fase1, 'p2')];
    final cardsF2 = [await card(fase2, 'p3'), await card(fase2, 'p4')];
    return (temaId: temaId, fase1: fase1, fase2: fase2, cardsF1: cardsF1, cardsF2: cardsF2);
  }

  test('cardsPoolDesbloqueado retorna só cards da primeira fase sem quiz passado', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), seed.cardsF1.toSet());
  });

  test('cardsPoolDesbloqueado inclui fase 2 após quiz da fase 1 passar com >= 70', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    await db.insert('quiz_tentativas',
        {'fase_id': seed.fase1, 'pontuacao': 80, 'estrelas': 2, 'concluido': 1});

    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), {...seed.cardsF1, ...seed.cardsF2});
  });

  test('cardsPoolDesbloqueado ignora quiz reprovado (< 70)', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    await db.insert('quiz_tentativas',
        {'fase_id': seed.fase1, 'pontuacao': 60, 'estrelas': 0, 'concluido': 1});

    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), seed.cardsF1.toSet());
  });

  test('cardsVencidos retorna só cards com proxima_revisao <= hoje, com limite', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final amanha = DateTime.now().add(const Duration(days: 1)).toIso8601String();

    // card vencido, card futuro, card nunca visto
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[0], 'nivel_srs': 0, 'total_visto': 2,
      'total_acerto': 1, 'proxima_revisao': ontem,
    });
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[1], 'nivel_srs': 2, 'total_visto': 1,
      'total_acerto': 1, 'proxima_revisao': amanha,
    });

    final vencidos = await repo.cardsVencidos(seed.temaId, 20);
    expect(vencidos.map((c) => c.id).toList(), [seed.cardsF1[0]]);

    final limitado = await repo.cardsVencidos(seed.temaId, 0);
    expect(limitado, isEmpty);
  });

  test('contarCardsVencidos conta cards vencidos do tema', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[0], 'nivel_srs': 0, 'total_visto': 1,
      'total_acerto': 0, 'proxima_revisao': ontem,
    });
    expect(await repo.contarCardsVencidos(seed.temaId), 1);
  });
}
