// lib/controllers/flashcard_controller.dart
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../repositories/progresso_repository.dart';
import '../repositories/config_repository.dart';
import '../services/metrica_service.dart';

class FlashcardController extends ChangeNotifier {
  final ProgressoRepository _progressoRepo;
  final ConfigRepository _configRepo;
  final MetricaService _metrica;

  List<CardModel> _cards = [];
  int _indiceAtual = 0;
  bool _virado = false;
  bool _sessaoConcluida = false;
  bool carregando = true;

  int faseId = 0;
  String nomeFase = '';
  String nomeTema = '';

  FlashcardController({
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
    MetricaService? metrica,
  })  : _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _metrica = metrica ?? MetricaService();

  CardModel? get cardAtual =>
      (_cards.isEmpty || _sessaoConcluida) ? null : _cards[_indiceAtual];

  bool get virado => _virado;
  bool get sessaoConcluida => _sessaoConcluida;
  int get totalSessao => _cards.length;
  int get indiceAtual => _indiceAtual;

  Future<void> carregarSessao(
      int novoFaseId, String novoNomeFase, String novoNomeTema) async {
    faseId = novoFaseId;
    nomeFase = novoNomeFase;
    nomeTema = novoNomeTema;
    carregando = true;
    _virado = false;
    _indiceAtual = 0;
    _sessaoConcluida = false;
    _cards = [];
    notifyListeners();

    final limite =
        await _configRepo.getValorInt('flashcard_cards_por_sessao', padrao: 20);
    _cards = await _progressoRepo.getCardsParaSessao(novoFaseId, limite);

    if (_cards.isEmpty) {
      _sessaoConcluida = true;
    } else {
      await _metrica.cardVisto(_cards[0].id, novoFaseId, novoNomeTema);
    }

    carregando = false;
    notifyListeners();
  }

  // Vira o card (revela resposta). Só pode virar uma vez por card.
  void virar() {
    if (_virado || _sessaoConcluida) return;
    _virado = true;
    notifyListeners();
  }

  // Avalia o card atual com nível SRS 0/1/2. Só funciona depois de virar.
  Future<void> avaliar(int nivelSrs) async {
    if (!_virado || _sessaoConcluida) return;
    final card = _cards[_indiceAtual];

    await _progressoRepo.salvarProgresso(card.id, nivelSrs);
    await _metrica.cardAvaliado(card.id, nivelSrs, nomeTema);

    _indiceAtual++;
    _virado = false;

    if (_indiceAtual >= _cards.length) {
      _sessaoConcluida = true;
    } else {
      await _metrica.cardVisto(_cards[_indiceAtual].id, faseId, nomeTema);
    }

    notifyListeners();
  }
}
