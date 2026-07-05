# Quiz Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar QuizScreen + QuizResultScreen + QuizController + QuizRepository, integrando com TrilhaController para desbloquear fases via nota ≥ 70.

**Architecture:** QuizController gerencia o estado da sessão de quiz (timer, respostas, pontuação) usando QuizRepository para persistir tentativas e respostas. TrilhaController é atualizado para carregar melhorTentativa do banco, e BottomSheetQuiz é conectado à rota `/quiz/:faseId`.

**Tech Stack:** Flutter 3.x · sqflite · provider · go_router · dart:async (Timer)

---

## Mapa de Arquivos

| Ação | Arquivo |
|---|---|
| Criar | `lib/repositories/quiz_repository.dart` |
| Criar | `lib/controllers/quiz_controller.dart` |
| Criar | `lib/screens/quiz/quiz_screen.dart` |
| Criar | `lib/screens/quiz/quiz_result_screen.dart` |
| Criar | `test/repositories/quiz_repository_test.dart` |
| Modificar | `lib/services/metrica_service.dart` |
| Modificar | `lib/controllers/trilha_controller.dart` |
| Modificar | `lib/screens/trilha/widgets/bottom_sheet_quiz.dart` |
| Modificar | `lib/app.dart` |

---

## Task 1: QuizRepository

**Files:**
- Create: `lib/repositories/quiz_repository.dart`
- Test: `test/repositories/quiz_repository_test.dart`

- [ ] **Step 1: Criar o arquivo de teste**

```dart
// test/repositories/quiz_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/quiz_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath);
  });

  setUp(() async {
    await DatabaseHelper().fecharParaTeste();
  });

  tearDown(() async {
    await DatabaseHelper().fecharParaTeste();
  });

  test('iniciarTentativa retorna id válido', () async {
    final repo = QuizRepository();
    final id = await repo.iniciarTentativa(1);
    expect(id, greaterThan(0));
  });

  test('concluirTentativa salva pontuacao e estrelas', () async {
    final repo = QuizRepository();
    final tentativaId = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(tentativaId, pontuacao: 85, estrelas: 2, tempoTotalSegundos: 120);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('quiz_tentativas', where: 'id = ?', whereArgs: [tentativaId]);
    expect(rows.first['pontuacao'], 85);
    expect(rows.first['estrelas'], 2);
    expect(rows.first['concluido'], 1);
  });

  test('melhorTentativa retorna tentativa com maior pontuacao', () async {
    final repo = QuizRepository();
    final id1 = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(id1, pontuacao: 70, estrelas: 1, tempoTotalSegundos: 100);
    final id2 = await repo.iniciarTentativa(1);
    await repo.concluirTentativa(id2, pontuacao: 90, estrelas: 3, tempoTotalSegundos: 80);

    final melhor = await repo.melhorTentativa(1);
    expect(melhor?.pontuacao, 90);
  });

  test('melhorTentativa retorna null quando não há tentativas', () async {
    final repo = QuizRepository();
    final melhor = await repo.melhorTentativa(999);
    expect(melhor, isNull);
  });

  test('abandonarTentativa marca concluido como false', () async {
    final repo = QuizRepository();
    final id = await repo.iniciarTentativa(1);
    await repo.abandonarTentativa(id);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('quiz_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['concluido'], 0);
  });

  test('contarTentativas conta apenas tentativas da fase', () async {
    final repo = QuizRepository();
    await repo.iniciarTentativa(1);
    await repo.iniciarTentativa(1);
    await repo.iniciarTentativa(2);

    expect(await repo.contarTentativas(1), 2);
    expect(await repo.contarTentativas(2), 1);
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

```
flutter test test/repositories/quiz_repository_test.dart
```
Esperado: FAIL — `QuizRepository` não existe.

- [ ] **Step 3: Criar QuizRepository**

```dart
// lib/repositories/quiz_repository.dart
import '../db/database_helper.dart';
import '../models/quiz_tentativa.dart';

