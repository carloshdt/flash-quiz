# Modos de Estudo (Plano 3.5) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar três modos de estudo por tema — Desafio Diário, Revisão Inteligente e Maratona — reaproveitando os motores de quiz e flashcard existentes, sem tocar na progressão de fases.

**Architecture:** Tabela nova `modo_tentativas` (migration_v4) isola os modos da progressão (`quiz_tentativas` fica intocada). `ModoRepository` concentra tentativas + queries de pool. Controllers novos e finos (`DesafioController`, `MaratonaController`, `RevisaoController`) reusam widgets extraídos de `QuizScreen`/`FlashcardScreen`. Entrada: bloco "Modos de estudo" na `SecoesScreen`.

**Tech Stack:** Flutter 3.x · sqflite · provider (ChangeNotifier) · go_router · sqflite_common_ffi (testes)

**Spec:** `docs/superpowers/specs/2026-07-01-modos-de-estudo-design.md`

**Convenções do projeto (CLAUDE.md):** comentários em português · SQL só em repositories · valores numéricos na tabela `config` · tudo metrificado em `eventos` · cores via `AppColors` (`lib/theme/app_theme.dart`).

**Comandos:** rodar da pasta `flashquiz/`. Testes: `flutter test` · análise: `flutter analyze`.

---

## Estrutura de arquivos

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `lib/db/migrations/migration_v4.dart` | Criar | Tabela `modo_tentativas` + config seeds |
| `lib/db/database_helper.dart` | Modificar | Registrar v4 |
| `lib/repositories/modo_repository.dart` | Criar | Tentativas dos modos + pool desbloqueado + cards vencidos |
| `lib/services/metrica_service.dart` | Modificar | 8 eventos novos |
| `lib/services/quiz_pontuacao.dart` | Criar | Helper 10/7/0 e nota 0–100 |
| `lib/screens/quiz/widgets/quiz_timer_bar.dart` | Criar | Barra de timer compartilhada |
| `lib/screens/quiz/widgets/quiz_questao_card.dart` | Criar | Card da pergunta compartilhado |
| `lib/screens/quiz/widgets/quiz_alternativas.dart` | Criar | Lista de alternativas compartilhada |
| `lib/screens/quiz/widgets/tempo_esgotado_banner.dart` | Criar | Banner "tempo esgotado" compartilhado |
| `lib/screens/quiz/quiz_screen.dart` | Modificar | Usar widgets extraídos (refactor puro de UI) |
| `lib/screens/flashcard/widgets/card_face.dart` | Criar | Face do flashcard (extraída) |
| `lib/screens/flashcard/widgets/botao_avaliacao.dart` | Criar | Botão Difícil/Médio/Fácil (extraído) |
| `lib/screens/flashcard/flashcard_screen.dart` | Modificar | Usar widgets extraídos |
| `lib/controllers/desafio_controller.dart` | Criar | Fluxo do Desafio Diário |
| `lib/screens/desafio/desafio_screen.dart` | Criar | Tela do desafio |
| `lib/screens/desafio/desafio_result_screen.dart` | Criar | Resultado do desafio |
| `lib/controllers/maratona_controller.dart` | Criar | Fluxo da Maratona |
| `lib/screens/maratona/maratona_screen.dart` | Criar | Tela da maratona |
| `lib/screens/maratona/maratona_result_screen.dart` | Criar | Resultado da maratona |
| `lib/controllers/revisao_controller.dart` | Criar | Fluxo da Revisão Inteligente |
| `lib/screens/revisao/revisao_screen.dart` | Criar | Tela da revisão |
| `lib/controllers/secoes_controller.dart` | Modificar | Carregar dados dos modos |
| `lib/screens/secoes/secoes_screen.dart` | Modificar | Bloco "Modos de estudo" |
| `lib/app.dart` | Modificar | Rotas novas |
| `test/db/migration_v4_test.dart` | Criar | Testes da migration |
| `test/repositories/modo_repository_test.dart` | Criar | Testes do repository |
| `test/services/quiz_pontuacao_test.dart` | Criar | Testes do helper |
| `test/controllers/maratona_controller_test.dart` | Criar | Testes de vidas/sorteio |

Decisões travadas:
- Nota mínima 70 continua literal (padrão existente em `TrilhaController` e `QuizResultScreen`).
- Sem model para `modo_tentativas` — queries retornam escalares (`int`/`int?`); YAGNI.
- Gate diário do desafio é feito na UI (`SecoesScreen` desabilita o card). Rota só é alcançável pela UI.
- Cards vencidos já implicam fase desbloqueada (só se vê card de fase desbloqueada), então `cardsVencidos` não filtra por desbloqueio.
- `criado_em` grava UTC (`CURRENT_TIMESTAMP`); comparações de "hoje" usam `DATE(criado_em, 'localtime')`.

---

### Task 1: Migration v4 — tabela `modo_tentativas` + configs

**Files:**
- Create: `lib/db/migrations/migration_v4.dart`
- Modify: `lib/db/database_helper.dart`
- Test: `test/db/migration_v4_test.dart`

- [ ] **Step 1: Escrever teste que falha**

```dart
// test/db/migration_v4_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';

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

  test('tabela modo_tentativas existe com colunas esperadas', () async {
    final db = await DatabaseHelper().banco;
    final cols = await db.rawQuery('PRAGMA table_info(modo_tentativas)');
    final nomes = cols.map((c) => c['name']).toSet();
    expect(nomes.containsAll(['id', 'modo', 'tema_id', 'pontuacao', 'tempo_total_segundos', 'concluido', 'criado_em', 'atualizado_em']), isTrue);
  });

  test('configs dos modos seedadas', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('config',
        where: "chave IN ('desafio_num_questoes', 'revisao_max_cards', 'maratona_max_erros')");
    expect(rows.length, 3);
    final mapa = {for (final r in rows) r['chave']: r['valor']};
    expect(mapa['desafio_num_questoes'], '5');
    expect(mapa['revisao_max_cards'], '20');
    expect(mapa['maratona_max_erros'], '3');
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/db/migration_v4_test.dart`
Expected: FAIL (tabela não existe / configs ausentes)

- [ ] **Step 3: Criar migration**

```dart
// lib/db/migrations/migration_v4.dart
// Tabela modo_tentativas (Desafio Diário e Maratona) + configs dos modos de estudo

class MigrationV4 {
  static Future<void> executar(dynamic db) async {
    await db.execute('''
      CREATE TABLE modo_tentativas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modo TEXT NOT NULL,
        tema_id INTEGER NOT NULL,
        pontuacao INTEGER NOT NULL DEFAULT 0,
        tempo_total_segundos INTEGER,
        concluido INTEGER DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tema_id) REFERENCES temas(id)
      )
    ''');

    final configs = [
      {'chave': 'desafio_num_questoes', 'valor': '5'},
      {'chave': 'revisao_max_cards', 'valor': '20'},
      {'chave': 'maratona_max_erros', 'valor': '3'},
    ];
    for (final c in configs) {
      await db.insert('config', c);
    }
  }
}
```

- [ ] **Step 4: Registrar v4 no DatabaseHelper**

Em `lib/db/database_helper.dart`:
- Adicionar import: `import 'migrations/migration_v4.dart';`
- Mudar `version: 3` para `version: 4`
- Em `onCreate`, adicionar após `MigrationV3.executar(db);`: `await MigrationV4.executar(db);`
- Em `onUpgrade`, adicionar após a linha do v3: `if (oldVersion < 4) await MigrationV4.executar(db);`

- [ ] **Step 5: Rodar testes e ver passar**

Run: `flutter test test/db/`
Expected: PASS (migration_v4_test + database_helper_test existente)

