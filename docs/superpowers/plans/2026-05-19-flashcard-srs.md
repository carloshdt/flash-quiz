# Plano 2 — FlashcardScreen + SRS Engine

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar tela de flashcards com engine SRS de 3 níveis (Difícil/Médio/Fácil), persistência de progresso no SQLite e desbloqueio real do nó de quiz na TrilhaScreen.

**Architecture:** ProgressoRepository lê/escreve `progresso_flashcard`; FlashcardController gerencia sessão e fila de cards; FlashcardScreen usa StatefulWidget com AnimationController para flip 3D. TrilhaController passa a ler cardsVistos real do banco. Quiz só desbloqueia quando cardsVistos/total >= 60% (config).

**Tech Stack:** Flutter 3.x, sqflite, provider ^6.1.1, go_router ^13.0.0. Sem dependência nova.

---

## Arquivos modificados / criados

| Ação | Arquivo |
|------|---------|
| Criar | `lib/repositories/progresso_repository.dart` |
| Criar | `lib/controllers/flashcard_controller.dart` |
| Criar | `lib/screens/flashcard/flashcard_screen.dart` |
| Modificar | `lib/services/metrica_service.dart` |
| Modificar | `lib/app.dart` |
| Modificar | `lib/controllers/trilha_controller.dart` |
| Modificar | `lib/screens/trilha/widgets/bottom_sheet_fase.dart` |

---

## Task 1: ProgressoRepository

**Files:**
- Create: `lib/repositories/progresso_repository.dart`

- [ ] **Step 1: Criar progresso_repository.dart**

```dart
// lib/repositories/progresso_repository.dart
import '../db/database_helper.dart';
import '../models/card_model.dart';

class ProgressoRepository {
  final DatabaseHelper _db;
  ProgressoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  // Cards da fase que devem aparecer na sessão:
  // 1. Cards vencidos (proxima_revisao <= hoje) — primeiro
  // 2. Cards novos (nunca vistos) — depois
  // Limite = flashcard_cards_por_sessao (padrão 20)
  Future<List<CardModel>> getCardsParaSessao(int faseId, int limite) async {
    final banco = await _db.banco;
    final hoje = DateTime.now().toIso8601String().split('T').first;

    final rows = await banco.rawQuery('''
      SELECT c.*
      FROM cards c
      LEFT JOIN progresso_flashcard pf ON pf.card_id = c.id
      WHERE c.fase_id = ?
        AND (
          pf.id IS NULL
          OR pf.total_visto = 0
          OR pf.proxima_revisao <= ?
        )
      ORDER BY
        CASE WHEN pf.total_visto > 0 THEN 0 ELSE 1 END ASC,
        pf.proxima_revisao ASC
      LIMIT ?
    ''', [faseId, hoje, limite]);

    return rows.map(CardModel.fromMap).toList();
  }

  // Conta quantos cards da fase já foram vistos pelo menos uma vez
  Future<int> getCardsVistosCount(int faseId) async {
    final banco = await _db.banco;
    final result = await banco.rawQuery('''
      SELECT COUNT(DISTINCT pf.card_id) AS vistos
      FROM progresso_flashcard pf
      JOIN cards c ON c.id = pf.card_id
      WHERE c.fase_id = ? AND pf.total_visto > 0
    ''', [faseId]);
    return (result.first['vistos'] as int?) ?? 0;
  }

  // Cria ou atualiza o progresso de um card após avaliação SRS
  // nivelSrs: 0=Difícil (revisão hoje), 1=Médio (+1 dia), 2=Fácil (+3 dias)
  Future<void> salvarProgresso(int cardId, int nivelSrs) async {
    final banco = await _db.banco;
    final agora = DateTime.now();
    final intervaloDias = const {0: 0, 1: 1, 2: 3};
    final proxima = agora.add(Duration(days: intervaloDias[nivelSrs] ?? 0));

    final existing = await banco.query(
      'progresso_flashcard',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    if (existing.isEmpty) {
      await banco.insert('progresso_flashcard', {
        'card_id': cardId,
        'nivel_srs': nivelSrs,
        'total_visto': 1,
        'total_acerto': nivelSrs > 0 ? 1 : 0,
        'proxima_revisao': proxima.toIso8601String(),
        'atualizado_em': agora.toIso8601String(),
      });
    } else {
      final old = existing.first;
      await banco.update(
        'progresso_flashcard',
        {
          'nivel_srs': nivelSrs,
          'total_visto': (old['total_visto'] as int) + 1,
          'total_acerto': (old['total_acerto'] as int) + (nivelSrs > 0 ? 1 : 0),
          'proxima_revisao': proxima.toIso8601String(),
          'atualizado_em': agora.toIso8601String(),
        },
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
    }
  }
}
```

