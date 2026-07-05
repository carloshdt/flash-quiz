// test/repositories/bichinho_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/models/bichinho.dart';
import 'package:flashquiz/repositories/bichinho_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  Future<int> criarTema() async {
    final db = await DatabaseHelper().banco;
    return db.insert('temas', {'nome': 'CFC', 'icone': '🚗'});
  }

  test('obterOuCriar cria ovo na primeira visita e reporta criado', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    final r = await repo.obterOuCriar(temaId);
    expect(r.criado, isTrue);
    expect(r.bichinho.estagio, 0);
    expect(r.bichinho.energia, 0);
    expect(r.bichinho.especie, temaId % 3);
    // segunda chamada retorna o mesmo, sem criar
    final r2 = await repo.obterOuCriar(temaId);
    expect(r2.criado, isFalse);
    expect(r2.bichinho.id, r.bichinho.id);
  });

  test('alimentar sem eventos recentes (streak inativo) soma energia base', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    // sem nenhum evento registrado = streak inativo → multiplicador 1.0
    // (alimentar em si não grava eventos — repository puro)
    final r = await repo.alimentar(temaId, 10);
    expect(r.energiaGanha, 10);
    expect(r.bichinho.energia, 10);
    expect(r.evoluiu, isFalse);
  });

  test('alimentar com streak ativo aplica multiplicador 1.5 arredondado pra baixo', () async {
    final temaId = await criarTema();
    final db = await DatabaseHelper().banco;
    // streak ativo = atividade registrada ontem em eventos (fonte interina, spec §2.4)
    await db.rawInsert(
      "INSERT INTO eventos (evento, tema, criado_em) VALUES (?, ?, datetime('now', '-1 day'))",
      ['card_avaliado', 'CFC'],
    );
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final r = await repo.alimentar(temaId, 15);
    expect(r.energiaGanha, 22); // 15 * 1.5 = 22.5 → 22
  });

  test('cruzar threshold promove estágio e reporta evoluiu', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final r = await repo.alimentar(temaId, 50); // threshold_1 = 50
    expect(r.evoluiu, isTrue);
    expect(r.bichinho.estagio, 1);
  });

  test('energia acumulada nunca é perdida e lendário não passa de 4', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    await repo.alimentar(temaId, 2000);
    final r = await repo.alimentar(temaId, 100);
    expect(r.bichinho.estagio, 4);
    expect(r.bichinho.energia, 2100);
    expect(r.evoluiu, isFalse); // já era lendário
  });

  test('humor por inatividade no tema', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final db = await DatabaseHelper().banco;

    // sem eventos = dormindo (nunca estudou)
    expect(await repo.humor(temaId), HumorBichinho.dormindo);

    // evento hoje = feliz
    await db.insert('eventos', {'evento': 'card_avaliado', 'tema': 'CFC'});
    expect(await repo.humor(temaId), HumorBichinho.feliz);
  });

  test('humor com evento retrodatado: 1 dia = neutro, 3 dias = comFome, 10 dias = dormindo', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final db = await DatabaseHelper().banco;

    // último estudo há 10 dias = dormindo
    await db.rawInsert(
      "INSERT INTO eventos (evento, tema, criado_em) VALUES (?, ?, datetime('now', '-10 days'))",
      ['card_avaliado', 'CFC'],
    );
    expect(await repo.humor(temaId), HumorBichinho.dormindo);

    // evento mais recente há 3 dias = comFome
    await db.rawInsert(
      "INSERT INTO eventos (evento, tema, criado_em) VALUES (?, ?, datetime('now', '-3 days'))",
      ['card_avaliado', 'CFC'],
    );
    expect(await repo.humor(temaId), HumorBichinho.comFome);

    // evento mais recente há 1 dia = neutro
    await db.rawInsert(
      "INSERT INTO eventos (evento, tema, criado_em) VALUES (?, ?, datetime('now', '-1 day'))",
      ['card_avaliado', 'CFC'],
    );
    expect(await repo.humor(temaId), HumorBichinho.neutro);
  });

  test('proximoThreshold retorna threshold do seed e null quando lendário', () async {
    final repo = BichinhoRepository();
    // força inicialização do banco (configs seedadas)
    await DatabaseHelper().banco;
    expect(await repo.proximoThreshold(0), 50);
    expect(await repo.proximoThreshold(Bichinho.estagioMax), isNull);
  });
}