- [ ] **Step 6: Commit**

```bash
git add lib/db/migrations/migration_v4.dart lib/db/database_helper.dart test/db/migration_v4_test.dart
git commit -m "feat(db): migration v4 com tabela modo_tentativas e configs dos modos"
```

---

### Task 2: ModoRepository — tentativas, gate diário, recorde

**Files:**
- Create: `lib/repositories/modo_repository.dart`
- Test: `test/repositories/modo_repository_test.dart`

- [ ] **Step 1: Escrever testes que falham**

```dart
// test/repositories/modo_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/modo_repository.dart';

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
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    expect(id, greaterThan(0));
  });

  test('concluirTentativa salva pontuacao e marca concluido', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.concluirTentativa(id, pontuacao: 84, tempoTotalSegundos: 90);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('modo_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['pontuacao'], 84);
    expect(rows.first['concluido'], 1);
  });

  test('abandonarTentativa mantém concluido = 0', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('maratona', 1);
    await repo.abandonarTentativa(id);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('modo_tentativas', where: 'id = ?', whereArgs: [id]);
    expect(rows.first['concluido'], 0);
  });

  test('notaDesafioHoje retorna null sem desafio concluído hoje', () async {
    final repo = ModoRepository();
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('notaDesafioHoje retorna nota do desafio concluído hoje', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.concluirTentativa(id, pontuacao: 76, tempoTotalSegundos: 60);
    expect(await repo.notaDesafioHoje(1), 76);
  });

  test('desafio abandonado não conta como feito hoje', () async {
    final repo = ModoRepository();
    final id = await repo.iniciarTentativa('desafio', 1);
    await repo.abandonarTentativa(id);
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('notaDesafioHoje ignora outros temas e maratonas', () async {
    final repo = ModoRepository();
    final m = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(m, pontuacao: 15, tempoTotalSegundos: 200);
    final outroTema = await repo.iniciarTentativa('desafio', 2);
    await repo.concluirTentativa(outroTema, pontuacao: 90, tempoTotalSegundos: 50);
    expect(await repo.notaDesafioHoje(1), isNull);
  });

  test('recordeMaratona retorna 0 sem partidas e MAX com partidas', () async {
    final repo = ModoRepository();
    expect(await repo.recordeMaratona(1), 0);

    final a = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(a, pontuacao: 12, tempoTotalSegundos: 100);
    final b = await repo.iniciarTentativa('maratona', 1);
    await repo.concluirTentativa(b, pontuacao: 20, tempoTotalSegundos: 150);

    expect(await repo.recordeMaratona(1), 20);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/repositories/modo_repository_test.dart`
Expected: FAIL ("modo_repository.dart" não existe)

- [ ] **Step 3: Implementar repository (parte 1 — tentativas)**

```dart
// lib/repositories/modo_repository.dart
import '../db/database_helper.dart';
import '../models/card_model.dart';

class ModoRepository {
  final DatabaseHelper _db;
  ModoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<int> iniciarTentativa(String modo, int temaId) async {
    final banco = await _db.banco;
    return banco.insert('modo_tentativas', {
      'modo': modo,
      'tema_id': temaId,
      'pontuacao': 0,
      'concluido': 0,
    });
  }

  Future<void> concluirTentativa(
    int tentativaId, {
    required int pontuacao,
    required int tempoTotalSegundos,
  }) async {
    final banco = await _db.banco;
    await banco.update(
      'modo_tentativas',
      {
        'pontuacao': pontuacao,
        'tempo_total_segundos': tempoTotalSegundos,
        'concluido': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  Future<void> abandonarTentativa(int tentativaId) async {
    final banco = await _db.banco;
    await banco.update(
      'modo_tentativas',
      {
        'concluido': 0,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tentativaId],
    );
  }

  // Nota do desafio concluído hoje (horário local), ou null se ainda não fez.
  // criado_em é gravado em UTC (CURRENT_TIMESTAMP) — converter com 'localtime'.
  Future<int?> notaDesafioHoje(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT pontuacao FROM modo_tentativas
      WHERE modo = 'desafio' AND tema_id = ? AND concluido = 1
        AND DATE(criado_em, 'localtime') = DATE('now', 'localtime')
      ORDER BY pontuacao DESC
      LIMIT 1
    ''', [temaId]);
    if (rows.isEmpty) return null;
    return rows.first['pontuacao'] as int;
  }

  Future<int> recordeMaratona(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT MAX(pontuacao) AS recorde FROM modo_tentativas
      WHERE modo = 'maratona' AND tema_id = ? AND concluido = 1
    ''', [temaId]);
    return (rows.first['recorde'] as int?) ?? 0;
  }
}
```

(As queries de pool entram na Task 3 — o import de `card_model.dart` já fica pronto.)

- [ ] **Step 4: Rodar testes e ver passar**

Run: `flutter test test/repositories/modo_repository_test.dart`
Expected: PASS (8 testes)

- [ ] **Step 5: Commit**

```bash
git add lib/repositories/modo_repository.dart test/repositories/modo_repository_test.dart
git commit -m "feat(modos): ModoRepository com tentativas, gate diário e recorde"
```

---

### Task 3: ModoRepository — pool desbloqueado e cards vencidos

**Files:**
- Modify: `lib/repositories/modo_repository.dart`
- Modify: `test/repositories/modo_repository_test.dart`

Regra de desbloqueio (mesma do `TrilhaController`): fase desbloqueada = primeira da seção (menor `ordem`) OU fase anterior (maior `ordem` menor que a dela, na mesma seção) tem `quiz_tentativas` com `concluido = 1 AND pontuacao >= 70`.

- [ ] **Step 1: Adicionar testes que falham**

Adicionar ao final do `main()` de `test/repositories/modo_repository_test.dart` (antes do fechamento `}`):

```dart
  // Helper: monta tema isolado com 1 seção e 2 fases (2 cards cada)
  Future<({int temaId, int fase1, int fase2, List<int> cardsF1, List<int> cardsF2})>
      seedTema() async {
    final db = await DatabaseHelper().banco;
    final temaId = await db.insert('temas', {'nome': 'TesteModo', 'icone': '🧪'});
    final secaoId = await db.insert('secoes', {'tema_id': temaId, 'nome': 'S1', 'ordem': 0});
    final fase1 = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F1', 'ordem': 1});
    final fase2 = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F2', 'ordem': 2});
    Future<int> card(int faseId, String p) => db.insert('cards', {
          'fase_id': faseId,
          'pergunta': p,
          'resposta': 'R',
          'alternativa_b': 'B',
          'alternativa_c': 'C',
          'alternativa_d': 'D',
        });
    final cardsF1 = [await card(fase1, 'p1'), await card(fase1, 'p2')];
    final cardsF2 = [await card(fase2, 'p3'), await card(fase2, 'p4')];
    return (temaId: temaId, fase1: fase1, fase2: fase2, cardsF1: cardsF1, cardsF2: cardsF2);
  }

  test('cardsPoolDesbloqueado retorna só cards da primeira fase sem quiz passado', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), seed.cardsF1.toSet());
  });

  test('cardsPoolDesbloqueado inclui fase 2 após quiz da fase 1 passar com >= 70', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    await db.insert('quiz_tentativas',
        {'fase_id': seed.fase1, 'pontuacao': 80, 'estrelas': 2, 'concluido': 1});

    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), {...seed.cardsF1, ...seed.cardsF2});
  });

  test('cardsPoolDesbloqueado ignora quiz reprovado (< 70)', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    await db.insert('quiz_tentativas',
        {'fase_id': seed.fase1, 'pontuacao': 60, 'estrelas': 0, 'concluido': 1});

    final pool = await repo.cardsPoolDesbloqueado(seed.temaId);
    expect(pool.map((c) => c.id).toSet(), seed.cardsF1.toSet());
  });

  test('cardsVencidos retorna só cards com proxima_revisao <= hoje, com limite', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final amanha = DateTime.now().add(const Duration(days: 1)).toIso8601String();

    // card vencido, card futuro, card nunca visto
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[0], 'nivel_srs': 0, 'total_visto': 2,
      'total_acerto': 1, 'proxima_revisao': ontem,
    });
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[1], 'nivel_srs': 2, 'total_visto': 1,
      'total_acerto': 1, 'proxima_revisao': amanha,
    });

    final vencidos = await repo.cardsVencidos(seed.temaId, 20);
    expect(vencidos.map((c) => c.id).toList(), [seed.cardsF1[0]]);

    final limitado = await repo.cardsVencidos(seed.temaId, 0);
    expect(limitado, isEmpty);
  });

  test('contarCardsVencidos conta cards vencidos do tema', () async {
    final repo = ModoRepository();
    final seed = await seedTema();
    final db = await DatabaseHelper().banco;
    final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    await db.insert('progresso_flashcard', {
      'card_id': seed.cardsF1[0], 'nivel_srs': 0, 'total_visto': 1,
      'total_acerto': 0, 'proxima_revisao': ontem,
    });
    expect(await repo.contarCardsVencidos(seed.temaId), 1);
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/repositories/modo_repository_test.dart`
Expected: FAIL (métodos não existem)