- [ ] **Step 2: Verificar que `CardModel.fromMap` existe em card_model.dart**

Abrir `lib/models/card_model.dart` e confirmar que `factory CardModel.fromMap(Map<String, dynamic> m)` está definido. Se não estiver, adicionar:

```dart
factory CardModel.fromMap(Map<String, dynamic> m) => CardModel(
  id: m['id'] as int,
  faseId: m['fase_id'] as int,
  pergunta: m['pergunta'] as String,
  resposta: m['resposta'] as String,
  alternativaB: m['alternativa_b'] as String,
  alternativaC: m['alternativa_c'] as String,
  alternativaD: m['alternativa_d'] as String,
);
```

- [ ] **Step 3: Rodar `flutter analyze` para checar erros de compilação**

```bash
cd flashquiz && flutter analyze lib/repositories/progresso_repository.dart
```

Esperado: sem erros.

---

## Task 2: FlashcardController

**Files:**
- Create: `lib/controllers/flashcard_controller.dart`

- [ ] **Step 1: Criar flashcard_controller.dart**

```dart
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
```

- [ ] **Step 2: Rodar `flutter analyze`**

```bash
cd flashquiz && flutter analyze lib/controllers/flashcard_controller.dart
```

Esperado: sem erros.

---

## Task 3: MetricaService — adicionar cardVisto e cardAvaliado

**Files:**
- Modify: `lib/services/metrica_service.dart`

- [ ] **Step 1: Adicionar os 2 métodos ao final da classe MetricaService**

Abrir `lib/services/metrica_service.dart` e adicionar antes do `}` final da classe:

```dart
  Future<void> cardVisto(int cardId, int faseId, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'card_visto',
        tema: nomeTema,
        metadata: {'card_id': cardId, 'fase_id': faseId},
      ));

  Future<void> cardAvaliado(int cardId, int nivelSrs, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'card_avaliado',
        tema: nomeTema,
        valor: nivelSrs == 0
            ? 'dificil'
            : nivelSrs == 1
                ? 'medio'
                : 'facil',
        metadata: {'card_id': cardId, 'nivel_srs': nivelSrs},
      ));
```

- [ ] **Step 2: Rodar `flutter analyze`**

```bash
cd flashquiz && flutter analyze lib/services/metrica_service.dart
```

Esperado: sem erros.

---

## Task 4: FlashcardScreen

**Files:**
- Create: `lib/screens/flashcard/flashcard_screen.dart`

- [ ] **Step 1: Criar a pasta `lib/screens/flashcard/`**

```bash
mkdir -p flashquiz/lib/screens/flashcard
```

- [ ] **Step 2: Criar flashcard_screen.dart**

