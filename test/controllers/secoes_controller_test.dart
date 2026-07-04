// test/controllers/secoes_controller_test.dart
// SecoesController: bichinho carregado com humor/threshold, métrica
// bichinho_nasceu gravada uma única vez e popup registrado sob demanda.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/controllers/secoes_controller.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/models/bichinho.dart';

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

  // Seed: 1 tema desbloqueado — seções não são necessárias pros cenários daqui
  Future<int> seedTema() async {
    final db = await DatabaseHelper().banco;
    return db.insert('temas', {'nome': 'TesteTema', 'icone': '📗', 'desbloqueado': 1});
  }

  Future<int> contarEventos(String evento) async {
    final db = await DatabaseHelper().banco;
    final rows = await db
        .rawQuery('SELECT COUNT(*) AS n FROM eventos WHERE evento = ?', [evento]);
    return rows.first['n'] as int;
  }

  test('carregar popula bichinho, humor e proximoThreshold do ovo', () async {
    final temaId = await seedTema();
    final ctrl = SecoesController();
    await ctrl.carregar(temaId, 'TesteTema');

    expect(ctrl.bichinho, isNotNull);
    expect(ctrl.bichinho!.temaId, temaId);
    expect(ctrl.bichinho!.estagio, 0); // nasce como ovo
    // Tema recém-criado sem eventos de estudo → humor dormindo
    expect(ctrl.humorBichinho, HumorBichinho.dormindo);
    // Ovo → threshold_1 seedado na migration v5 (50)
    expect(ctrl.proximoThreshold, 50);
    ctrl.dispose();
  });

  test('bichinho_nasceu gravado 1x na 1ª carga e 0 novos na 2ª', () async {
    final temaId = await seedTema();
    final ctrl = SecoesController();

    await ctrl.carregar(temaId, 'TesteTema');
    expect(await contarEventos('bichinho_nasceu'), 1);

    // Segunda carga: bichinho já existe — nenhum nascimento novo
    await ctrl.carregar(temaId, 'TesteTema');
    expect(await contarEventos('bichinho_nasceu'), 1);
    ctrl.dispose();
  });

  test('registrarPopupAberto grava evento após carregar', () async {
    final temaId = await seedTema();
    final ctrl = SecoesController();
    await ctrl.carregar(temaId, 'TesteTema');

    await ctrl.registrarPopupAberto();
    expect(await contarEventos('bichinho_popup_aberto'), 1);
    ctrl.dispose();
  });

  test('registrarPopupAberto sem bichinho carregado é no-op sem exception', () async {
    await seedTema();
    final ctrl = SecoesController(); // recém-criado, carregar() nunca chamado

    await ctrl.registrarPopupAberto();
    expect(await contarEventos('bichinho_popup_aberto'), 0);
    ctrl.dispose();
  });
}
