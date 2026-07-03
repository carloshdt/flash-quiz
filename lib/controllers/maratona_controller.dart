// lib/controllers/maratona_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bichinho.dart';
import '../models/card_model.dart';
import '../repositories/bichinho_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/modo_repository.dart';
import '../services/metrica_service.dart';

enum EstadoQuestaoMaratona { aguardando, tempoEsgotado }

class MaratonaResultado {
  final int score;
  final int recorde;
  final bool recordeBatido;
  final int tempoTotalSegundos;
  final int temaId;
  final String nomeTema;

  MaratonaResultado({
    required this.score,
    required this.recorde,
    required this.recordeBatido,
    required this.tempoTotalSegundos,
    required this.temaId,
    required this.nomeTema,
  });
}

class MaratonaController extends ChangeNotifier {
  final ModoRepository _modoRepo;
  final ConfigRepository _configRepo;
  final BichinhoRepository _bichinhoRepo;
  final MetricaService _metrica;

  List<CardModel> _pool = [];
  List<CardModel> _fila = [];
  int _indiceFila = 0;
  List<String> _alternativasAtual = [];
  int _indiceCorreto = 0;
  EstadoQuestaoMaratona _estado = EstadoQuestaoMaratona.aguardando;
  bool carregando = true;
  bool poolVazio = false;

  Timer? _timer;
  int _segundosRestantes = 0;
  int _tempoPorQuestao = 30;
  int _maxErros = 3;

  int _tentativaId = 0;
  int acertos = 0;
  int erros = 0;
  DateTime? _inicioSessao;

  int temaId = 0;
  String nomeTema = '';

  /// Último resultado de alimentar o bichinho — a UI usa pra animar evolução.
  ResultadoAlimentar? ultimoAlimentar;

  MaratonaController({
    ModoRepository? modoRepo,
    ConfigRepository? configRepo,
    BichinhoRepository? bichinhoRepo,
    MetricaService? metrica,
  })  : _modoRepo = modoRepo ?? ModoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _bichinhoRepo = bichinhoRepo ?? BichinhoRepository(),
        _metrica = metrica ?? MetricaService();

  CardModel? get questaoAtual =>
      (_fila.isEmpty || fimDeJogo) ? null : _fila[_indiceFila];
  List<String> get alternativasAtual => _alternativasAtual;
  int get indiceCorreto => _indiceCorreto;
  EstadoQuestaoMaratona get estado => _estado;
  int get segundosRestantes => _segundosRestantes;
  int get maxErros => _maxErros;
  bool get fimDeJogo => erros >= _maxErros;

  double get percentualTempo =>
      _tempoPorQuestao > 0 ? _segundosRestantes / _tempoPorQuestao : 0.0;

  Future<void> carregar(int novoTemaId, String novoNomeTema) async {
    temaId = novoTemaId;
    nomeTema = novoNomeTema;
    carregando = true;
    notifyListeners();

    _tempoPorQuestao =
        await _configRepo.getValorInt('quiz_tempo_por_questao', padrao: 30);
    _maxErros = await _configRepo.getValorInt('maratona_max_erros', padrao: 3);

    _pool = await _modoRepo.cardsPoolDesbloqueado(temaId);
    if (_pool.isEmpty) {
      poolVazio = true;
      carregando = false;
      notifyListeners();
      return;
    }

    _fila = List.of(_pool)..shuffle();
    _indiceFila = 0;
    acertos = 0;
    erros = 0;
    _inicioSessao = DateTime.now();

    _tentativaId = await _modoRepo.iniciarTentativa('maratona', temaId);
    await _metrica.maratonaIniciada(temaId, nomeTema);

    _carregarAlternativasAtual();
    _iniciarTimer();

    carregando = false;
    notifyListeners();
  }

  void _carregarAlternativasAtual() {
    final card = _fila[_indiceFila];
    _alternativasAtual = card.alternativasEmbaralhadas();
    _indiceCorreto = _alternativasAtual.indexOf(card.resposta);
    _estado = EstadoQuestaoMaratona.aguardando;
    _segundosRestantes = _tempoPorQuestao;
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes > 0) {
        _segundosRestantes--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _estado = EstadoQuestaoMaratona.tempoEsgotado;
        notifyListeners();
      }
    });
  }

  // Registra e avança imediatamente (sem delay de 1s — modo arcade)
  void selecionarResposta(int indice) {
    if (_estado != EstadoQuestaoMaratona.aguardando || fimDeJogo) return;
    _timer?.cancel();
    _registrarEAvancar(acertou: indice == _indiceCorreto);
  }

  void avancarAposTempoEsgotado() {
    if (_estado != EstadoQuestaoMaratona.tempoEsgotado) return;
    _registrarEAvancar(acertou: false);
  }

  void _registrarEAvancar({required bool acertou}) {
    if (acertou) {
      acertos++;
    } else {
      erros++;
    }

    if (fimDeJogo) {
      _timer?.cancel();
      notifyListeners();
      return;
    }

    _indiceFila++;
    // Pool esgotado: re-embaralha e recomeça a fila
    if (_indiceFila >= _fila.length) {
      _fila = List.of(_pool)..shuffle();
      _indiceFila = 0;
    }

    _carregarAlternativasAtual();
    _iniciarTimer();
    notifyListeners();
  }

  Future<MaratonaResultado> concluir() async {
    _timer?.cancel();
    final tempoTotal =
        DateTime.now().difference(_inicioSessao ?? DateTime.now()).inSeconds;

    final recordeAnterior = await _modoRepo.recordeMaratona(temaId);
    final recordeBatido = acertos > recordeAnterior;

    await _modoRepo.concluirTentativa(
      _tentativaId,
      pontuacao: acertos,
      tempoTotalSegundos: tempoTotal,
    );

    await _metrica.maratonaConcluida(
      temaId: temaId,
      nomeTema: nomeTema,
      score: acertos,
      recordeBatido: recordeBatido,
      tempoTotalS: tempoTotal,
    );

    // Alimenta o bichinho do tema com a energia do modo concluído (config).
    final energia =
        await _configRepo.getValorInt('bichinho_energia_modo', padrao: 10);
    ultimoAlimentar = await _bichinhoRepo.alimentar(temaId, energia);
    await _metrica.bichinhoAlimentado(
        nomeTema, ultimoAlimentar!.energiaGanha, ultimoAlimentar!.bichinho.energia);
    if (ultimoAlimentar!.evoluiu) {
      await _metrica.bichinhoEvoluiu(nomeTema, ultimoAlimentar!.bichinho.estagio);
    }

    return MaratonaResultado(
      score: acertos,
      recorde: recordeBatido ? acertos : recordeAnterior,
      recordeBatido: recordeBatido,
      tempoTotalSegundos: tempoTotal,
      temaId: temaId,
      nomeTema: nomeTema,
    );
  }

  Future<void> abandonar() async {
    _timer?.cancel();
    await _modoRepo.abandonarTentativa(_tentativaId);
    await _metrica.maratonaAbandonada(
      temaId: temaId,
      nomeTema: nomeTema,
      scoreParcial: acertos,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
