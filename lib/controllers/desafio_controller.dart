// lib/controllers/desafio_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../repositories/config_repository.dart';
import '../repositories/modo_repository.dart';
import '../services/metrica_service.dart';
import '../services/quiz_pontuacao.dart';

enum EstadoQuestaoDesafio { aguardando, selecionada, tempoEsgotado }

class DesafioResultado {
  final int nota;
  final int tempoTotalSegundos;
  final int temaId;
  final String nomeTema;

  DesafioResultado({
    required this.nota,
    required this.tempoTotalSegundos,
    required this.temaId,
    required this.nomeTema,
  });
}

class DesafioController extends ChangeNotifier {
  final ModoRepository _modoRepo;
  final ConfigRepository _configRepo;
  final MetricaService _metrica;

  List<CardModel> _questoes = [];
  List<String> _alternativasAtual = [];
  int _indiceCorreto = 0;
  int _indiceAtual = 0;
  int? _respostaSelecionada;
  EstadoQuestaoDesafio _estado = EstadoQuestaoDesafio.aguardando;
  bool carregando = true;
  bool poolVazio = false;
  bool _disposed = false;

  Timer? _timer;
  int _segundosRestantes = 0;
  int _tempoPorQuestao = 30;

  int _tentativaId = 0;
  int _somaPontos = 0;
  DateTime? _inicioSessao;

  int temaId = 0;
  String nomeTema = '';

  DesafioController({
    ModoRepository? modoRepo,
    ConfigRepository? configRepo,
    MetricaService? metrica,
  })  : _modoRepo = modoRepo ?? ModoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _metrica = metrica ?? MetricaService();

  CardModel? get questaoAtual =>
      _questoes.isEmpty ? null : _questoes[_indiceAtual];
  List<String> get alternativasAtual => _alternativasAtual;
  int? get respostaSelecionada => _respostaSelecionada;
  EstadoQuestaoDesafio get estado => _estado;
  int get segundosRestantes => _segundosRestantes;
  int get indiceAtual => _indiceAtual;
  int get totalQuestoes => _questoes.length;
  bool get desafioConcluido => _questoes.isNotEmpty && _indiceAtual >= _questoes.length;

  double get percentualTempo =>
      _tempoPorQuestao > 0 ? _segundosRestantes / _tempoPorQuestao : 0.0;

  Future<void> carregar(int novoTemaId, String novoNomeTema) async {
    temaId = novoTemaId;
    nomeTema = novoNomeTema;
    carregando = true;
    notifyListeners();

    _tempoPorQuestao =
        await _configRepo.getValorInt('quiz_tempo_por_questao', padrao: 30);
    final numQuestoes =
        await _configRepo.getValorInt('desafio_num_questoes', padrao: 5);

    final pool = await _modoRepo.cardsPoolDesbloqueado(temaId);
    if (pool.isEmpty) {
      poolVazio = true;
      carregando = false;
      notifyListeners();
      return;
    }

    pool.shuffle();
    _questoes = pool.take(numQuestoes).toList();
    _indiceAtual = 0;
    _somaPontos = 0;
    _inicioSessao = DateTime.now();

    _tentativaId = await _modoRepo.iniciarTentativa('desafio', temaId);
    await _metrica.desafioIniciado(temaId, nomeTema, _questoes.length);

    _carregarAlternativasAtual();
    _iniciarTimer();

    carregando = false;
    notifyListeners();
  }

  void _carregarAlternativasAtual() {
    final card = _questoes[_indiceAtual];
    _alternativasAtual = card.alternativasEmbaralhadas();
    _indiceCorreto = _alternativasAtual.indexOf(card.resposta);
    _respostaSelecionada = null;
    _estado = EstadoQuestaoDesafio.aguardando;
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
        _estado = EstadoQuestaoDesafio.tempoEsgotado;
        notifyListeners();
      }
    });
  }

  void selecionarResposta(int indice) {
    if (_estado != EstadoQuestaoDesafio.aguardando) return;
    _timer?.cancel();

    _respostaSelecionada = indice;
    _estado = EstadoQuestaoDesafio.selecionada;
    notifyListeners();

    // Auto-avança após 1s (mesmo comportamento do quiz de fase)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_disposed) _registrarEAvancar(indice: indice, timerEsgotou: false);
    });
  }

  void avancarAposTempoEsgotado() {
    if (_estado != EstadoQuestaoDesafio.tempoEsgotado) return;
    _registrarEAvancar(indice: null, timerEsgotou: true);
  }

  void _registrarEAvancar({required int? indice, required bool timerEsgotou}) {
    final acertou = !timerEsgotou && indice == _indiceCorreto;
    final tempoGasto = _tempoPorQuestao - _segundosRestantes;
    _somaPontos += QuizPontuacao.pontosQuestao(
      acertou: acertou,
      tempoGasto: tempoGasto,
      tempoPorQuestao: _tempoPorQuestao,
    );

    _indiceAtual++;
    if (_indiceAtual >= _questoes.length) {
      notifyListeners();
    } else {
      _carregarAlternativasAtual();
      _iniciarTimer();
      notifyListeners();
    }
  }

  Future<DesafioResultado> concluir() async {
    _timer?.cancel();
    final nota = QuizPontuacao.nota(_somaPontos, _questoes.length);
    final tempoTotal =
        DateTime.now().difference(_inicioSessao ?? DateTime.now()).inSeconds;

    await _modoRepo.concluirTentativa(
      _tentativaId,
      pontuacao: nota,
      tempoTotalSegundos: tempoTotal,
    );

    await _metrica.desafioConcluido(
      temaId: temaId,
      nomeTema: nomeTema,
      nota: nota,
      tempoTotalS: tempoTotal,
    );

    return DesafioResultado(
      nota: nota,
      tempoTotalSegundos: tempoTotal,
      temaId: temaId,
      nomeTema: nomeTema,
    );
  }

  Future<void> abandonar() async {
    _timer?.cancel();
    await _modoRepo.abandonarTentativa(_tentativaId);
    await _metrica.desafioAbandonado(
      temaId: temaId,
      nomeTema: nomeTema,
      questaoAtual: _indiceAtual + 1,
      totalQuestoes: _questoes.length,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
