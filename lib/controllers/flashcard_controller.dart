// lib/controllers/flashcard_controller.dart
import 'package:flutter/foundation.dart';
import '../models/bichinho.dart';
import '../models/card_model.dart';
import '../repositories/config_repository.dart';
import '../repositories/progresso_repository.dart';
import '../repositories/tema_repository.dart';
import '../services/bichinho_service.dart';
import '../services/metrica_service.dart';

class FlashcardController extends ChangeNotifier {
  final ProgressoRepository _progressoRepo;
  final ConfigRepository _configRepo;
  final TemaRepository _temaRepo;
  final BichinhoService _bichinhoService;
  final MetricaService _metrica;

  List<CardModel> _cards = [];
  int _indiceAtual = 0;
  bool _virado = false;
  bool _sessaoConcluida = false;
  bool carregando = true;

  int faseId = 0;
  String nomeFase = '';
  String nomeTema = '';
  int? _temaId; // resolvido 1x no carregarSessao (a rota só passa o nome do tema)

  /// Último resultado de alimentar o bichinho — a UI usa pra animar evolução.
  ResultadoAlimentar? ultimoAlimentar;

  FlashcardController({
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
    TemaRepository? temaRepo,
    BichinhoService? bichinhoService,
    MetricaService? metrica,
  })  : _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _temaRepo = temaRepo ?? TemaRepository(),
        _bichinhoService = bichinhoService ?? BichinhoService(),
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

    // Resolve o id do tema pelo nome — necessário pro bichinho (sem SQL aqui).
    _temaId = (await _temaRepo.getTemaPorNome(novoNomeTema))?.id;

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
    ultimoAlimentar = await _bichinhoService.alimentarComMetricas(
      temaId: _temaId,
      nomeTema: nomeTema,
      chaveEnergia: 'bichinho_energia_card',
      padrao: 2,
    );

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