```dart
// lib/screens/flashcard/flashcard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/flashcard_controller.dart';

class FlashcardScreen extends StatefulWidget {
  final int faseId;
  final String nomeFase;
  final String nomeTema;

  const FlashcardScreen({
    super.key,
    required this.faseId,
    required this.nomeFase,
    required this.nomeTema,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _mostrandoFrente = true;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardController>().carregarSessao(
            widget.faseId,
            widget.nomeFase,
            widget.nomeTema,
          );
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _virar() {
    if (!_mostrandoFrente) return;
    _flipCtrl.forward();
    setState(() => _mostrandoFrente = false);
    context.read<FlashcardController>().virar();
  }

  Future<void> _avaliar(int nivelSrs) async {
    await context.read<FlashcardController>().avaliar(nivelSrs);
    _flipCtrl.reset();
    setState(() => _mostrandoFrente = true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FlashcardController>();

    return Scaffold(
      backgroundColor: const Color(0xFF12122A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nomeFase,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(widget.nomeTema,
                style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
          ],
        ),
      ),
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : ctrl.sessaoConcluida
              ? _buildSessaoConcluida(context, ctrl)
              : _buildSessao(context, ctrl),
    );
  }

  Widget _buildSessao(BuildContext context, FlashcardController ctrl) {
    final card = ctrl.cardAtual!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
            // Card com flip
            GestureDetector(
              onTap: ctrl.virado ? null : _virar,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  final angulo = _flipAnim.value;
                  final mostrarFrente = angulo < pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angulo),
                    child: mostrarFrente
                        ? _CardFace(
                            texto: card.pergunta,
                            label: 'PERGUNTA',
                            cor: const Color(0xFF1E1E3A),
                            corBorda: const Color(0xFF3A3A5A),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: _CardFace(
                              texto: card.resposta,
                              label: 'RESPOSTA',
                              cor: const Color(0xFF1A2A1A),
                              corBorda: const Color(0xFF2A5A2A),
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Instrução para tocar no card
            AnimatedOpacity(
              opacity: ctrl.virado ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'Toque no card para ver a resposta',
                style: TextStyle(fontSize: 12, color: Color(0xFF555577)),
              ),
            ),
            const Spacer(),
            // Botões de avaliação SRS
            _buildBotoesAvaliacao(ctrl),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAvaliacao(FlashcardController ctrl) {
    return AnimatedOpacity(
      opacity: ctrl.virado ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !ctrl.virado,
        child: Row(
          children: [
            _BotaoAvaliacao(
              emoji: '😓',
              label: 'Difícil',
              cor: const Color(0xFFB71C1C),
              corBorda: const Color(0xFFEF9A9A),
              onTap: () => _avaliar(0),
            ),
            const SizedBox(width: 10),
            _BotaoAvaliacao(
              emoji: '🤔',
              label: 'Médio',
              cor: const Color(0xFFE65100),
              corBorda: const Color(0xFFFFCC80),
              onTap: () => _avaliar(1),
            ),
            const SizedBox(width: 10),
            _BotaoAvaliacao(
              emoji: '😊',
              label: 'Fácil',
              cor: const Color(0xFF1B5E20),
              corBorda: const Color(0xFFA5D6A7),
              onTap: () => _avaliar(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessaoConcluida(BuildContext context, FlashcardController ctrl) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Sessão concluída!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctrl.totalSessao} cards revisados',
                style: const TextStyle(fontSize: 14, color: Color(0xFF90CAF9)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar à trilha',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String texto;
  final String label;
  final Color cor;
  final Color corBorda;

  const _CardFace({
    required this.texto,
    required this.label,
    required this.cor,
    required this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Text(
            texto,
            style: const TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BotaoAvaliacao extends StatelessWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corBorda;
  final VoidCallback onTap;

  const _BotaoAvaliacao({
    required this.emoji,
    required this.label,
    required this.cor,
    required this.corBorda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: corBorda, width: 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Rodar `flutter analyze`**

```bash
cd flashquiz && flutter analyze lib/screens/flashcard/flashcard_screen.dart
```

Esperado: sem erros.

---

## Task 5: Wiring — app.dart + bottom_sheet_fase + TrilhaController

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/screens/trilha/widgets/bottom_sheet_fase.dart`
- Modify: `lib/controllers/trilha_controller.dart`

### 5a — app.dart: adicionar rota e provider

- [ ] **Step 1: Adicionar import de FlashcardController e FlashcardScreen em app.dart**

No topo de `lib/app.dart`, adicionar:
```dart
import 'controllers/flashcard_controller.dart';
import 'screens/flashcard/flashcard_screen.dart';
```

- [ ] **Step 2: Adicionar rota `/flashcard/:faseId` no `_router`**

Dentro de `routes: [...]` em `_router`, após a rota de trilha, adicionar:

```dart
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
```

