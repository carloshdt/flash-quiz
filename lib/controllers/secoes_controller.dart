// lib/controllers/secoes_controller.dart
import 'package:flutter/foundation.dart';
import '../models/bichinho.dart';
import '../models/secao.dart';
import '../repositories/bichinho_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/secao_repository.dart';
import '../repositories/modo_repository.dart';
import '../services/metrica_service.dart';

class SecoesController extends ChangeNotifier {
  final SecaoRepository _repo;
  final MetricaService _metrica;
  final ModoRepository _modoRepo;
  final ConfigRepository _configRepo;
  final BichinhoRepository _bichinhoRepo;

  List<Secao> secoes = [];
  Map<int, double> progressoPorSecao = {};
  double progressoGeral = 0.0;
  bool carregando = false;

  int? notaDesafioHoje;      // null = desafio de hoje ainda não feito
  int cardsVencidos = 0;
  int recordeMaratona = 0;

  int desafioNumQuestoes = 5;
  int maratonaMaxErros = 3;

  // Bichinho do tema (header da tela)
  Bichinho? bichinho;
  HumorBichinho humorBichinho = HumorBichinho.feliz;
  int? proximoThreshold; // null = lendário

  String _nomeTema = '';

  SecoesController({SecaoRepository? repo, MetricaService? metrica, ModoRepository? modoRepo, ConfigRepository? configRepo, BichinhoRepository? bichinhoRepo})
      : _repo = repo ?? SecaoRepository(),
        _metrica = metrica ?? MetricaService(),
        _modoRepo = modoRepo ?? ModoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _bichinhoRepo = bichinhoRepo ?? BichinhoRepository();

  Future<void> carregar(int temaId, String nomeTema) async {
    carregando = true;
    notifyListeners();

    _nomeTema = nomeTema;

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

    // Bichinho do tema — obterOuCriar é idempotente (Home também cria o ovo)
    final criacao = await _bichinhoRepo.obterOuCriar(temaId);
    bichinho = criacao.bichinho;
    humorBichinho = await _bichinhoRepo.humor(temaId);
    proximoThreshold = await _bichinhoRepo.proximoThreshold(bichinho!.estagio);
    if (criacao.criado) {
      await _metrica.bichinhoNasceu(nomeTema, criacao.bichinho.especie);
    }

    await _metrica.temaSelecionado(temaId, nomeTema);

    carregando = false;
    notifyListeners();
  }

  /// Registra a métrica de abertura do popup do bichinho (chamado pela tela no tap).
  Future<void> registrarPopupAberto() async {
    if (bichinho == null) return;
    await _metrica.bichinhoPopupAberto(_nomeTema, bichinho!.estagio);
  }
}
