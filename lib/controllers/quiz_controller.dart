// lib/controllers/quiz_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../repositories/card_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/quiz_repository.dart';
import '../services/metrica_service.dart';

enum EstadoQuestao { aguardando, selecionada, tempoEsgotado }

class _RespostaLocal {
  final int cardId;
  final String? respostaEscolhida;
  final bool acertou;
  final int tempoSegundos;
  final int pontos;

  _RespostaLocal({
    required this.cardId,
    this.respostaEscolhida,
    required this.acertou,
    required this.tempoSegundos,
    required this.pontos,
  });
}

class QuizResultado {
  final int nota;
  final int estrelas;
  final bool aprovado;
  final int tempoTotalSegundos;
  final int faseId;
  final String nomeFase;
  final String nomeTema;

  QuizResultado({
    required this.nota,
    required this.estrelas,
    required this.aprovado,
    required this.tempoTotalSegundos,
    required this.faseId,
    required this.nomeFase,
    required this.nomeTema,
  });
}

class QuizController extends ChangeNotifier {
  final CardRepository _cardRepo;
  final ConfigRepository _configRepo;
  final QuizRepository _quizRepo;
  final MetricaService _metrica;

  // Estado da sessão
  List<CardModel> _questoes = [];
  List<String> _alternativasAtual = [];
  int _indiceCorreto = 0;
  int _indiceAtual = 0;
  int? _respostaSelecionada;
  EstadoQuestao _estado = EstadoQuestao.aguardando;
  bool carregando = true;

  // Timer
  Timer? _timer;
  int _segundosRestantes = 0;
  int _tempoPorQuestao = 30;

  // Dados da tentativa
  int _tentativaId = 0;
  int _tentativaNumero = 0;
  final List<_RespostaLocal> _respostas = [];
  DateTime? _inicioSessao;

  // Contexto
  int faseId = 0;
  String nomeFase = '';
  String nomeTema = '';

  QuizController({
    CardRepository? cardRepo,
    ConfigRepository? configRepo,
    QuizRepository? quizRepo,
    MetricaService? metrica,
  })  : _cardRepo = cardRepo ?? CardRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _quizRepo = quizRepo ?? QuizRepository(),
        _metrica = metrica ?? MetricaService();

  // Getters
  CardModel? get questaoAtual =>
      _questoes.isEmpty ? null : _questoes[_indiceAtual];
  List<String> get alternativasAtual => _alternativasAtual;
  int get indiceCorreto => _indiceCorreto;
  int? get respostaSelecionada => _respostaSelecionada;
  EstadoQuestao get estado => _estado;
  int get segundosRestantes => _segundosRestantes;
  int get tempoPorQuestao => _tempoPorQuestao;
  int get indiceAtual => _indiceAtual;
  int get totalQuestoes => _questoes.length;

  // Percentual de tempo restante (0.0 a 1.0)
  double get percentualTempo =>
      _tempoPorQuestao > 0 ? _segundosRestantes / _tempoPorQuestao : 0.0;

  Future<void> carregarQuiz(
      int novoFaseId, String novoNomeFase, String novoNomeTema) async {
    faseId = novoFaseId;
    nomeFase = novoNomeFase;
    nomeTema = novoNomeTema;
    carregando = true;
    notifyListeners();

    _tempoPorQuestao =
        await _configRepo.getValorInt('quiz_tempo_por_questao', padrao: 30);
    final numQuestoes =
        await _configRepo.getValorInt('quiz_num_questoes', padrao: 10);

    final todos = await _cardRepo.getCardsPorFase(faseId);
    todos.shuffle();
    _questoes = todos.take(numQuestoes).toList();

    _respostas.clear();
    _indiceAtual = 0;
    _inicioSessao = DateTime.now();

    _tentativaNumero = await _quizRepo.contarTentativas(faseId) + 1;
    _tentativaId = await _quizRepo.iniciarTentativa(faseId);

    await _metrica.quizIniciado(faseId, nomeTema, _tentativaNumero);

    _carregarAlternativasAtual();
    _iniciarTimer();

    carregando = false;
    notifyListeners();
  }