class QuizRepository {
  final DatabaseHelper _db;
  QuizRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<int> iniciarTentativa(int faseId) async {
    final banco = await _db.banco;
    return banco.insert('quiz_tentativas', {
      'fase_id': faseId,
      'pontuacao': 0,
      'estrelas': 0,
      'concluido': 0,
    });
  }

  Future<void> concluirTentativa(
    int tentativaId, {
    required int pontuacao,
    required int estrelas,
    required int tempoTotalSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.update(
      'quiz_tentativas',
      {
        'pontuacao': pontuacao,
        'estrelas': estrelas,
        'tempo_total_segundos': tempoTotalSegundos,
        'concluido': 1,
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  Future<void> abandonarTentativa(int tentativaId) async {
    final banco = await _db.banco;
    await banco.update(
      'quiz_tentativas',
      {'concluido': 0},
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  Future<QuizTentativa?> melhorTentativa(int faseId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery(
      '''SELECT * FROM quiz_tentativas
         WHERE fase_id = ? AND concluido = 1
         ORDER BY pontuacao DESC
         LIMIT 1''',
      [faseId],
    );
    if (rows.isEmpty) return null;
    return QuizTentativa.fromMap(rows.first);
  }

  Future<int> contarTentativas(int faseId) async {
    final banco = await _db.banco;
    final result = await banco.rawQuery(
      'SELECT COUNT(*) as total FROM quiz_tentativas WHERE fase_id = ?',
      [faseId],
    );
    return result.first['total'] as int;
  }

  Future<void> salvarResposta({
    required int tentativaId,
    required int cardId,
    String? respostaEscolhida,
    required bool acertou,
    required int tempoSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.insert('quiz_respostas', {
      'tentativa_id': tentativaId,
      'card_id': cardId,
      'resposta_escolhida': respostaEscolhida,
      'acertou': acertou ? 1 : 0,
      'tempo_segundos': tempoSegundos,
    });
  }
}
```

- [ ] **Step 4: Rodar os testes**

```
flutter test test/repositories/quiz_repository_test.dart
```
Esperado: todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/repositories/quiz_repository.dart test/repositories/quiz_repository_test.dart
git commit -m "feat(quiz): QuizRepository com tentativas e respostas"
```

---

## Task 2: MetricaService — Métodos de Quiz

**Files:**
- Modify: `lib/services/metrica_service.dart`

- [ ] **Step 1: Adicionar métodos de quiz ao MetricaService**

Adicionar ao final da classe `MetricaService` (antes do fechamento `}`):

```dart
  Future<void> quizIniciado(int faseId, String nomeTema, int tentativaN) =>
      _repo.registrar(Evento(
        evento: 'quiz_iniciado',
        tema: nomeTema,
        metadata: {'fase_id': faseId, 'tentativa_n': tentativaN},
      ));

  Future<void> quizQuestaoRespondida({
    required int faseId,
    required int cardId,
    required bool acertou,
    required int tempoS,
    required int pontos,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_questao_respondida',
        tema: nomeTema,
        valor: acertou ? 'acerto' : 'erro',
        metadata: {
          'fase_id': faseId,
          'card_id': cardId,
          'acertou': acertou,
          'tempo_s': tempoS,
          'pontos': pontos,
          'tentativa_n': tentativaN,
        },
      ));

  Future<void> quizConcluido({
    required int faseId,
    required int nota,
    required int estrelas,
    required int tempoTotalS,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_concluido',
        tema: nomeTema,
        valor: '$nota',
        metadata: {
          'fase_id': faseId,
          'nota': nota,
          'estrelas': estrelas,
          'tempo_total_s': tempoTotalS,
          'tentativa_n': tentativaN,
        },
      ));

  Future<void> quizAbandonado({
    required int faseId,
    required int questaoAtual,
    required int totalQuestoes,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_abandonado',
        tema: nomeTema,
        metadata: {
          'fase_id': faseId,
          'questao_atual': questaoAtual,
          'total_questoes': totalQuestoes,
          'tentativa_n': tentativaN,
        },
      ));
```

- [ ] **Step 2: Verificar que o app compila**

```
flutter analyze lib/services/metrica_service.dart
```
Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/services/metrica_service.dart
git commit -m "feat(quiz): métodos de quiz no MetricaService"
```

---

## Task 3: QuizController

**Files:**
- Create: `lib/controllers/quiz_controller.dart`

- [ ] **Step 1: Criar QuizController**

```dart
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
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/controllers/quiz_controller.dart
```
Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/controllers/quiz_controller.dart
git commit -m "feat(quiz): QuizController com timer, pontuação e abandon"
```

---

## Task 4: QuizScreen

**Files:**
- Create: `lib/screens/quiz/quiz_screen.dart`

- [ ] **Step 1: Criar QuizScreen**

```dart
// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';

class QuizScreen extends StatefulWidget {
  final int faseId;
  final String nomeFase;
  final String nomeTema;

  const QuizScreen({
    super.key,
    required this.faseId,
    required this.nomeFase,
    required this.nomeTema,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  bool _concluindo = false; // guard: evita concluir() duplo

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizController>().carregarQuiz(
            widget.faseId,
            widget.nomeFase,
            widget.nomeTema,
          );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3A),
        title: const Text('Sair do quiz?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Esta tentativa será registrada como abandonada.',
          style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF90CAF9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<QuizController>().abandonar();
      if (mounted) context.pop();
    }
    return false;
  }

  Future<void> _irParaResultado(QuizController ctrl) async {
    if (_concluindo) return;
    _concluindo = true;
    final resultado = await ctrl.concluir();
    if (!mounted) return;
    context.pushReplacement('/quiz-resultado', extra: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _onWillPop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF12122A),
        body: Consumer<QuizController>(
          builder: (_, ctrl, __) {
            if (ctrl.carregando) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
            }

            // Quando última questão foi respondida, navega para resultado
            if (ctrl.quizConcluido) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _irParaResultado(ctrl);
              });
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
            }

            final card = ctrl.questaoAtual!;
            final tempoEsgotado = ctrl.estado == EstadoQuestao.tempoEsgotado;
            final selecionada = ctrl.estado == EstadoQuestao.selecionada;

            // Cor da barra de timer: roxo → vermelho quando < 30%
            final corTimer = ctrl.percentualTempo < 0.30
                ? const Color(0xFFFF3D00)
                : const Color(0xFF7C4DFF);

            return FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header azul
                    Container(
                      color: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.nomeTema} · ${widget.nomeFase}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Questão ${ctrl.indiceAtual + 1} / ${ctrl.totalQuestoes}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Barra de timer + número
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ctrl.percentualTempo,
                                backgroundColor: const Color(0xFF1A1A3A),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(corTimer),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${ctrl.segundosRestantes}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: corTimer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card da pergunta
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.pergunta,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white, height: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Timer esgotado: mensagem
                    if (tempoEsgotado)
                      GestureDetector(
                        onTap: ctrl.avancarAposTempoEsgotado,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF5252)),
                          ),
                          child: const Text(
                            'Tempo esgotado — toque para continuar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                      ),

                    // Alternativas
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: ctrl.alternativasAtual.length,
                        itemBuilder: (_, i) {
                          final letras = ['A', 'B', 'C', 'D'];
                          final selecionadaEsta =
                              ctrl.respostaSelecionada == i;
                          final desabilitada = tempoEsgotado || selecionada;

                          return GestureDetector(
                            onTap: desabilitada
                                ? null
                                : () => ctrl.selecionarResposta(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: selecionadaEsta
                                    ? const Color(0xFF7C4DFF).withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selecionadaEsta
                                      ? const Color(0xFF7C4DFF)
                                      : const Color(0xFF2A2A5A),
                                  width: selecionadaEsta ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    letras[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selecionadaEsta
                                          ? const Color(0xFF7C4DFF)
                                          : const Color(0xFF90CAF9),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      ctrl.alternativasAtual[i],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: selecionadaEsta
                                            ? Colors.white
                                            : const Color(0xFFCCCCCC),
                                        fontWeight: selecionadaEsta
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/screens/quiz/quiz_screen.dart
```
Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/quiz/quiz_screen.dart
git commit -m "feat(quiz): QuizScreen com timer, alternativas e abandon dialog"
```

---

## Task 5: QuizResultScreen

**Files:**
- Create: `lib/screens/quiz/quiz_result_screen.dart`

- [ ] **Step 1: Criar QuizResultScreen**

```dart
// lib/screens/quiz/quiz_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/quiz_controller.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResultado resultado;

  const QuizResultScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final aprovado = resultado.aprovado;
    final corNota = aprovado ? Colors.white : const Color(0xFFFF5252);
    final estrelas = resultado.estrelas;

    return Scaffold(
      backgroundColor: const Color(0xFF12122A),
      body: SafeArea(
        child: Column(
          children: [
            // Corpo centralizado com score
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Estrelas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Text(
                        i < estrelas ? '⭐' : '☆',
                        style: TextStyle(
                          fontSize: 32,
                          color: i < estrelas
                              ? const Color(0xFFF6C90E)
                              : const Color(0xFF2A2A5A),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Nota
                  Text(
                    '${resultado.nota}',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: corNota,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'pontos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF90CAF9),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divisor
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A5A),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status
                  Text(
                    aprovado
                        ? 'Próxima fase desbloqueada!'
                        : 'Mínimo 70 para avançar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: aprovado
                          ? const Color(0xFF00897B)
                          : const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
            ),

            // Botões
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: aprovado
                          ? () => context.pop() // Continuar → volta para TrilhaScreen
                          : () => context.pushReplacement( // Tentar novamente → novo quiz
                                '/quiz/${resultado.faseId}'
                                '?nomeFase=${Uri.encodeComponent(resultado.nomeFase)}'
                                '&nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                              ),
                      child: Text(
                        aprovado ? 'Continuar →' : 'Tentar novamente',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A2A5A)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: aprovado
                          ? () => context.pushReplacement( // Refazer quiz → novo quiz
                                '/quiz/${resultado.faseId}'
                                '?nomeFase=${Uri.encodeComponent(resultado.nomeFase)}'
                                '&nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                              )
                          : () => context.pop(), // Voltar para trilha
                      child: Text(
                        aprovado ? 'Refazer quiz' : 'Voltar para trilha',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF90CAF9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/screens/quiz/quiz_result_screen.dart
```
Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/quiz/quiz_result_screen.dart
git commit -m "feat(quiz): QuizResultScreen com score centralizado"
```

---

## Task 6: Rotas + BottomSheetQuiz + Provider

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/screens/trilha/widgets/bottom_sheet_quiz.dart`

- [ ] **Step 1: Adicionar rotas e provider em app.dart**

Substituir o conteúdo de `lib/app.dart`:

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'controllers/flashcard_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/secoes_controller.dart';
import 'controllers/trilha_controller.dart';
import 'screens/flashcard/flashcard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/quiz/quiz_result_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/secoes/secoes_screen.dart';
import 'screens/trilha/trilha_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tema/:temaId/secoes',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nome'] ?? '';
        return SecoesScreen(temaId: temaId, nomeTema: nomeTema);
      },
    ),
    GoRoute(
      path: '/tema/:temaId/secao/:secaoId/trilha',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final secaoId = int.parse(state.pathParameters['secaoId']!);
        final nomeSecao = state.uri.queryParameters['nomeSecao'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return TrilhaScreen(
          temaId: temaId,
          secaoId: secaoId,
          nomeSecao: nomeSecao,
          nomeTema: nomeTema,
        );
      },
    ),
    GoRoute(
      path: '/flashcard/:faseId',
      builder: (_, state) {
        final faseId = int.parse(state.pathParameters['faseId']!);
        final nomeFase = state.uri.queryParameters['nomeFase'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return FlashcardScreen(
          faseId: faseId,
          nomeFase: nomeFase,
          nomeTema: nomeTema,
        );
      },
    ),
    GoRoute(
      path: '/quiz/:faseId',
      builder: (_, state) {
        final faseId = int.parse(state.pathParameters['faseId']!);
        final nomeFase = state.uri.queryParameters['nomeFase'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => QuizController(),
          child: QuizScreen(
            faseId: faseId,
            nomeFase: nomeFase,
            nomeTema: nomeTema,
          ),
        );
      },
    ),
    GoRoute(
      path: '/quiz-resultado',
      builder: (_, state) {
        final resultado = state.extra as QuizResultado;
        return QuizResultScreen(resultado: resultado);
      },
    ),
  ],
);

class FlashQuizApp extends StatelessWidget {
  const FlashQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => SecoesController()),
        ChangeNotifierProvider(create: (_) => TrilhaController()),
        ChangeNotifierProvider(create: (_) => FlashcardController()),
      ],
      child: MaterialApp.router(
        title: 'FlashQuiz',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C4DFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
```

- [ ] **Step 2: Adicionar `nomeTema` ao BottomSheetQuiz e conectar botão**

Em `lib/screens/trilha/widgets/bottom_sheet_quiz.dart`, adicionar campo `nomeTema` e wiring do botão:

```dart
// Substituir declaração da classe:
class BottomSheetQuiz extends StatelessWidget {
  final ItemTrilha item;
  final String nomeTema; // ADICIONAR
  const BottomSheetQuiz({super.key, required this.item, required this.nomeTema}); // ATUALIZAR

// Substituir o onPressed do botão "Iniciar Quiz":
onPressed: () {
  Navigator.pop(context);
  context.push(
    '/quiz/${item.fase.id}'
    '?nomeFase=${Uri.encodeComponent(item.fase.nome)}'
    '&nomeTema=${Uri.encodeComponent(nomeTema)}',
  );
},
```

Adicionar import no topo do arquivo:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 2b: Passar `nomeTema` ao abrir o BottomSheetQuiz em TrilhaScreen**

Em `lib/screens/trilha/trilha_screen.dart`, atualizar `_abrirBottomSheetQuiz`:

```dart
// Substituir:
void _abrirBottomSheetQuiz(BuildContext context, ItemTrilha item) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => BottomSheetQuiz(item: item),
  );
}

// Por:
void _abrirBottomSheetQuiz(BuildContext context, ItemTrilha item) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => BottomSheetQuiz(item: item, nomeTema: widget.nomeTema),
  );
}
```

- [ ] **Step 3: Verificar que compila**

```
flutter analyze lib/
```
Esperado: sem erros.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/screens/trilha/widgets/bottom_sheet_quiz.dart lib/screens/trilha/trilha_screen.dart
git commit -m "feat(quiz): rota /quiz/:faseId e wiring do BottomSheetQuiz"
```

---

## Task 7: TrilhaController — Carregar melhorTentativa do Banco

**Files:**
- Modify: `lib/controllers/trilha_controller.dart`

- [ ] **Step 1: Adicionar QuizRepository ao TrilhaController**

Substituir o conteúdo de `lib/controllers/trilha_controller.dart`:

```dart
// lib/controllers/trilha_controller.dart
import 'package:flutter/foundation.dart';
import '../models/fase.dart';
import '../models/quiz_tentativa.dart';
import '../repositories/card_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/fase_repository.dart';
import '../repositories/progresso_repository.dart';
import '../repositories/quiz_repository.dart';

class ItemTrilha {
  final bool ehQuiz;
  final Fase fase;
  final int totalCards;
  final int cardsVistos;
  final QuizTentativa? melhorTentativa;
  final bool desbloqueado;

  ItemTrilha({
    required this.ehQuiz,
    required this.fase,
    this.totalCards = 0,
    this.cardsVistos = 0,
    this.melhorTentativa,
    this.desbloqueado = false,
  });

  bool get concluido => ehQuiz
      ? (melhorTentativa?.concluido ?? false) &&
          (melhorTentativa?.pontuacao ?? 0) >= 70
      : cardsVistos >= totalCards && totalCards > 0;

  bool get emAndamento => !concluido && desbloqueado;

  double get percentualVisto =>
      totalCards > 0 ? cardsVistos / totalCards : 0.0;
}

class TrilhaController extends ChangeNotifier {
  final FaseRepository _faseRepo;
  final CardRepository _cardRepo;
  final ProgressoRepository _progressoRepo;
  final ConfigRepository _configRepo;
  final QuizRepository _quizRepo;

  List<ItemTrilha> itens = [];
  bool carregando = false;

  TrilhaController({
    FaseRepository? faseRepo,
    CardRepository? cardRepo,
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
    QuizRepository? quizRepo,
  })  : _faseRepo = faseRepo ?? FaseRepository(),
        _cardRepo = cardRepo ?? CardRepository(),
        _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _quizRepo = quizRepo ?? QuizRepository();

  Future<void> carregar(int secaoId) async {
    carregando = true;
    notifyListeners();

    final fases = await _faseRepo.getFasesPorSecao(secaoId);
    final minPercentual = await _configRepo.getValorInt(
        'flashcard_min_percentual_para_quiz',
        padrao: 60);

    final novosItens = <ItemTrilha>[];

    for (int i = 0; i < fases.length; i++) {
      final fase = fases[i];
      final total = await _cardRepo.contarCardsPorFase(fase.id);
      final vistos = await _progressoRepo.getCardsVistosCount(fase.id);
      final melhor = await _quizRepo.melhorTentativa(fase.id);

      final desbloqueadaFlashcard =
          i == 0 || (novosItens.isNotEmpty && novosItens.last.concluido);

      final itemFlashcard = ItemTrilha(
        ehQuiz: false,
        fase: fase,
        totalCards: total,
        cardsVistos: vistos,
        desbloqueado: desbloqueadaFlashcard,
      );
      novosItens.add(itemFlashcard);

      final percentualAtingido =
          total > 0 && (vistos / total) >= (minPercentual / 100.0);
      novosItens.add(ItemTrilha(
        ehQuiz: true,
        fase: fase,
        totalCards: total,
        cardsVistos: vistos,
        melhorTentativa: melhor,
        desbloqueado: desbloqueadaFlashcard && percentualAtingido,
      ));
    }

    itens = novosItens;
    carregando = false;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/controllers/trilha_controller.dart
```
Esperado: sem erros.

- [ ] **Step 3: Rodar todos os testes**

```
flutter test
```
Esperado: todos PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/controllers/trilha_controller.dart
git commit -m "feat(quiz): TrilhaController carrega melhorTentativa do banco"
```

---

## Task 8: Smoke Test Manual

- [ ] **Step 1: Rodar no device/emulador**

```
flutter run
```

- [ ] **Step 2: Verificar fluxo completo**

1. Home → selecionar tema → selecionar seção → trilha
2. Tocar nó de quiz desbloqueado → bottom sheet abre → "Iniciar Quiz" navega para QuizScreen
3. Quiz carrega questões com timer rodando
4. Selecionar resposta → highlight roxo → auto-avança
5. Deixar timer esgotar numa questão → "Tempo esgotado" → toque para avançar
6. Apertar voltar → diálogo aparece → cancelar funciona / confirmar abandona
7. Completar todas as questões → QuizResultScreen aparece com nota e estrelas
8. "Continuar" volta para Home; "Refazer quiz" volta para quiz
9. Voltar para trilha → nó de quiz mostra concluído se nota ≥ 70

- [ ] **Step 3: Commit final**

```bash
git add .
git commit -m "feat(quiz): Plano 3 completo — QuizEngine funcional"
```
