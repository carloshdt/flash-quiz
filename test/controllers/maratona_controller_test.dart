// test/controllers/maratona_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/controllers/maratona_controller.dart';
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

  // Monta tema com 1 seção / 1 fase / 3 cards (primeira fase = desbloqueada)
  Future<int> seedTema() async {
    final db = await DatabaseHelper().banco;
    final temaId = await db.insert('temas', {'nome': 'TesteMaratona', 'icone': '🏃'});
    final secaoId = await db.insert('secoes', {'tema_id': temaId, 'nome': 'S1', 'ordem': 0});
    final faseId = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F1', 'ordem': 1});
    for (var i = 0; i < 3; i++) {
      await db.insert('cards', {
        'fase_id': faseId,
        'pergunta': 'p$i',
        'resposta': 'R$i',
        'alternativa_b': 'B',
        'alternativa_c': 'C',
        'alternativa_d': 'D',
      });
    }
    return temaId;
  }

  test('carregar monta fila com pool desbloqueado', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    expect(ctrl.poolVazio, isFalse);
    expect(ctrl.questaoAtual, isNotNull);
    expect(ctrl.erros, 0);
    expect(ctrl.acertos, 0);
    ctrl.dispose();
  });

  test('acerto incrementa acertos; erro incrementa erros', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    ctrl.selecionarResposta(ctrl.indiceCorreto); // acerto
    expect(ctrl.acertos, 1);
    expect(ctrl.erros, 0);

    final errado = (ctrl.indiceCorreto + 1) % 4;
    ctrl.selecionarResposta(errado); // erro
    expect(ctrl.acertos, 1);
    expect(ctrl.erros, 1);
    ctrl.dispose();
  });

  test('3 erros encerram a partida', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    for (var i = 0; i < 3; i++) {
      expect(ctrl.fimDeJogo, isFalse);
      ctrl.selecionarResposta((ctrl.indiceCorreto + 1) % 4);
    }
    expect(ctrl.erros, 3);
    expect(ctrl.fimDeJogo, isTrue);
    ctrl.dispose();
  });

  test('fila não repete card até esgotar o pool, depois re-embaralha', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    final vistos = <int>[];
    for (var i = 0; i < 3; i++) {
      vistos.add(ctrl.questaoAtual!.id);
      ctrl.selecionarResposta(ctrl.indiceCorreto);
    }
    // 3 cards distintos na primeira volta
    expect(vistos.toSet().length, 3);
    // Pool esgotado: quarta questão existe (re-embaralhado)
    expect(ctrl.questaoAtual, isNotNull);
    ctrl.dispose();
  });

  test('concluir salva score e detecta recorde batido', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    ctrl.selecionarResposta(ctrl.indiceCorreto);
    ctrl.selecionarResposta(ctrl.indiceCorreto);
    for (var i = 0; i < 3; i++) {
      ctrl.selecionarResposta((ctrl.indiceCorreto + 1) % 4);
    }
    expect(ctrl.fimDeJogo, isTrue);

    final resultado = await ctrl.concluir();
    expect(resultado.score, 2);
    expect(resultado.recordeBatido, isTrue);

    // Bichinho alimentado com a energia de modo (10, sem streak ativo)
    expect(ctrl.ultimoAlimentar, isNotNull);
    expect(ctrl.ultimoAlimentar!.energiaGanha, 10);
    ctrl.dispose();
  });
}