- [ ] **Step 3: Implementar queries**

Adicionar ao final da classe `ModoRepository`:

```dart
  // Cards de fases desbloqueadas do tema (regra idêntica ao TrilhaController):
  // primeira fase da seção OU fase anterior com quiz >= 70 concluído.
  Future<List<CardModel>> cardsPoolDesbloqueado(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT c.* FROM cards c
      JOIN fases f ON f.id = c.fase_id
      JOIN secoes s ON s.id = f.secao_id
      WHERE s.tema_id = ?
        AND (
          f.ordem = (SELECT MIN(f2.ordem) FROM fases f2 WHERE f2.secao_id = f.secao_id)
          OR EXISTS (
            SELECT 1 FROM quiz_tentativas qt
            JOIN fases fa ON fa.id = qt.fase_id
            WHERE fa.secao_id = f.secao_id
              AND fa.ordem = (SELECT MAX(f3.ordem) FROM fases f3
                              WHERE f3.secao_id = f.secao_id AND f3.ordem < f.ordem)
              AND qt.concluido = 1 AND qt.pontuacao >= 70
          )
        )
    ''', [temaId]);
    return rows.map(CardModel.fromMap).toList();
  }

  // Cards vencidos do SRS no tema (mais atrasados primeiro).
  // Card visto implica fase desbloqueada — sem filtro extra de desbloqueio.
  Future<List<CardModel>> cardsVencidos(int temaId, int limite) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT c.* FROM cards c
      JOIN progresso_flashcard pf ON pf.card_id = c.id
      JOIN fases f ON f.id = c.fase_id
      JOIN secoes s ON s.id = f.secao_id
      WHERE s.tema_id = ? AND pf.total_visto > 0
        AND DATE(pf.proxima_revisao) <= DATE('now', 'localtime')
      ORDER BY pf.proxima_revisao ASC
      LIMIT ?
    ''', [temaId, limite]);
    return rows.map(CardModel.fromMap).toList();
  }

  Future<int> contarCardsVencidos(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.rawQuery('''
      SELECT COUNT(*) AS total FROM cards c
      JOIN progresso_flashcard pf ON pf.card_id = c.id
      JOIN fases f ON f.id = c.fase_id
      JOIN secoes s ON s.id = f.secao_id
      WHERE s.tema_id = ? AND pf.total_visto > 0
        AND DATE(pf.proxima_revisao) <= DATE('now', 'localtime')
    ''', [temaId]);
    return (rows.first['total'] as int?) ?? 0;
  }
```

- [ ] **Step 4: Rodar testes e ver passar**

Run: `flutter test test/repositories/modo_repository_test.dart`
Expected: PASS (13 testes)

- [ ] **Step 5: Commit**

```bash
git add lib/repositories/modo_repository.dart test/repositories/modo_repository_test.dart
git commit -m "feat(modos): queries de pool desbloqueado e cards vencidos"
```

---

### Task 4: MetricaService — eventos dos modos

**Files:**
- Modify: `lib/services/metrica_service.dart`

Wrappers finos sobre `EventoRepository` (já testado). Sem teste novo — padrão do arquivo.

- [ ] **Step 1: Adicionar métodos**

Adicionar ao final da classe `MetricaService` (antes do `}` final):

```dart
  // ---- Modos de estudo ----

  Future<void> desafioIniciado(int temaId, String nomeTema, int numQuestoes) =>
      _repo.registrar(Evento(
        evento: 'desafio_iniciado',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'num_questoes': numQuestoes},
      ));

  Future<void> desafioConcluido({
    required int temaId,
    required String nomeTema,
    required int nota,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'desafio_concluido',
        tema: nomeTema,
        valor: '$nota',
        metadata: {'tema_id': temaId, 'nota': nota, 'tempo_total_s': tempoTotalS},
      ));

  Future<void> desafioAbandonado({
    required int temaId,
    required String nomeTema,
    required int questaoAtual,
    required int totalQuestoes,
  }) =>
      _repo.registrar(Evento(
        evento: 'desafio_abandonado',
        tema: nomeTema,
        metadata: {
          'tema_id': temaId,
          'questao_atual': questaoAtual,
          'total_questoes': totalQuestoes,
        },
      ));

  Future<void> revisaoIniciada(int temaId, String nomeTema, int cardsVencidos) =>
      _repo.registrar(Evento(
        evento: 'revisao_iniciada',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'cards_vencidos': cardsVencidos},
      ));

  Future<void> revisaoConcluida({
    required int temaId,
    required String nomeTema,
    required int cardsRevisados,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'revisao_concluida',
        tema: nomeTema,
        metadata: {
          'tema_id': temaId,
          'cards_revisados': cardsRevisados,
          'tempo_total_s': tempoTotalS,
        },
      ));

  Future<void> maratonaIniciada(int temaId, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'maratona_iniciada',
        tema: nomeTema,
        metadata: {'tema_id': temaId},
      ));

  Future<void> maratonaConcluida({
    required int temaId,
    required String nomeTema,
    required int score,
    required bool recordeBatido,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'maratona_concluida',
        tema: nomeTema,
        valor: '$score',
        metadata: {
          'tema_id': temaId,
          'score': score,
          'recorde_batido': recordeBatido,
          'tempo_total_s': tempoTotalS,
        },
      ));

  Future<void> maratonaAbandonada({
    required int temaId,
    required String nomeTema,
    required int scoreParcial,
  }) =>
      _repo.registrar(Evento(
        evento: 'maratona_abandonada',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'score_parcial': scoreParcial},
      ));
```

- [ ] **Step 2: Verificar análise e testes**

Run: `flutter analyze && flutter test`
Expected: 0 erros novos; testes existentes PASS

- [ ] **Step 3: Commit**

```bash
git add lib/services/metrica_service.dart
git commit -m "feat(metricas): eventos dos modos de estudo"
```

---

### Task 5: Helper QuizPontuacao

**Files:**
- Create: `lib/services/quiz_pontuacao.dart`
- Test: `test/services/quiz_pontuacao_test.dart`

`QuizController` NÃO é alterado (funciona e tem cobertura via app) — helper serve os controllers novos.

- [ ] **Step 1: Escrever testes que falham**

