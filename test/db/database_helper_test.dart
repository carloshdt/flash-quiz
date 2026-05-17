// test/db/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper().fecharParaTeste();
  });

  test('banco cria todas as tabelas', () async {
    final db = await DatabaseHelper().banco;
    final tabelas = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final nomes = tabelas.map((t) => t['name'] as String).toList();
    expect(nomes, containsAll([
      'cards', 'config', 'conquistas', 'conquistas_usuario',
      'eventos', 'fases', 'perfil', 'progresso_flashcard',
      'quiz_respostas', 'quiz_tentativas', 'secoes', 'temas',
    ]));
  });

  test('config tem valores padrão', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('config');
    final chaves = rows.map((r) => r['chave'] as String).toList();
    expect(chaves, contains('quiz_tempo_por_questao'));
    expect(chaves, contains('quiz_num_questoes'));
    expect(chaves, contains('flashcard_min_percentual_para_quiz'));
  });

  test('perfil inicial criado', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('perfil');
    expect(rows.length, 1);
    expect(rows.first['xp_total'], 0);
    expect(rows.first['streak_atual'], 0);
  });
}