- [ ] **Step 3: Adicionar FlashcardController no MultiProvider de FlashQuizApp**

No `MultiProvider`, após `ChangeNotifierProvider(create: (_) => TrilhaController()),`, adicionar:

```dart
        ChangeNotifierProvider(create: (_) => FlashcardController()),
```

- [ ] **Step 4: Rodar `flutter analyze lib/app.dart`**

```bash
cd flashquiz && flutter analyze lib/app.dart
```

Esperado: sem erros.

---

### 5b — bottom_sheet_fase.dart: navegar para FlashcardScreen

O bottom sheet não tem acesso ao GoRouter diretamente pois é construído em contexto separado. A solução é receber um callback `onIniciar` do TrilhaScreen que tem o contexto correto.

- [ ] **Step 5: Atualizar BottomSheetFase para aceitar callback onIniciar**

Substituir o conteúdo de `lib/screens/trilha/widgets/bottom_sheet_fase.dart`:

```dart
// lib/screens/trilha/widgets/bottom_sheet_fase.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class BottomSheetFase extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onIniciar;

  const BottomSheetFase({
    super.key,
    required this.item,
    required this.onIniciar,
  });

  @override
  Widget build(BuildContext context) {
    final percentual = (item.percentualVisto * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.fase.nome,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$percentual% dos cards vistos',
                style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9)),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.percentualVisto.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1A237E),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onIniciar();
              },
              child: Text(
                item.cardsVistos > 0
                    ? '▶ Continuar Flashcards'
                    : '▶ Iniciar Flashcards',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Atualizar TrilhaScreen para passar onIniciar ao BottomSheetFase**

Em `lib/screens/trilha/trilha_screen.dart`, localizar o método `_abrirBottomSheetFase` e substituí-lo:

```dart
  void _abrirBottomSheetFase(BuildContext context, ItemTrilha item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetFase(
        item: item,
        onIniciar: () {
          context.push(
            '/flashcard/${item.fase.id}'
            '?nomeFase=${Uri.encodeComponent(item.fase.nome)}'
            '&nomeTema=${Uri.encodeComponent(widget.nomeTema)}',
          );
        },
      ),
    );
  }