```dart
// test/services/quiz_pontuacao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/services/quiz_pontuacao.dart';

void main() {
  test('acertou rápido (< metade do tempo) = 10 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 10, tempoPorQuestao: 30), 10);
  });

  test('acertou devagar (>= metade do tempo) = 7 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 15, tempoPorQuestao: 30), 7);
    expect(QuizPontuacao.pontosQuestao(acertou: true, tempoGasto: 30, tempoPorQuestao: 30), 7);
  });

  test('errou = 0 pontos', () {
    expect(QuizPontuacao.pontosQuestao(acertou: false, tempoGasto: 5, tempoPorQuestao: 30), 0);
  });

  test('nota é proporcional ao máximo possível', () {
    expect(QuizPontuacao.nota(50, 5), 100); // 5 questões × 10 = 50
    expect(QuizPontuacao.nota(35, 5), 70);
    expect(QuizPontuacao.nota(0, 5), 0);
  });

  test('nota com zero questões é 0', () {
    expect(QuizPontuacao.nota(0, 0), 0);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/services/quiz_pontuacao_test.dart`
Expected: FAIL (arquivo não existe)

- [ ] **Step 3: Implementar**

```dart
// lib/services/quiz_pontuacao.dart
// Pontuação padrão por questão (regra do Plano.md):
// acertou em < metade do tempo = 10 | acertou em >= metade = 7 | errou/estourou = 0

class QuizPontuacao {
  static int pontosQuestao({
    required bool acertou,
    required int tempoGasto,
    required int tempoPorQuestao,
  }) {
    if (!acertou) return 0;
    return tempoGasto < tempoPorQuestao / 2 ? 10 : 7;
  }

  // Nota 0–100 proporcional ao máximo possível (totalQuestoes × 10)
  static int nota(int somaPontos, int totalQuestoes) {
    final totalPossivel = totalQuestoes * 10;
    if (totalPossivel == 0) return 0;
    return (somaPontos / totalPossivel * 100).round();
  }
}
```

- [ ] **Step 4: Rodar testes e ver passar**

Run: `flutter test test/services/quiz_pontuacao_test.dart`
Expected: PASS (5 testes)

- [ ] **Step 5: Commit**

```bash
git add lib/services/quiz_pontuacao.dart test/services/quiz_pontuacao_test.dart
git commit -m "feat(modos): helper QuizPontuacao com regra 10/7/0"
```

---

### Task 6: Extrair widgets compartilhados do QuizScreen

**Files:**
- Create: `lib/screens/quiz/widgets/quiz_timer_bar.dart`
- Create: `lib/screens/quiz/widgets/quiz_questao_card.dart`
- Create: `lib/screens/quiz/widgets/quiz_alternativas.dart`
- Create: `lib/screens/quiz/widgets/tempo_esgotado_banner.dart`
- Modify: `lib/screens/quiz/quiz_screen.dart`

Refactor puro de UI — comportamento idêntico. Widgets recebem valores simples (não o controller) pra serem reusáveis por Desafio e Maratona.

- [ ] **Step 1: Criar QuizTimerBar**