  void _carregarAlternativasAtual() {
    if (_questoes.isEmpty) return;
    final card = _questoes[_indiceAtual];
    _alternativasAtual = card.alternativasEmbaralhadas();
    _indiceCorreto = _alternativasAtual.indexOf(card.resposta);
    _respostaSelecionada = null;
    _estado = EstadoQuestao.aguardando;
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
        _timerEsgotou();
      }
    });
  }

  void _timerEsgotou() {
    _estado = EstadoQuestao.tempoEsgotado;
    notifyListeners();
  }

  void selecionarResposta(int indice) {
    if (_estado != EstadoQuestao.aguardando) return;
    _timer?.cancel();

    _respostaSelecionada = indice;
    _estado = EstadoQuestao.selecionada;
    notifyListeners();

    // Auto-avança após 1s
    Future.delayed(const Duration(milliseconds: 1000), () {
      _registrarRespostaEAvancar(indice: indice, timerEsgotou: false);
    });
  }

  void avancarAposTempoEsgotado() {
    if (_estado != EstadoQuestao.tempoEsgotado) return;
    _registrarRespostaEAvancar(indice: null, timerEsgotou: true);
  }

  Future<void> _registrarRespostaEAvancar({
    required int? indice,
    required bool timerEsgotou,
  }) async {
    final card = _questoes[_indiceAtual];
    final acertou = !timerEsgotou && indice == _indiceCorreto;
    final tempoGasto = _tempoPorQuestao - _segundosRestantes;
    final metadeTempo = _tempoPorQuestao / 2;
    final pontos = acertou ? (tempoGasto < metadeTempo ? 10 : 7) : 0;
    final respostaEscolhida =
        (indice != null) ? _alternativasAtual[indice] : null;

    _respostas.add(_RespostaLocal(
      cardId: card.id,
      respostaEscolhida: respostaEscolhida,
      acertou: acertou,
      tempoSegundos: tempoGasto,
      pontos: pontos,
    ));

    await _quizRepo.salvarResposta(
      tentativaId: _tentativaId,
      cardId: card.id,
      respostaEscolhida: respostaEscolhida,
      acertou: acertou,
      tempoSegundos: tempoGasto,
    );

    await _metrica.quizQuestaoRespondida(
      faseId: faseId,
      cardId: card.id,
      acertou: acertou,
      tempoS: tempoGasto,
      pontos: pontos,
      tentativaN: _tentativaNumero,
      nomeTema: nomeTema,
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

  bool get quizConcluido => _indiceAtual >= _questoes.length;

  Future<QuizResultado> concluir() async {
    _timer?.cancel();
    final totalPossivel = _questoes.length * 10;
    final somaObtida = _respostas.fold(0, (acc, r) => acc + r.pontos);
    final nota =
        totalPossivel > 0 ? (somaObtida / totalPossivel * 100).round() : 0;
    final estrelas = _calcularEstrelas(nota);
    final tempoTotal =
        DateTime.now().difference(_inicioSessao!).inSeconds;

    await _quizRepo.concluirTentativa(
      _tentativaId,
      pontuacao: nota,
      estrelas: estrelas,
      tempoTotalSegundos: tempoTotal,
    );

    await _metrica.quizConcluido(
      faseId: faseId,
      nota: nota,
      estrelas: estrelas,
      tempoTotalS: tempoTotal,
      tentativaN: _tentativaNumero,
      nomeTema: nomeTema,
    );

    return QuizResultado(
      nota: nota,
      estrelas: estrelas,
      aprovado: nota >= 70,
      tempoTotalSegundos: tempoTotal,
      faseId: faseId,
      nomeFase: nomeFase,
      nomeTema: nomeTema,
    );
  }

  Future<void> abandonar() async {
    _timer?.cancel();
    await _quizRepo.abandonarTentativa(_tentativaId);
    await _metrica.quizAbandonado(
      faseId: faseId,
      questaoAtual: _indiceAtual + 1,
      totalQuestoes: _questoes.length,
      tentativaN: _tentativaNumero,
      nomeTema: nomeTema,
    );
  }

  int _calcularEstrelas(int nota) {
    if (nota >= 90) return 3;
    if (nota >= 80) return 2;
    if (nota >= 70) return 1;
    return 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
