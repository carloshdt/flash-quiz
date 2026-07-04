// test/controllers/home_controller_test.dart
// HomeController: bichinhos/humores só pra temas desbloqueados e métrica
// bichinho_nasceu gravada uma única vez (na primeira carga).
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/controllers/home_controller.dart';
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

  // Seed adicional: 1 tema desbloqueado + 1 bloqueado
  // (as migrations já seedam CFC desbloqueado e 3 temas mock bloqueados)
  Future<void> seedTemas() async {
    final db = await DatabaseHelper().banco;
    await db.insert('temas', {'nome': 'TesteAberto', 'icone': '📗', 'desbloqueado': 1});
    await db.insert('temas', {'nome': 'TesteFechado', 'icone': '📕', 'desbloqueado': 0});
  }

  // O construtor do HomeController dispara carregar() — espera terminar
  Future<void> aguardarCarregar(HomeController ctrl) async {
    while (ctrl.carregando) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<int> contarNascimentos() async {
    final db = await DatabaseHelper().banco;
    final rows = await db.rawQuery(
        "SELECT COUNT(*) AS n FROM eventos WHERE evento = 'bichinho_nasceu'");
    return rows.first['n'] as int;
  }

  test('carregar popula bichinhos e humores só pra temas desbloqueados', () async {
    await seedTemas();
    final ctrl = HomeController();
    await aguardarCarregar(ctrl);

    final desbloqueados =
        ctrl.temas.where((t) => t.desbloqueado).map((t) => t.id).toSet();
    final bloqueados =
        ctrl.temas.where((t) => !t.desbloqueado).map((t) => t.id).toSet();
    expect(desbloqueados, isNotEmpty);
    expect(bloqueados, isNotEmpty);

    expect(ctrl.bichinhos.keys.toSet(), desbloqueados);
    expect(ctrl.humores.keys.toSet(), desbloqueados);
    ctrl.dispose();
  });

  test('bichinho_nasceu gravado 1x por tema desbloqueado na 1ª carga e 0x na 2ª',
      () async {
    await seedTemas();
    final ctrl = HomeController();
    await aguardarCarregar(ctrl);

    final numDesbloqueados = ctrl.temas.where((t) => t.desbloqueado).length;
    expect(await contarNascimentos(), numDesbloqueados);

    // Segunda carga: bichinhos já existem — nenhum nascimento novo
    await ctrl.carregar();
    expect(await contarNascimentos(), numDesbloqueados);
    ctrl.dispose();
  });
}