```dart
// lib/screens/quiz/widgets/quiz_timer_bar.dart
// Barra de timer do quiz: roxa, vira vermelha quando resta < 30% do tempo
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizTimerBar extends StatelessWidget {
  final double percentual; // 0.0 a 1.0
  final int segundos;

  const QuizTimerBar({super.key, required this.percentual, required this.segundos});

  @override
  Widget build(BuildContext context) {
    final cor = percentual < 0.30 ? const Color(0xFFFF3D00) : AppColors.purple;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentual,
                backgroundColor: const Color(0xFF1A1A3A),
                valueColor: AlwaysStoppedAnimation<Color>(cor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$segundos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Criar QuizQuestaoCard**

```dart
// lib/screens/quiz/widgets/quiz_questao_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizQuestaoCard extends StatelessWidget {
  final String pergunta;

  const QuizQuestaoCard({super.key, required this.pergunta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          pergunta,
          style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Criar QuizAlternativas**

```dart
// lib/screens/quiz/widgets/quiz_alternativas.dart
// Lista A/B/C/D com highlight roxo na selecionada
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizAlternativas extends StatelessWidget {
  final List<String> alternativas;
  final int? respostaSelecionada;
  final bool desabilitada;
  final ValueChanged<int> onSelecionar;

  const QuizAlternativas({
    super.key,
    required this.alternativas,
    required this.respostaSelecionada,
    required this.desabilitada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    const letras = ['A', 'B', 'C', 'D'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: alternativas.length,
      itemBuilder: (_, i) {
        final selecionadaEsta = respostaSelecionada == i;
        return GestureDetector(
          onTap: desabilitada ? null : () => onSelecionar(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selecionadaEsta
                  ? AppColors.purple.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selecionadaEsta ? AppColors.purple : const Color(0xFF2A2A5A),
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
                    color: selecionadaEsta ? AppColors.purple : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alternativas[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: selecionadaEsta ? Colors.white : const Color(0xFFCCCCCC),
                      fontWeight: selecionadaEsta ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Criar TempoEsgotadoBanner**

```dart
// lib/screens/quiz/widgets/tempo_esgotado_banner.dart
import 'package:flutter/material.dart';

class TempoEsgotadoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const TempoEsgotadoBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              color: Color(0xFFFF5252), fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Refatorar QuizScreen para usar os widgets**

Em `lib/screens/quiz/quiz_screen.dart`:
- Adicionar imports:
```dart
import 'widgets/quiz_timer_bar.dart';
import 'widgets/quiz_questao_card.dart';
import 'widgets/quiz_alternativas.dart';
import 'widgets/tempo_esgotado_banner.dart';
```
- Remover a variável local `corTimer` (linhas ~121-124) — a cor agora vive no `QuizTimerBar`.
- Substituir o bloco "Barra de timer + número" (o `Padding` com `Row`/`LinearProgressIndicator`, linhas ~155-187) por:
```dart
                    QuizTimerBar(
                      percentual: ctrl.percentualTempo,
                      segundos: ctrl.segundosRestantes,
                    ),
```
- Substituir o bloco "Card da pergunta" (o `Padding` com `Container`, linhas ~189-205) por:
```dart
                    QuizQuestaoCard(pergunta: card.pergunta),
```
- Substituir o bloco "Timer esgotado: mensagem" (o `if (tempoEsgotado) GestureDetector(...)`, linhas ~209-231) por:
```dart
                    if (tempoEsgotado)
                      TempoEsgotadoBanner(onTap: ctrl.avancarAposTempoEsgotado),
```
- Substituir o bloco "Alternativas" (o `Expanded` com `ListView.builder`, linhas ~233-299) por:
```dart
                    Expanded(
                      child: QuizAlternativas(
                        alternativas: ctrl.alternativasAtual,
                        respostaSelecionada: ctrl.respostaSelecionada,
                        desabilitada: tempoEsgotado || selecionada,
                        onSelecionar: ctrl.selecionarResposta,
                      ),
                    ),
```

- [ ] **Step 6: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; todos os testes PASS

- [ ] **Step 7: Validar visualmente (golden path)**

Run: `flutter run -d windows` (ou emulador Android)
Navegar: Home → CFC → seção → nó de quiz → jogar 2-3 questões (uma deixando estourar o tempo). Visual e comportamento devem estar idênticos a antes.

- [ ] **Step 8: Commit**

```bash
git add lib/screens/quiz/widgets/ lib/screens/quiz/quiz_screen.dart
git commit -m "refactor(quiz): extrai widgets compartilhados da QuizScreen"
```

---

### Task 7: DesafioController

**Files:**
- Create: `lib/controllers/desafio_controller.dart`

Espelha o fluxo do `QuizController` (timer, estados, auto-avanço) com fonte = pool desbloqueado do tema, persistência em `modo_tentativas`, sem estrelas. Lógica de pontuação/queries já testada nas Tasks 2, 3 e 5 — sem teste próprio de controller (timer torna teste frágil; mesmo critério do `QuizController`, que não tem teste unitário).

- [ ] **Step 1: Implementar controller**

```dart
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
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze`
Expected: 0 erros novos

- [ ] **Step 3: Commit**

```bash
git add lib/controllers/desafio_controller.dart
git commit -m "feat(desafio): DesafioController com pool desbloqueado e nota 0-100"
```

---

### Task 8: Telas do Desafio + rotas

**Files:**
- Create: `lib/screens/desafio/desafio_screen.dart`
- Create: `lib/screens/desafio/desafio_result_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Criar DesafioScreen**

```dart
// lib/screens/desafio/desafio_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/desafio_controller.dart';
import '../../theme/app_theme.dart';
import '../quiz/widgets/quiz_alternativas.dart';
import '../quiz/widgets/quiz_questao_card.dart';
import '../quiz/widgets/quiz_timer_bar.dart';
import '../quiz/widgets/tempo_esgotado_banner.dart';

class DesafioScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const DesafioScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<DesafioScreen> createState() => _DesafioScreenState();
}

class _DesafioScreenState extends State<DesafioScreen> {
  bool _concluindo = false;
  bool _navegandoParaResultado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DesafioController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  Future<bool> _onWillPop() async {
    final ctrl = context.read<DesafioController>();
    // Pool vazio: sai direto, nada a abandonar
    if (ctrl.poolVazio) {
      if (mounted) context.pop();
      return false;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sheetBg,
        title: const Text('Sair do desafio?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'A tentativa será registrada como abandonada e o desafio de hoje continua disponível.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<DesafioController>().abandonar();
      if (mounted) context.pop();
    }
    return false;
  }

  Future<void> _irParaResultado(DesafioController ctrl) async {
    if (_concluindo) return;
    _concluindo = true;
    final resultado = await ctrl.concluir();
    if (!mounted) return;
    context.pushReplacement('/desafio-resultado', extra: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onWillPop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<DesafioController>(
          builder: (_, ctrl, __) {
            if (ctrl.carregando) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            if (ctrl.poolVazio) {
              return _EstadoVazio(onVoltar: () => context.pop());
            }

            if (ctrl.desafioConcluido) {
              if (!_navegandoParaResultado) {
                _navegandoParaResultado = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _irParaResultado(ctrl);
                });
              }
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            final card = ctrl.questaoAtual!;
            final tempoEsgotado = ctrl.estado == EstadoQuestaoDesafio.tempoEsgotado;
            final selecionada = ctrl.estado == EstadoQuestaoDesafio.selecionada;

            return SafeArea(
              child: Column(
                children: [
                  // Header laranja do desafio
                  Container(
                    color: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desafio Diário · ${widget.nomeTema}',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
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
                      ],
                    ),
                  ),
                  QuizTimerBar(
                    percentual: ctrl.percentualTempo,
                    segundos: ctrl.segundosRestantes,
                  ),
                  QuizQuestaoCard(pergunta: card.pergunta),
                  const SizedBox(height: 12),
                  if (tempoEsgotado)
                    TempoEsgotadoBanner(onTap: ctrl.avancarAposTempoEsgotado),
                  Expanded(
                    child: QuizAlternativas(
                      alternativas: ctrl.alternativasAtual,
                      respostaSelecionada: ctrl.respostaSelecionada,
                      desabilitada: tempoEsgotado || selecionada,
                      onSelecionar: ctrl.selecionarResposta,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onVoltar;

  const _EstadoVazio({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📖', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Nada por aqui ainda',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estude uma fase primeiro para liberar o desafio deste tema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onVoltar,
                  child: const Text('Voltar',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Criar DesafioResultScreen**

```dart
// lib/screens/desafio/desafio_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/desafio_controller.dart';
import '../../theme/app_theme.dart';

class DesafioResultScreen extends StatelessWidget {
  final DesafioResultado resultado;

  const DesafioResultScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${resultado.nota}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'pontos',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3060),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Desafio de hoje concluído!\nVolte amanhã para um novo desafio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.pop(), // volta para SecoesScreen
                  child: const Text(
                    'Voltar ao tema',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Adicionar rotas em app.dart**

Em `lib/app.dart`, adicionar imports:
```dart
import 'controllers/desafio_controller.dart';
import 'screens/desafio/desafio_result_screen.dart';
import 'screens/desafio/desafio_screen.dart';
```
Adicionar rotas dentro de `routes: [` (após a rota `/quiz-resultado`):
```dart
    GoRoute(
      path: '/desafio/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => DesafioController(),
          child: DesafioScreen(temaId: temaId, nomeTema: nomeTema),
        );
      },
    ),
    GoRoute(
      path: '/desafio-resultado',
      builder: (_, state) {
        final resultado = state.extra as DesafioResultado;
        return DesafioResultScreen(resultado: resultado);
      },
    ),
```

- [ ] **Step 4: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/desafio/ lib/app.dart
git commit -m "feat(desafio): telas do Desafio Diário e rotas"
```

---

### Task 9: MaratonaController (com testes)

**Files:**
- Create: `lib/controllers/maratona_controller.dart`
- Test: `test/controllers/maratona_controller_test.dart`

Lógica própria (vidas, fila sem repetição, re-embaralhamento) merece teste. Testes chamam `selecionarResposta`/`avancarAposTempoEsgotado` diretamente — sem esperar timer. `responderAtual(acertou:)` é interno testável via resposta selecionada correta/errada usando `indiceCorreto` exposto.

- [ ] **Step 1: Escrever testes que falham**

```dart
// test/controllers/maratona_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/controllers/maratona_controller.dart';
import 'package:flashquiz/db/database_helper.dart';

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

  // Monta tema com 1 seção / 1 fase / 3 cards (primeira fase = desbloqueada)
  Future<int> seedTema() async {
    final db = await DatabaseHelper().banco;
    final temaId = await db.insert('temas', {'nome': 'TesteMaratona', 'icone': '🏃'});
    final secaoId = await db.insert('secoes', {'tema_id': temaId, 'nome': 'S1', 'ordem': 0});
    final faseId = await db.insert('fases', {'secao_id': secaoId, 'nome': 'F1', 'ordem': 1});
    for (var i = 0; i < 3; i++) {
      await db.insert('cards', {
        'fase_id': faseId,
        'pergunta': 'p$i',
        'resposta': 'R$i',
        'alternativa_b': 'B',
        'alternativa_c': 'C',
        'alternativa_d': 'D',
      });
    }
    return temaId;
  }

  test('carregar monta fila com pool desbloqueado', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    expect(ctrl.poolVazio, isFalse);
    expect(ctrl.questaoAtual, isNotNull);
    expect(ctrl.erros, 0);
    expect(ctrl.acertos, 0);
    ctrl.dispose();
  });

  test('acerto incrementa acertos; erro incrementa erros', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    ctrl.selecionarResposta(ctrl.indiceCorreto); // acerto
    expect(ctrl.acertos, 1);
    expect(ctrl.erros, 0);

    final errado = (ctrl.indiceCorreto + 1) % 4;
    ctrl.selecionarResposta(errado); // erro
    expect(ctrl.acertos, 1);
    expect(ctrl.erros, 1);
    ctrl.dispose();
  });

  test('3 erros encerram a partida', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    for (var i = 0; i < 3; i++) {
      expect(ctrl.fimDeJogo, isFalse);
      ctrl.selecionarResposta((ctrl.indiceCorreto + 1) % 4);
    }
    expect(ctrl.erros, 3);
    expect(ctrl.fimDeJogo, isTrue);
    ctrl.dispose();
  });

  test('fila não repete card até esgotar o pool, depois re-embaralha', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    final vistos = <int>[];
    for (var i = 0; i < 3; i++) {
      vistos.add(ctrl.questaoAtual!.id);
      ctrl.selecionarResposta(ctrl.indiceCorreto);
    }
    // 3 cards distintos na primeira volta
    expect(vistos.toSet().length, 3);
    // Pool esgotado: quarta questão existe (re-embaralhado)
    expect(ctrl.questaoAtual, isNotNull);
    ctrl.dispose();
  });

  test('concluir salva score e detecta recorde batido', () async {
    final temaId = await seedTema();
    final ctrl = MaratonaController();
    await ctrl.carregar(temaId, 'TesteMaratona');

    ctrl.selecionarResposta(ctrl.indiceCorreto);
    ctrl.selecionarResposta(ctrl.indiceCorreto);
    for (var i = 0; i < 3; i++) {
      ctrl.selecionarResposta((ctrl.indiceCorreto + 1) % 4);
    }
    expect(ctrl.fimDeJogo, isTrue);

    final resultado = await ctrl.concluir();
    expect(resultado.score, 2);
    expect(resultado.recordeBatido, isTrue); // primeiro jogo sempre bate recorde 0... exceto score 0
    ctrl.dispose();
  });
}
```

**Nota de implementação para os testes passarem sem timer:** `selecionarResposta` na maratona registra e avança **imediatamente** (síncrono) — diferente do quiz de fase que espera 1s. A UI mantém o highlight visual via o próprio rebuild (o card muda logo, estilo "arcade", combina com o modo). Isso simplifica e torna o controller determinístico.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/controllers/maratona_controller_test.dart`
Expected: FAIL (arquivo não existe)

- [ ] **Step 3: Implementar controller**

```dart
// lib/controllers/maratona_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
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

  MaratonaController({
    ModoRepository? modoRepo,
    ConfigRepository? configRepo,
    MetricaService? metrica,
  })  : _modoRepo = modoRepo ?? ModoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
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
```

**Atenção ao teste de recorde:** score 2 > recorde 0 → `recordeBatido = true`. Se score for 0 e recorde 0, `0 > 0` é false — sem falso "recorde batido".

- [ ] **Step 4: Rodar testes e ver passar**

Run: `flutter test test/controllers/maratona_controller_test.dart`
Expected: PASS (5 testes)

- [ ] **Step 5: Rodar suíte completa + análise**

Run: `flutter analyze && flutter test`
Expected: 0 erros; tudo PASS

- [ ] **Step 6: Commit**

```bash
git add lib/controllers/maratona_controller.dart test/controllers/maratona_controller_test.dart
git commit -m "feat(maratona): MaratonaController com vidas, fila sem repetição e recorde"
```

---

### Task 10: Telas da Maratona + rotas

**Files:**
- Create: `lib/screens/maratona/maratona_screen.dart`
- Create: `lib/screens/maratona/maratona_result_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Criar MaratonaScreen**

```dart
// lib/screens/maratona/maratona_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/maratona_controller.dart';
import '../../theme/app_theme.dart';
import '../quiz/widgets/quiz_alternativas.dart';
import '../quiz/widgets/quiz_questao_card.dart';
import '../quiz/widgets/quiz_timer_bar.dart';
import '../quiz/widgets/tempo_esgotado_banner.dart';

class MaratonaScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const MaratonaScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<MaratonaScreen> createState() => _MaratonaScreenState();
}

class _MaratonaScreenState extends State<MaratonaScreen> {
  bool _concluindo = false;
  bool _navegandoParaResultado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaratonaController>().carregar(widget.temaId, widget.nomeTema);
    });
  }

  Future<bool> _onWillPop() async {
    final ctrl = context.read<MaratonaController>();
    if (ctrl.poolVazio) {
      if (mounted) context.pop();
      return false;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sheetBg,
        title: const Text('Abandonar maratona?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'O score desta partida não será salvo como recorde.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<MaratonaController>().abandonar();
      if (mounted) context.pop();
    }
    return false;
  }

  Future<void> _irParaResultado(MaratonaController ctrl) async {
    if (_concluindo) return;
    _concluindo = true;
    final resultado = await ctrl.concluir();
    if (!mounted) return;
    context.pushReplacement('/maratona-resultado', extra: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onWillPop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<MaratonaController>(
          builder: (_, ctrl, __) {
            if (ctrl.carregando) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            if (ctrl.poolVazio) {
              return _EstadoVazio(onVoltar: () => context.pop());
            }

            if (ctrl.fimDeJogo) {
              if (!_navegandoParaResultado) {
                _navegandoParaResultado = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _irParaResultado(ctrl);
                });
              }
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            final card = ctrl.questaoAtual!;
            final tempoEsgotado = ctrl.estado == EstadoQuestaoMaratona.tempoEsgotado;

            return SafeArea(
              child: Column(
                children: [
                  // Header teal: score + vidas
                  Container(
                    color: AppColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text('🏃', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maratona · ${widget.nomeTema}',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ctrl.acertos} acertos',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        // Vidas restantes (corações)
                        Row(
                          children: List.generate(ctrl.maxErros, (i) {
                            final perdida = i < ctrl.erros;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                perdida ? '🖤' : '❤️',
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  QuizTimerBar(
                    percentual: ctrl.percentualTempo,
                    segundos: ctrl.segundosRestantes,
                  ),
                  QuizQuestaoCard(pergunta: card.pergunta),
                  const SizedBox(height: 12),
                  if (tempoEsgotado)
                    TempoEsgotadoBanner(onTap: ctrl.avancarAposTempoEsgotado),
                  Expanded(
                    child: QuizAlternativas(
                      alternativas: ctrl.alternativasAtual,
                      respostaSelecionada: null,
                      desabilitada: tempoEsgotado,
                      onSelecionar: ctrl.selecionarResposta,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onVoltar;

  const _EstadoVazio({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📖', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Nada por aqui ainda',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estude uma fase primeiro para liberar a maratona deste tema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onVoltar,
                  child: const Text('Voltar',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Criar MaratonaResultScreen**

```dart
// lib/screens/maratona/maratona_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/maratona_controller.dart';
import '../../theme/app_theme.dart';

class MaratonaResultScreen extends StatelessWidget {
  final MaratonaResultado resultado;

  const MaratonaResultScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(resultado.recordeBatido ? '🏆' : '🏃',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${resultado.score}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'acertos',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3060),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    resultado.recordeBatido
                        ? 'Novo recorde! 🎉'
                        : 'Recorde: ${resultado.recorde}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: resultado.recordeBatido ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pushReplacement(
                        '/maratona/${resultado.temaId}'
                        '?nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                      ),
                      child: const Text(
                        'Jogar de novo',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A3060)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Voltar ao tema',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

- [ ] **Step 3: Adicionar rotas em app.dart**

Imports:
```dart
import 'controllers/maratona_controller.dart';
import 'screens/maratona/maratona_result_screen.dart';
import 'screens/maratona/maratona_screen.dart';
```
Rotas (após `/desafio-resultado`):
```dart
    GoRoute(
      path: '/maratona/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => MaratonaController(),
          child: MaratonaScreen(temaId: temaId, nomeTema: nomeTema),
        );
      },
    ),
    GoRoute(
      path: '/maratona-resultado',
      builder: (_, state) {
        final resultado = state.extra as MaratonaResultado;
        return MaratonaResultScreen(resultado: resultado);
      },
    ),
```

- [ ] **Step 4: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/maratona/ lib/app.dart
git commit -m "feat(maratona): telas da Maratona com vidas e recorde"
```

---

### Task 11: Extrair widgets do FlashcardScreen

**Files:**
- Create: `lib/screens/flashcard/widgets/card_face.dart`
- Create: `lib/screens/flashcard/widgets/botao_avaliacao.dart`
- Modify: `lib/screens/flashcard/flashcard_screen.dart`

Refactor puro de UI — `_CardFace` e `_BotaoAvaliacao` são privados hoje; viram públicos pra reuso pela RevisaoScreen.

- [ ] **Step 1: Criar CardFace**

Mover o conteúdo da classe `_CardFace` (final de `flashcard_screen.dart`) para arquivo próprio, renomeando para `CardFace`:

```dart
// lib/screens/flashcard/widgets/card_face.dart
// Face do flashcard (frente = pergunta, verso = resposta)
import 'package:flutter/material.dart';

class CardFace extends StatelessWidget {
  final String texto;
  final String label;
  final Color cor;
  final Color corBorda;

  const CardFace({
    super.key,
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
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Criar BotaoAvaliacao**

Mover `_BotaoAvaliacao` para arquivo próprio, renomeando para `BotaoAvaliacao` (mesmo corpo, com `super.key`):

```dart
// lib/screens/flashcard/widgets/botao_avaliacao.dart
// Botão de autoavaliação SRS (Difícil / Médio / Fácil)
import 'package:flutter/material.dart';

class BotaoAvaliacao extends StatelessWidget {
  final String emoji;
  final String label;
  final Color cor;
  final Color corBorda;
  final VoidCallback onTap;

  const BotaoAvaliacao({
    super.key,
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
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Atualizar FlashcardScreen**

Em `lib/screens/flashcard/flashcard_screen.dart`:
- Adicionar imports:
```dart
import 'widgets/botao_avaliacao.dart';
import 'widgets/card_face.dart';
```
- Apagar as classes `_CardFace` e `_BotaoAvaliacao` do final do arquivo.
- Substituir todos os usos `_CardFace(` por `CardFace(` e `_BotaoAvaliacao(` por `BotaoAvaliacao(`.

- [ ] **Step 4: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/flashcard/
git commit -m "refactor(flashcard): extrai CardFace e BotaoAvaliacao para reuso"
```

---

### Task 12: RevisaoController + RevisaoScreen + rota

**Files:**
- Create: `lib/controllers/revisao_controller.dart`
- Create: `lib/screens/revisao/revisao_screen.dart`
- Modify: `lib/app.dart`

Espelha `FlashcardController` com fonte = `cardsVencidos(temaId)`. Query já testada (Task 3); avaliação SRS reusa `ProgressoRepository.salvarProgresso` (já testado). Sem teste próprio.

- [ ] **Step 1: Implementar controller**

```dart
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
      await _metrica.cardVisto(_cards[_indiceAtual].id, _cards[_indiceAtual].faseId, nomeTema);
    }

    notifyListeners();
  }
}
```

- [ ] **Step 2: Criar RevisaoScreen**

Estrutura idêntica à `FlashcardScreen` (flip 3D, botões SRS), com header próprio e dois estados finais (tudo em dia / sessão concluída):

```dart
// lib/screens/revisao/revisao_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/revisao_controller.dart';
import '../../theme/app_theme.dart';
import '../flashcard/widgets/botao_avaliacao.dart';
import '../flashcard/widgets/card_face.dart';

class RevisaoScreen extends StatefulWidget {
  final int temaId;
  final String nomeTema;

  const RevisaoScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  State<RevisaoScreen> createState() => _RevisaoScreenState();
}

class _RevisaoScreenState extends State<RevisaoScreen>
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
      context.read<RevisaoController>().carregarSessao(widget.temaId, widget.nomeTema);
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
    context.read<RevisaoController>().virar();
  }

  Future<void> _avaliar(int nivelSrs) async {
    await context.read<RevisaoController>().avaliar(nivelSrs);
    _flipCtrl.reset();
    setState(() => _mostrandoFrente = true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RevisaoController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revisão Inteligente 🧠',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(widget.nomeTema,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : ctrl.tudoEmDia
              ? _buildTudoEmDia(context)
              : ctrl.sessaoConcluida
                  ? _buildSessaoConcluida(context, ctrl)
                  : _buildSessao(context, ctrl),
    );
  }

  Widget _buildSessao(BuildContext context, RevisaoController ctrl) {
    final card = ctrl.cardAtual!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
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
                        ? CardFace(
                            texto: card.pergunta,
                            label: 'PERGUNTA',
                            cor: const Color(0xFF1C2040),
                            corBorda: const Color(0xFF3A3A5A),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: CardFace(
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
            AnimatedOpacity(
              opacity: ctrl.virado ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'Toque no card para ver a resposta',
                style: TextStyle(fontSize: 12, color: Color(0xFF555577)),
              ),
            ),
            const Spacer(),
            _buildBotoesAvaliacao(ctrl),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAvaliacao(RevisaoController ctrl) {
    return AnimatedOpacity(
      opacity: ctrl.virado ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !ctrl.virado,
        child: Row(
          children: [
            BotaoAvaliacao(
              emoji: '😓',
              label: 'Difícil',
              cor: const Color(0xFFB71C1C),
              corBorda: const Color(0xFFEF9A9A),
              onTap: () => _avaliar(0),
            ),
            const SizedBox(width: 10),
            BotaoAvaliacao(
              emoji: '🤔',
              label: 'Médio',
              cor: const Color(0xFFE65100),
              corBorda: const Color(0xFFFFCC80),
              onTap: () => _avaliar(1),
            ),
            const SizedBox(width: 10),
            BotaoAvaliacao(
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

  Widget _buildTudoEmDia(BuildContext context) {
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
                'Tudo em dia!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nenhum card para revisar agora. Volte mais tarde.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar',
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

  Widget _buildSessaoConcluida(BuildContext context, RevisaoController ctrl) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Revisão concluída!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctrl.totalSessao} cards revisados',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Voltar ao tema',
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
```

- [ ] **Step 3: Adicionar rota em app.dart**

Imports:
```dart
import 'controllers/revisao_controller.dart';
import 'screens/revisao/revisao_screen.dart';
```
Rota (após `/maratona-resultado`):
```dart
    GoRoute(
      path: '/revisao/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => RevisaoController(),
          child: RevisaoScreen(temaId: temaId, nomeTema: nomeTema),
        );
      },
    ),
```

- [ ] **Step 4: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/controllers/revisao_controller.dart lib/screens/revisao/ lib/app.dart
git commit -m "feat(revisao): Revisão Inteligente com cards vencidos do SRS"
```

---

### Task 13: Bloco "Modos de estudo" na SecoesScreen

**Files:**
- Modify: `lib/controllers/secoes_controller.dart`
- Modify: `lib/screens/secoes/secoes_screen.dart`

- [ ] **Step 1: Carregar dados dos modos no SecoesController**

Em `lib/controllers/secoes_controller.dart`:
- Adicionar import: `import '../repositories/modo_repository.dart';`
- Adicionar campo e injeção no construtor:
```dart
  final ModoRepository _modoRepo;
```
```dart
  SecoesController({SecaoRepository? repo, MetricaService? metrica, ModoRepository? modoRepo})
      : _repo = repo ?? SecaoRepository(),
        _metrica = metrica ?? MetricaService(),
        _modoRepo = modoRepo ?? ModoRepository();
```
- Adicionar campos públicos junto de `progressoGeral`:
```dart
  int? notaDesafioHoje;      // null = desafio de hoje ainda não feito
  int cardsVencidos = 0;
  int recordeMaratona = 0;
```
- Em `carregar`, após `progressoPorSecao = ...`, adicionar:
```dart
    notaDesafioHoje = await _modoRepo.notaDesafioHoje(temaId);
    cardsVencidos = await _modoRepo.contarCardsVencidos(temaId);
    recordeMaratona = await _modoRepo.recordeMaratona(temaId);
```

- [ ] **Step 2: Adicionar bloco de modos na SecoesScreen**

Em `lib/screens/secoes/secoes_screen.dart`:

Adicionar métodos de navegação em `_SecoesScreenState` (abaixo de `_navegarParaTrilha`):
```dart
  void _abrirModo(BuildContext context, String rota) {
    context
        .push('$rota/${widget.temaId}?nomeTema=${Uri.encodeComponent(widget.nomeTema)}')
        .then((_) {
      // Recarrega ao voltar (atualiza "feito hoje", vencidos e recorde)
      if (mounted) {
        context.read<SecoesController>().carregar(widget.temaId, widget.nomeTema);
      }
    });
  }
```

No `ListView` do `build`, logo após o `Container` da barra "Progresso geral" e do `SizedBox(height: 16)` que o segue, inserir:
```dart
                Text(
                  'Modos de estudo',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 8),
                _ModoCard(
                  emoji: '⚡',
                  titulo: 'Desafio Diário',
                  subtitulo: ctrl.notaDesafioHoje != null
                      ? '✓ Feito hoje · ${ctrl.notaDesafioHoje} pontos'
                      : '5 questões · uma vez por dia',
                  cor: AppColors.orange,
                  desabilitado: ctrl.notaDesafioHoje != null,
                  onTap: () => _abrirModo(context, '/desafio'),
                ),
                const SizedBox(height: 8),
                _ModoCard(
                  emoji: '🧠',
                  titulo: 'Revisão Inteligente',
                  subtitulo: ctrl.cardsVencidos > 0
                      ? '${ctrl.cardsVencidos} cards para revisar'
                      : 'Tudo em dia',
                  cor: AppColors.purple,
                  desabilitado: false,
                  onTap: () => _abrirModo(context, '/revisao'),
                ),
                const SizedBox(height: 8),
                _ModoCard(
                  emoji: '🏃',
                  titulo: 'Maratona',
                  subtitulo: ctrl.recordeMaratona > 0
                      ? 'Recorde: ${ctrl.recordeMaratona} acertos'
                      : 'Responda até errar 3',
                  cor: AppColors.teal,
                  desabilitado: false,
                  onTap: () => _abrirModo(context, '/maratona'),
                ),
                const SizedBox(height: 16),
```

Adicionar a classe `_ModoCard` ao final do arquivo (depois de `_SecaoCard`):
```dart
class _ModoCard extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final bool desabilitado;
  final VoidCallback onTap;

  const _ModoCard({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.desabilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: desabilitado ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: desabilitado ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(fontSize: 11, color: cor),
                    ),
                  ],
                ),
              ),
              if (!desabilitado) Icon(Icons.chevron_right, color: cor),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verificar**

Run: `flutter analyze && flutter test`
Expected: 0 erros; testes PASS

- [ ] **Step 4: Commit**

```bash
git add lib/controllers/secoes_controller.dart lib/screens/secoes/secoes_screen.dart
git commit -m "feat(modos): bloco Modos de estudo na SecoesScreen"
```

---

### Task 14: Verificação final + docs

**Files:**
- Modify: `Plano.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Suíte completa + análise**

Run: `flutter analyze && flutter test`
Expected: 0 erros; todos os testes PASS

- [ ] **Step 2: Teste manual no app (golden path + casos-limite)**

Run: `flutter run -d windows` (ou emulador Android). Verificar:
1. SecoesScreen do CFC mostra bloco "Modos de estudo" com 3 cards.
2. **Desafio:** jogar as 5 questões → tela de resultado com nota → voltar → card mostra "✓ Feito hoje · N pontos" e fica desabilitado.
3. **Desafio abandono:** (após meia-noite ou apagando a tentativa no banco) sair no meio → diálogo → confirmar → card continua disponível.
4. **Revisão:** com cards vencidos, sessão abre e avalia; sem vencidos, mostra "Tudo em dia!".
5. **Maratona:** corações caem a cada erro; 3 erros → resultado com score e recorde; "Jogar de novo" reinicia; recorde persiste e aparece no card.
6. **Pool vazio:** em tema sem estudo (ex: banco recém-criado, outra seção), desafio/maratona mostram estado vazio.
7. Quiz de fase e Flashcard normais continuam funcionando (regressão do refactor de widgets).

- [ ] **Step 3: Atualizar docs**

Em `Plano.md`:
- Marcar `- [x] Modos de estudo extras (Desafio Diário, Revisão Inteligente, Maratona)` no v1.0.
- Na tabela de planos: `Plano 3.5 | ... | ✅ Concluído` e `Plano 4 | ... | ⏳ Próximo`.

Em `CLAUDE.md`, adicionar na seção "REGRAS DE NEGÓCIO" (após o bloco "Progressão de seção"):
```markdown
### Modos de estudo (por tema, entrada na SecoesScreen)
- **Desafio Diário:** 1x/dia por tema, `desafio_num_questoes` questões do pool desbloqueado, nota 0-100, não afeta progressão. Gate: `ModoRepository.notaDesafioHoje`.
- **Revisão Inteligente:** flashcards vencidos do SRS no tema (`revisao_max_cards` máx), atualiza SRS normal.
- **Maratona:** questões sem fim do pool desbloqueado, `maratona_max_erros` erros encerram, score = acertos, recorde por tema.
- Tentativas dos modos ficam em `modo_tentativas` (nunca em `quiz_tentativas` — essa alimenta progressão).
- Pool desbloqueado = mesma regra da trilha (primeira fase da seção OU fase anterior com quiz ≥ 70).
```

E na tabela "Telas implementadas", adicionar:
```markdown
| DesafioScreen | `screens/desafio/desafio_screen.dart` | ✅ |
| DesafioResultScreen | `screens/desafio/desafio_result_screen.dart` | ✅ |
| MaratonaScreen | `screens/maratona/maratona_screen.dart` | ✅ |
| MaratonaResultScreen | `screens/maratona/maratona_result_screen.dart` | ✅ |
| RevisaoScreen | `screens/revisao/revisao_screen.dart` | ✅ |
```

- [ ] **Step 4: Commit final**

```bash
git add Plano.md CLAUDE.md
git commit -m "docs: marca Plano 3.5 (modos de estudo) como concluído"
```

---

## Cobertura da spec (self-review)

| Requisito da spec | Task |
|---|---|
| migration_v4 + configs | 1 |
| modo_tentativas CRUD, gate diário, recorde | 2 |
| Pool desbloqueado, cards vencidos | 3 |
| Metrificação (8 eventos) | 4 |
| Helper 10/7/0 | 5 |
| Widgets compartilhados do quiz | 6 |
| Desafio: controller, telas, rota, estado vazio, abandono | 7, 8 |
| Maratona: vidas, fila sem repetição, recorde, telas | 9, 10 |
| Revisão: widgets flashcard, controller, tela, tudo-em-dia | 11, 12 |
| Entrada na SecoesScreen (3 cards com estado) | 13 |
| Regressão + docs | 14 |

Desvio consciente da spec: maratona avança **sem** delay de 1s após resposta (modo arcade, controller determinístico e testável). Registrado na Task 9.

