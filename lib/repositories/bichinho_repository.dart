// lib/repositories/bichinho_repository.dart
// Bichinho virtual: criação, alimentação (energia), evolução e humor.
// Streak lido de perfil.streak_atual (>0 = ativo). Config define valores.
import '../db/database_helper.dart';
import '../models/bichinho.dart';
import 'config_repository.dart';

class BichinhoRepository {
  final DatabaseHelper _db;
  final ConfigRepository _config;

  BichinhoRepository({DatabaseHelper? db, ConfigRepository? config})
      : _db = db ?? DatabaseHelper(),
        _config = config ?? ConfigRepository();

  static const int numEspecies = 3;

  /// Padrões dos thresholds de evolução — espelho dos seeds da migration v5.
  /// Evita que config faltando (padrão implícito 0) vire lendário instantâneo.
  static const _thresholdsPadrao = [50, 200, 500, 1000];

  Future<BichinhoCriacao> obterOuCriar(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.query('bichinhos', where: 'tema_id = ?', whereArgs: [temaId]);
    if (rows.isNotEmpty) {
      return BichinhoCriacao(bichinho: Bichinho.fromMap(rows.first), criado: false);
    }

    final id = await banco.insert('bichinhos', {
      'tema_id': temaId,
      'especie': temaId % numEspecies,
      'estagio': 0,
      'energia': 0,
    });
    final novo = await banco.query('bichinhos', where: 'id = ?', whereArgs: [id]);
    return BichinhoCriacao(bichinho: Bichinho.fromMap(novo.first), criado: true);
  }

  /// Soma energia (com multiplicador de streak) e promove estágio se cruzar threshold.
  Future<ResultadoAlimentar> alimentar(int temaId, int energiaBase) async {
    final banco = await _db.banco;
    final atual = (await obterOuCriar(temaId)).bichinho;

    final mult = await _multiplicadorStreak();
    final ganho = (energiaBase * mult).floor();
    final energiaNova = atual.energia + ganho;

    final estagioNovo = await _estagioPara(energiaNova);
    final evoluiu = estagioNovo > atual.estagio;

    await banco.update(
      'bichinhos',
      {
        'energia': energiaNova,
        'estagio': estagioNovo,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'tema_id = ?',
      whereArgs: [temaId],
    );

    final atualizado = (await obterOuCriar(temaId)).bichinho;
    return ResultadoAlimentar(bichinho: atualizado, energiaGanha: ganho, evoluiu: evoluiu);
  }

  /// Threshold de energia pro próximo estágio (null se lendário).
  Future<int?> proximoThreshold(int estagio) async {
    if (estagio >= Bichinho.estagioMax) return null;
    return _config.getValorInt(
      'bichinho_threshold_${estagio + 1}',
      padrao: _thresholdsPadrao[estagio],
    );
  }

  /// Humor calculado da última atividade registrada em eventos pro tema.
  Future<HumorBichinho> humor(int temaId) async {
    final banco = await _db.banco;
    final tema = await banco.query('temas', where: 'id = ?', whereArgs: [temaId]);
    if (tema.isEmpty) return HumorBichinho.dormindo;
    final nomeTema = tema.first['nome'] as String;

    final rows = await banco.rawQuery(
      '''SELECT CAST(julianday('now', 'localtime') - julianday(MAX(criado_em), 'localtime') AS INTEGER) AS dias
         FROM eventos WHERE tema = ?''',
      [nomeTema],
    );
    final dias = rows.first['dias'] as int?;
    if (dias == null) return HumorBichinho.dormindo; // nunca estudou

    final diasFome = await _config.getValorInt('bichinho_dias_fome', padrao: 2);
    final diasDormindo = await _config.getValorInt('bichinho_dias_dormindo', padrao: 7);

    if (dias >= diasDormindo) return HumorBichinho.dormindo;
    if (dias >= diasFome) return HumorBichinho.comFome;
    if (dias >= 1) return HumorBichinho.neutro;
    return HumorBichinho.feliz;
  }

  /// Multiplicador de energia quando o streak está ativo (perfil.streak_atual > 0).
  Future<double> _multiplicadorStreak() async {
    final banco = await _db.banco;
    final rows = await banco.query('perfil', limit: 1);
    final streak = rows.isEmpty ? 0 : (rows.first['streak_atual'] as int? ?? 0);
    if (streak <= 0) return 1.0;
    final config = await _config.getConfig('bichinho_streak_multiplicador');
    return double.tryParse(config?.valor ?? '1.5') ?? 1.5;
  }

  /// Maior estágio cujo threshold foi atingido pela energia acumulada.
  Future<int> _estagioPara(int energia) async {
    var estagio = 0;
    for (var i = 1; i <= Bichinho.estagioMax; i++) {
      final t = await _config.getValorInt(
        'bichinho_threshold_$i',
        padrao: _thresholdsPadrao[i - 1],
      );
      if (energia >= t) estagio = i;
    }
    return estagio;
  }
}