```

Adicionar import de go_router no topo se ainda não tiver:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 7: Rodar `flutter analyze lib/screens/trilha/`**

```bash
cd flashquiz && flutter analyze lib/screens/trilha/
```

Esperado: sem erros.

---

### 5c — TrilhaController: ler cardsVistos real + desbloquear quiz com percentual

- [ ] **Step 8: Atualizar TrilhaController para usar ProgressoRepository**

Substituir o conteúdo de `lib/controllers/trilha_controller.dart`:

```dart
// lib/controllers/trilha_controller.dart
import 'package:flutter/foundation.dart';
import '../models/fase.dart';
import '../models/quiz_tentativa.dart';
import '../repositories/fase_repository.dart';
import '../repositories/card_repository.dart';
import '../repositories/progresso_repository.dart';
import '../repositories/config_repository.dart';

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

  // Fase concluída = todos os cards vistos
  // Quiz concluído = tentativa com pontuação >= 70
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

  List<ItemTrilha> itens = [];
  bool carregando = false;

  TrilhaController({
    FaseRepository? faseRepo,
    CardRepository? cardRepo,
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
  })  : _faseRepo = faseRepo ?? FaseRepository(),
        _cardRepo = cardRepo ?? CardRepository(),
        _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository();

  Future<void> carregar(int secaoId) async {
    carregando = true;
    notifyListeners();

    final fases = await _faseRepo.getFasesPorSecao(secaoId);
    // Percentual mínimo para desbloquear o quiz da fase
    final minPercentual =
        await _configRepo.getValorInt('flashcard_min_percentual_para_quiz', padrao: 60);

    final novosItens = <ItemTrilha>[];

    for (int i = 0; i < fases.length; i++) {
      final fase = fases[i];
      final total = await _cardRepo.contarCardsPorFase(fase.id);
      final vistos = await _progressoRepo.getCardsVistosCount(fase.id);

      // Primeira fase sempre desbloqueada; seguintes dependem do quiz anterior
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

      // Quiz desbloqueia quando percentual de cards vistos >= minPercentual%
      final percentualAtingido =
          total > 0 && (vistos / total) >= (minPercentual / 100.0);
      novosItens.add(ItemTrilha(
        ehQuiz: true,
        fase: fase,
        totalCards: total,
        cardsVistos: vistos,
        desbloqueado: desbloqueadaFlashcard && percentualAtingido,
      ));
    }

    itens = novosItens;
    carregando = false;
    notifyListeners();
  }
}
```

- [ ] **Step 9: Rodar `flutter analyze lib/controllers/trilha_controller.dart`**

```bash
cd flashquiz && flutter analyze lib/controllers/trilha_controller.dart
```

Esperado: sem erros.

---

## Task 6: Teste End-to-End

- [ ] **Step 1: Compilar e rodar no device**

```bash
cd flashquiz && flutter run
```

Esperado: sem erros de compilação.

- [ ] **Step 2: Fluxo feliz — iniciar flashcards**

1. Abrir app → tela Home com CFC
2. Tocar em CFC → Seções
3. Tocar em Geral → Trilha (nó de fase desbloqueado, quiz bloqueado)
4. Tocar no nó da Fase 1 → BottomSheet aparece com "0% dos cards vistos"
5. Tocar "▶ Iniciar Flashcards" → FlashcardScreen abre
6. Card aparece mostrando pergunta, botões de avaliação invisíveis
7. Tocar no card → flip animado, resposta aparece, botões visíveis
8. Tocar "😓 Difícil" → próximo card aparece, flip reset, botões invisíveis
9. Repetir até fim da sessão → tela "Sessão concluída!" com total de cards
10. Tocar "Voltar à trilha" → volta pra Trilha
11. Nó da fase agora mostra progresso real (cards_vistos > 0)

- [ ] **Step 3: Verificar desbloqueio de quiz**

1. Após ver 3+ dos 5 cards de uma fase (>= 60%), voltar à trilha
2. O nó de quiz dessa fase deve aparecer desbloqueado (cor teal, não bloqueado)
3. Tocar no quiz → BottomSheet de quiz aparece (ainda sem iniciar, Plano 3)

- [ ] **Step 4: Verificar métricas no banco**

Conectar ao device e checar:

```bash
adb shell "run-as com.flashquiz.flashquiz sqlite3 /data/data/com.flashquiz.flashquiz/databases/flashquiz.db 'SELECT evento, valor, metadata FROM eventos ORDER BY id DESC LIMIT 20;'"
```

Esperado: linhas com `card_visto`, `card_avaliado` com `valor` = dificil/medio/facil.

---

## Resumo das Mudanças

| Arquivo | O que mudou |
|---------|------------|
| `lib/repositories/progresso_repository.dart` | Novo: lê cards para sessão, conta vistos, salva progresso SRS |
| `lib/controllers/flashcard_controller.dart` | Novo: gerencia sessão, virar card, avaliar com SRS |
| `lib/screens/flashcard/flashcard_screen.dart` | Novo: UI com flip 3D, botões SRS, tela de conclusão |
| `lib/services/metrica_service.dart` | Adicionou cardVisto() e cardAvaliado() |
| `lib/app.dart` | Adicionou rota `/flashcard/:faseId` e FlashcardController no Provider |
| `lib/screens/trilha/widgets/bottom_sheet_fase.dart` | Recebe callback onIniciar em vez de navegar diretamente |
| `lib/screens/trilha/trilha_screen.dart` | Passa onIniciar ao BottomSheetFase com context.push |
| `lib/controllers/trilha_controller.dart` | Lê cardsVistos real do banco, desbloqueia quiz com percentual |

---

## Próximos Planos

**Plano 3:** QuizScreen (timer, sem feedback durante) + QuizResultScreen (breakdown por questão)
**Plano 4:** PerfilScreen + XP/level/streak system + conquistas
**Plano 5:** Conteúdo real CFC (cards e alternativas reais)
**Plano 6:** AdMob + Firebase Cloud Messaging + estrutura de paywall
