// lib/controllers/revisao_controller.dart
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../repositories/config_repository.dart';
import '../repositories/modo_repository.dart';
import '../repositories/progresso_repository.dart';
import '../services/metrica_service.dart';

class RevisaoController extends ChangeNotifier {
  final ModoRepository _modoRepo;
  final ProgressoRepository _progressoRepo;
  final ConfigRepository _configRepo;
  final MetricaService _metrica;

  List<CardModel> _cards = [];
  int _indiceAtual = 0;
  bool _virado = false;
  bool _sessaoConcluida = false;
  bool carregando = true;
  bool tudoEmDia = false;
  DateTime? _inicioSessao;

  int temaId = 0;
  String nomeTema = '';

  RevisaoController({
    ModoRepository? modoRepo,
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
    MetricaService? metrica,
  })  : _modoRepo = modoRepo ?? ModoRepository(),
        _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _metrica = metrica ?? MetricaService();

  CardModel? get cardAtual =>
      (_cards.isEmpty || _sessaoConcluida) ? null : _cards[_indiceAtual];
  bool get virado => _virado;
  bool get sessaoConcluida => _sessaoConcluida;
  int get totalSessao => _cards.length;
  int get indiceAtual => _indiceAtual;

  Future<void> carregarSessao(int novoTemaId, String novoNomeTema) async {
    temaId = novoTemaId;
    nomeTema = novoNomeTema;
    carregando = true;
    _virado = false;
    _indiceAtual = 0;
    _sessaoConcluida = false;
    tudoEmDia = false;
    _cards = [];
    notifyListeners();

    final limite =
        await _configRepo.getValorInt('revisao_max_cards', padrao: 20);
    _cards = await _modoRepo.cardsVencidos(temaId, limite);

    if (_cards.isEmpty) {
      tudoEmDia = true;
    } else {
      _inicioSessao = DateTime.now();
      await _metrica.revisaoIniciada(temaId, nomeTema, _cards.length);
      await _metrica.cardVisto(_cards[0].id, _cards[0].faseId, nomeTema);
    }

    carregando = false;
    notifyListeners();
  }

  void virar() {
    if (_virado || _sessaoConcluida) return;
    _virado = true;
    notifyListeners();
  }

  Future<void> avaliar(int nivelSrs) async {
    if (!_virado || _sessaoConcluida) return;
    final card = _cards[_indiceAtual];

    await _progressoRepo.salvarProgresso(card.id, nivelSrs);
    await _metrica.cardAvaliado(card.id, nivelSrs, nomeTema);

    _indiceAtual++;
    _virado = false;

    if (_indiceAtual >= _cards.length) {
      _sessaoConcluida = true;
      final tempoTotal =
          DateTime.now().difference(_inicioSessao ?? DateTime.now()).inSeconds;
      await _metrica.revisaoConcluida(
        temaId: temaId,
        nomeTema: nomeTema,
        cardsRevisados: _cards.length,
        tempoTotalS: tempoTotal,
      );
    } else {
      await _metrica.cardVisto(
          _cards[_indiceAtual].id, _cards[_indiceAtual].faseId, nomeTema);
    }

    notifyListeners();
  }
}
