// lib/controllers/secoes_controller.dart
import 'package:flutter/foundation.dart';
import '../models/secao.dart';
import '../repositories/config_repository.dart';
import '../repositories/secao_repository.dart';
import '../repositories/modo_repository.dart';
import '../services/metrica_service.dart';

class SecoesController extends ChangeNotifier {
  final SecaoRepository _repo;
  final MetricaService _metrica;
  final ModoRepository _modoRepo;
  final ConfigRepository _configRepo;

  List<Secao> secoes = [];
  Map<int, double> progressoPorSecao = {};
  double progressoGeral = 0.0;
  bool carregando = false;

  int? notaDesafioHoje;      // null = desafio de hoje ainda não feito
  int cardsVencidos = 0;
  int recordeMaratona = 0;

  int desafioNumQuestoes = 5;
  int maratonaMaxErros = 3;

  SecoesController({SecaoRepository? repo, MetricaService? metrica, ModoRepository? modoRepo, ConfigRepository? configRepo})
      : _repo = repo ?? SecaoRepository(),
        _metrica = metrica ?? MetricaService(),
        _modoRepo = modoRepo ?? ModoRepository(),
        _configRepo = configRepo ?? ConfigRepository();

  Future<void> carregar(int temaId, String nomeTema) async {
    carregando = true;
    notifyListeners();

    secoes = await _repo.getSecoesPorTema(temaId);
    progressoPorSecao = await _repo.getProgressoPorTema(temaId);

    final vals = progressoPorSecao.values;
    progressoGeral = vals.isEmpty
        ? 0.0
        : vals.reduce((a, b) => a + b) / vals.length;

    notaDesafioHoje = await _modoRepo.notaDesafioHoje(temaId);
    cardsVencidos = await _modoRepo.contarCardsVencidos(temaId);
    recordeMaratona = await _modoRepo.recordeMaratona(temaId);

    desafioNumQuestoes = await _configRepo.getValorInt('desafio_num_questoes', padrao: 5);
    maratonaMaxErros = await _configRepo.getValorInt('maratona_max_erros', padrao: 3);

    await _metrica.temaSelecionado(temaId, nomeTema);

    carregando = false;
    notifyListeners();
  }
}
