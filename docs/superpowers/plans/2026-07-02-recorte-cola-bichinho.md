# Recorte & Cola + Bichinho Virtual — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a identidade dark navy genérica por "Recorte & Cola" (scrapbook de papel claro) e adicionar bichinho virtual pixel evolutivo por tema.

**Architecture:** Big-bang no design system (`app_theme.dart` reescrito + widgets de papel reutilizáveis), depois telas reestilizadas uma a uma. Bichinho = tabela `bichinhos` (migration v5) + `BichinhoRepository` + sprites pixel em código (CustomPainter). Energia plugada nos controllers existentes. Sons/haptics via `AudioService` singleton com toggles em `config`.

**Tech Stack:** Flutter 3.x · sqflite · provider · go_router · google_fonts (Patrick Hand, Nunito, VT323) · audioplayers (novo)

**Spec:** `docs/superpowers/specs/2026-07-02-recorte-cola-bichinho-design.md`

**Working dir:** `c:\Users\carlo\OneDrive\Documentos\Projects\FlashQuiz\flashquiz` — branch master (preferência do usuário).

**Convenções obrigatórias (CLAUDE.md):** comentários em português · SQL só em repositories · valores numéricos na tabela `config` · toda tabela nova tem `criado_em`/`atualizado_em` · tudo metrificado em `eventos` via `MetricaService`.

---

## Task 1: Design system novo — AppColors + ThemeData light

**Files:**
- Modify: `lib/theme/app_theme.dart` (reescrever)
- Modify: `pubspec.yaml`
- Test: `test/theme/app_theme_test.dart`

- [ ] **Step 1: Adicionar audioplayers e assets no pubspec.yaml**

Em `pubspec.yaml`, seção `dependencies`, adicionar após `google_fonts: ^6.2.0`:

```yaml
  audioplayers: ^6.0.0
```

E na seção `flutter:` (fim do arquivo):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
```

Criar a pasta vazia com um `.gitkeep`: `assets/sounds/.gitkeep` (sons chegam na Task 8).

Run: `flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 2: Escrever teste do AppColors novo**

Criar `test/theme/app_theme_test.dart`:

```dart
// test/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/theme/app_theme.dart';

void main() {
  group('AppColors Recorte & Cola', () {
    test('cores da fundação existem com valores da spec', () {
      expect(AppColors.papel, const Color(0xFFF2EDE4));
      expect(AppColors.cartao, const Color(0xFFFFFFFF));
      expect(AppColors.tinta, const Color(0xFF33302A));
      expect(AppColors.tintaSuave, const Color(0xFF8A8378));
      expect(AppColors.grao, const Color(0xFFD8D0C0));
    });

    test('acentos existem com valores da spec', () {
      expect(AppColors.laranja, const Color(0xFFFF5C39));
      expect(AppColors.verde, const Color(0xFF5CB270));
      expect(AppColors.amarelo, const Color(0xFFF7D046));
      expect(AppColors.azul, const Color(0xFF4DA6FF));
      expect(AppColors.rosa, const Color(0xFFFF9EBB));
    });

    test('accentFor cicla e é determinístico', () {
      expect(AppColors.accentFor(0), AppColors.accentFor(8));
      expect(AppColors.accentFor(1), isNot(AppColors.accentFor(2)));
    });
  });
}
```

- [ ] **Step 3: Rodar teste, ver falhar**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL — `papel` não definido.

- [ ] **Step 4: Reescrever lib/theme/app_theme.dart**

```dart
// lib/theme/app_theme.dart
// Design system "Recorte & Cola" — scrapbook de papel claro.
// Fundação: papel creme + tinta quase-preta. Acentos vivos usados com parcimônia.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Fundação
  static const Color papel = Color(0xFFF2EDE4);      // fundo geral — papel creme
  static const Color cartao = Color(0xFFFFFFFF);     // superfícies/cards
  static const Color tinta = Color(0xFF33302A);      // texto principal
  static const Color tintaSuave = Color(0xFF8A8378); // texto secundário — lápis
  static const Color grao = Color(0xFFD8D0C0);       // grão do papel, divisores

  // Acentos
  static const Color laranja = Color(0xFFFF5C39); // CTA, energia
  static const Color verde = Color(0xFF5CB270);   // sucesso, aprovado
  static const Color amarelo = Color(0xFFF7D046); // post-its, estrelas
  static const Color azul = Color(0xFF4DA6FF);    // info
  static const Color rosa = Color(0xFFFF9EBB);    // carinho

  static const List<Color> _accents = [
    laranja,
    verde,
    azul,
    rosa,
    amarelo,
    Color(0xFFB48CD9), // roxo suave
    Color(0xFF7FDBCA), // teal
    Color(0xFFFF8A7A), // coral
  ];

  static Color accentFor(int id) => _accents[id % _accents.length];
}

class AppTheme {
  AppTheme._();

  /// Tema claro único do app. Patrick Hand em títulos, Nunito no corpo.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.papel,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.laranja,
        brightness: Brightness.light,
        surface: AppColors.papel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.papel,
        foregroundColor: AppColors.tinta,
        elevation: 0,
        centerTitle: false,
      ),
      splashFactory: NoSplash.splashFactory, // pressão de papel substitui ripple
      highlightColor: Colors.transparent,
    );

    final corpo = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.tinta,
      displayColor: AppColors.tinta,
    );

    // Títulos manuscritos
    final titulos = GoogleFonts.patrickHand(color: AppColors.tinta);

    return base.copyWith(
      textTheme: corpo.copyWith(
        displayLarge: titulos.copyWith(fontSize: 40),
        displayMedium: titulos.copyWith(fontSize: 32),
        headlineLarge: titulos.copyWith(fontSize: 28),
        headlineMedium: titulos.copyWith(fontSize: 24),
        titleLarge: titulos.copyWith(fontSize: 22),
        titleMedium: titulos.copyWith(fontSize: 18),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: titulos.copyWith(fontSize: 24),
      ),
    );
  }

  /// Fonte pixel usada apenas no contexto do bichinho.
  static TextStyle pixel({double fontSize = 14, Color color = AppColors.tinta}) =>
      GoogleFonts.vt323(fontSize: fontSize, color: color);
}
```

- [ ] **Step 5: Aplicar tema no app**

Em `lib/app.dart`, localizar o `MaterialApp.router` (ou `MaterialApp`) e garantir `theme: AppTheme.light` (adicionar import `theme/app_theme.dart` se faltar; remover `darkTheme`/`themeMode` se existirem).

- [ ] **Step 6: Rodar testes e analyze**

Run: `flutter test test/theme/app_theme_test.dart && flutter analyze`
Expected: PASS. Analyze vai apontar usos antigos (`AppColors.background`, `.purple`, etc.) como erros — **isso é esperado nesta task**. Adicionar aliases temporários de compatibilidade no fim da classe `AppColors` (serão removidos na Task 15):

```dart
  // COMPAT — remover na task final de limpeza
  static const Color background = papel;
  static const Color surface = cartao;
  static const Color headerBg = papel;
  static const Color sheetBg = cartao;
  static const Color purple = laranja;
  static const Color orange = laranja;
  static const Color gold = amarelo;
  static const Color teal = Color(0xFF7FDBCA);
  static const Color textSecondary = tintaSuave;
  static const Color divider = grao;
```

Run de novo: `flutter analyze`
Expected: 0 erros (infos pré-existentes ok).

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml lib/theme/app_theme.dart lib/app.dart test/theme/app_theme_test.dart assets/sounds/.gitkeep
git commit -m "feat(theme): design system Recorte & Cola — paleta papel/tinta e tema claro"
```

---

## Task 2: Widgets de papel

**Files:**
- Create: `lib/widgets/papel/papel_card.dart`
- Create: `lib/widgets/papel/botao_papel.dart`
- Create: `lib/widgets/papel/post_it.dart`
- Create: `lib/widgets/papel/fita.dart`
- Create: `lib/widgets/papel/carimbo.dart`
- Create: `lib/widgets/papel/linha_costura.dart`
- Create: `lib/widgets/papel/fundo_papel.dart`
- Test: `test/widgets/papel_test.dart`

- [ ] **Step 1: Escrever testes de widget**

Criar `test/widgets/papel_test.dart`:

```dart
// test/widgets/papel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/widgets/papel/papel_card.dart';
import 'package:flashquiz/widgets/papel/botao_papel.dart';
import 'package:flashquiz/widgets/papel/post_it.dart';
import 'package:flashquiz/widgets/papel/carimbo.dart';
import 'package:flashquiz/widgets/papel/linha_costura.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('PapelCard renderiza filho e rotação é determinística', (tester) async {
    await tester.pumpWidget(_wrap(const PapelCard(seed: 42, child: Text('oi'))));
    expect(find.text('oi'), findsOneWidget);
    final t1 = tester.widget<Transform>(find.byType(Transform).first).transform;
    await tester.pumpWidget(_wrap(const PapelCard(seed: 42, child: Text('oi'))));
    final t2 = tester.widget<Transform>(find.byType(Transform).first).transform;
    expect(t1, t2); // mesma seed = mesma rotação
  });

  testWidgets('BotaoPapel dispara onPressed', (tester) async {
    var apertou = false;
    await tester.pumpWidget(_wrap(BotaoPapel(
      onPressed: () => apertou = true,
      child: const Text('Bora'),
    )));
    await tester.tap(find.text('Bora'));
    await tester.pumpAndSettle();
    expect(apertou, isTrue);
  });

  testWidgets('PostIt e Carimbo renderizam texto', (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [
      PostIt(child: Text('lembrete')),
      Carimbo(texto: 'APROVADO'),
      LinhaCostura(),
    ])));
    expect(find.text('lembrete'), findsOneWidget);
    expect(find.text('APROVADO'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar, ver falhar**

Run: `flutter test test/widgets/papel_test.dart`
Expected: FAIL — arquivos não existem.

- [ ] **Step 3: Implementar PapelCard**

```dart
// lib/widgets/papel/papel_card.dart
// Card de papel: branco, canto 4px, rotação torta determinística e sombra dura.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PapelCard extends StatelessWidget {
  final Widget child;
  final int seed; // hash estável (ex: id do item) — mesma seed, mesma rotação
  final EdgeInsetsGeometry padding;
  final Color cor;

  const PapelCard({
    super.key,
    required this.child,
    this.seed = 0,
    this.padding = const EdgeInsets.all(16),
    this.cor = AppColors.cartao,
  });

  /// Rotação entre -1.5° e +1.5° derivada da seed.
  double get _angulo => ((seed * 2654435761) % 100 - 50) / 50 * 0.026; // rad ≈ 1.5°

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _angulo,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), offset: Offset(2, 3), blurRadius: 0),
          ],
        ),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar BotaoPapel**

```dart
// lib/widgets/papel/botao_papel.dart
// Botão que "afunda" ao pressionar: scale 0.97 + sombra some. Substitui ripple.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class BotaoPapel extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color cor;
  final EdgeInsetsGeometry padding;

  const BotaoPapel({
    super.key,
    required this.onPressed,
    required this.child,
    this.cor = AppColors.laranja,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  State<BotaoPapel> createState() => _BotaoPapelState();
}

class _BotaoPapelState extends State<BotaoPapel> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null;
    return GestureDetector(
      onTapDown: habilitado ? (_) => setState(() => _pressionado = true) : null,
      onTapCancel: () => setState(() => _pressionado = false),
      onTapUp: habilitado
          ? (_) {
              setState(() => _pressionado = false);
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressionado ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: habilitado ? widget.cor : AppColors.grao,
            borderRadius: BorderRadius.circular(6),
            boxShadow: _pressionado || !habilitado
                ? []
                : const [BoxShadow(color: Color(0x40000000), offset: Offset(2, 3), blurRadius: 0)],
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar PostIt, Fita, Carimbo, LinhaCostura, FundoPapel**

```dart
// lib/widgets/papel/post_it.dart
// Post-it com dobra de canto e leve rotação.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PostIt extends StatelessWidget {
  final Widget child;
  final Color cor;
  final double angulo; // graus

  const PostIt({super.key, required this.child, this.cor = AppColors.amarelo, this.angulo = -2});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo * 3.14159 / 180,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor,
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), offset: Offset(1, 2), blurRadius: 0),
              ],
            ),
            child: child,
          ),
          // dobra do canto inferior direito
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(size: const Size(14, 14), painter: _DobraPainter(cor)),
          ),
        ],
      ),
    );
  }
}

class _DobraPainter extends CustomPainter {
  final Color cor;
  _DobraPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final sombra = Paint()..color = Colors.black.withValues(alpha: 0.15);
    final dobra = Paint()..color = Color.lerp(cor, Colors.black, 0.18)!;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, sombra);
    canvas.drawPath(path, dobra);
  }

  @override
  bool shouldRepaint(covariant _DobraPainter old) => old.cor != cor;
}
```

```dart
// lib/widgets/papel/fita.dart
// Fita adesiva translúcida que "cola" o topo de um card.
import 'package:flutter/material.dart';

class Fita extends StatelessWidget {
  final double largura;
  final double angulo; // graus

  const Fita({super.key, this.largura = 72, this.angulo = -4});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo * 3.14159 / 180,
      child: Container(
        width: largura,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 0),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/papel/carimbo.dart
// Carimbo rotacionado com borda dupla — APROVADO, RECORDE, etc.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class Carimbo extends StatelessWidget {
  final String texto;
  final Color cor;
  final double angulo; // graus
  final double fontSize;

  const Carimbo({
    super.key,
    required this.texto,
    this.cor = AppColors.verde,
    this.angulo = -8,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: cor, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: cor, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            texto,
            style: GoogleFonts.patrickHand(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: cor,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/papel/linha_costura.dart
// Divisor tracejado tipo costura / linha de recorte.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LinhaCostura extends StatelessWidget {
  final Color cor;
  const LinhaCostura({super.key, this.cor = AppColors.grao});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(double.infinity, 2), painter: _CosturaPainter(cor));
  }
}

class _CosturaPainter extends CustomPainter {
  final Color cor;
  _CosturaPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 8.0, gap = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset((x + dash).clamp(0, size.width), 1), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _CosturaPainter old) => old.cor != cor;
}
```

```dart
// lib/widgets/papel/fundo_papel.dart
// Fundo papel creme com grão pontilhado determinístico.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FundoPapel extends StatelessWidget {
  final Widget child;
  const FundoPapel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.papel,
      child: CustomPaint(
        foregroundPainter: _GraoPainter(),
        child: child,
      ),
    );
  }
}

class _GraoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.grao.withValues(alpha: 0.35);
    // Pontos em grade pseudo-aleatória determinística (sem Random pra não tremer)
    for (double y = 8; y < size.height; y += 26) {
      for (double x = 8; x < size.width; x += 26) {
        final dx = ((x * 7 + y * 13) % 11) - 5;
        final dy = ((x * 13 + y * 7) % 9) - 4;
        canvas.drawCircle(Offset(x + dx, y + dy), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
```

- [ ] **Step 6: Rodar testes**

Run: `flutter test test/widgets/papel_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/papel/ test/widgets/papel_test.dart
git commit -m "feat(papel): widgets do design system Recorte & Cola"
```

---

## Task 3: Migration v5 — tabela bichinhos + configs

**Files:**
- Create: `lib/db/migrations/migration_v5.dart`
- Modify: `lib/db/database_helper.dart`
- Test: `test/db/migration_v5_test.dart`

- [ ] **Step 1: Escrever teste**

Criar `test/db/migration_v5_test.dart` (seguir padrão de `test/db/migration_v4_test.dart` — abrir com `sqflite_common_ffi` e `DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath)`):

```dart
// test/db/migration_v5_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('tabela bichinhos existe com colunas esperadas', () async {
    final db = await DatabaseHelper().banco;
    final info = await db.rawQuery('PRAGMA table_info(bichinhos)');
    final colunas = info.map((c) => c['name']).toSet();
    expect(
      colunas.containsAll(
          {'id', 'tema_id', 'especie', 'estagio', 'energia', 'criado_em', 'atualizado_em'}),
      isTrue,
    );
  });

  test('configs do bichinho seedadas', () async {
    final db = await DatabaseHelper().banco;
    final rows = await db.query('config', where: "chave LIKE 'bichinho_%'");
    final chaves = rows.map((r) => r['chave']).toSet();
    expect(chaves, {
      'bichinho_energia_card',
      'bichinho_energia_quiz',
      'bichinho_energia_modo',
      'bichinho_threshold_1',
      'bichinho_threshold_2',
      'bichinho_threshold_3',
      'bichinho_threshold_4',
      'bichinho_streak_multiplicador',
      'bichinho_dias_fome',
      'bichinho_dias_dormindo',
    });
  });

  test('configs de som e haptics seedadas', () async {
    final db = await DatabaseHelper().banco;
    final som = await db.query('config', where: "chave = 'som_ativo'");
    final hap = await db.query('config', where: "chave = 'haptics_ativo'");
    expect(som.first['valor'], '1');
    expect(hap.first['valor'], '1');
  });
}
```

- [ ] **Step 2: Rodar, ver falhar**

Run: `flutter test test/db/migration_v5_test.dart`
Expected: FAIL — tabela não existe.

- [ ] **Step 3: Criar migration_v5.dart**

```dart
// lib/db/migrations/migration_v5.dart
// Tabela bichinhos (bichinho virtual por tema) + configs de energia/evolução e toggles de som/haptics

class MigrationV5 {
  static Future<void> executar(dynamic db) async {
    await db.execute('''
      CREATE TABLE bichinhos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tema_id INTEGER NOT NULL UNIQUE,
        especie INTEGER NOT NULL,
        estagio INTEGER NOT NULL DEFAULT 0,
        energia INTEGER NOT NULL DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tema_id) REFERENCES temas(id)
      )
    ''');

    final configs = [
      {'chave': 'bichinho_energia_card', 'valor': '2'},
      {'chave': 'bichinho_energia_quiz', 'valor': '15'},
      {'chave': 'bichinho_energia_modo', 'valor': '10'},
      {'chave': 'bichinho_threshold_1', 'valor': '50'},
      {'chave': 'bichinho_threshold_2', 'valor': '200'},
      {'chave': 'bichinho_threshold_3', 'valor': '500'},
      {'chave': 'bichinho_threshold_4', 'valor': '1000'},
      {'chave': 'bichinho_streak_multiplicador', 'valor': '1.5'},
      {'chave': 'bichinho_dias_fome', 'valor': '2'},
      {'chave': 'bichinho_dias_dormindo', 'valor': '7'},
      {'chave': 'som_ativo', 'valor': '1'},
      {'chave': 'haptics_ativo', 'valor': '1'},
    ];
    for (final c in configs) {
      await db.insert('config', c);
    }
  }
}
```

- [ ] **Step 4: Registrar no database_helper.dart**

Em `lib/db/database_helper.dart`: import `migrations/migration_v5.dart`, `version: 5`, adicionar `await MigrationV5.executar(db);` no `onCreate` e `if (oldVersion < 5) await MigrationV5.executar(db);` no `onUpgrade`.

- [ ] **Step 5: Rodar testes (v5 + suite inteira do db)**

Run: `flutter test test/db/`
Expected: PASS todos.

- [ ] **Step 6: Commit**

```bash
git add lib/db/ test/db/migration_v5_test.dart
git commit -m "feat(db): migration v5 — tabela bichinhos e configs de evolução/som"
```

---

## Task 4: Sprites pixel + BichinhoSprite

**Files:**
- Create: `lib/widgets/bichinho/sprites.dart`
- Create: `lib/widgets/bichinho/bichinho_sprite.dart`
- Test: `test/widgets/sprites_test.dart`

- [ ] **Step 1: Escrever teste das matrizes**

```dart
// test/widgets/sprites_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/widgets/bichinho/sprites.dart';

void main() {
  test('todas as matrizes são 16x16 com índices de cor válidos', () {
    for (final especie in Sprites.especies) {
      for (final estagio in especie.estagios) {
        expect(estagio.length, 16, reason: 'altura deve ser 16');
        for (final linha in estagio) {
          expect(linha.length, 16, reason: 'largura deve ser 16');
          for (final pixel in linha) {
            expect(pixel >= 0 && pixel < especie.palette.length + 1, isTrue,
                reason: 'índice $pixel fora da palette');
          }
        }
      }
    }
  });

  test('ovo é 16x16', () {
    expect(Sprites.ovo.length, 16);
    for (final linha in Sprites.ovo) {
      expect(linha.length, 16);
    }
  });

  test('existem pelo menos 3 espécies com 4 estágios cada', () {
    expect(Sprites.especies.length, greaterThanOrEqualTo(3));
    for (final e in Sprites.especies) {
      expect(e.estagios.length, 4); // filhote, jovem, adulto, lendário
    }
  });
}
```

- [ ] **Step 2: Rodar, ver falhar**

Run: `flutter test test/widgets/sprites_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar sprites.dart**

Estrutura de dados (o implementador desenha as matrizes seguindo o formato — cada espécie tem personalidade própria; 0 = transparente, 1..N = índice na palette, onde palette[0] é a cor do índice 1):

```dart
// lib/widgets/bichinho/sprites.dart
// Pixel art dos bichinhos em matrizes 16x16.
// 0 = transparente; n>0 = palette[n-1]. Ovo compartilhado (pintado com palette da espécie).
import 'package:flutter/material.dart';

class EspecieSprite {
  final String nome;
  final List<Color> palette; // cores da espécie
  final List<List<List<int>>> estagios; // [filhote, jovem, adulto, lendário]
  const EspecieSprite({required this.nome, required this.palette, required this.estagios});
}

class Sprites {
  Sprites._();

  /// Ovo compartilhado — usa palette da espécie (índice 1 = casca, 2 = manchas, 3 = contorno).
  static const List<List<int>> ovo = [
    [0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 3, 3, 1, 1, 1, 1, 3, 3, 0, 0, 0, 0],
    [0, 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0, 0, 0],
    [0, 0, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 3, 0, 0],
    [0, 0, 3, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 3, 0, 0],
    [0, 3, 1, 1, 1, 1, 2, 1, 1, 2, 2, 1, 1, 1, 3, 0],
    [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 3, 0],
    [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0],
    [0, 3, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0],
    [0, 3, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 3, 0],
    [0, 3, 1, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 3, 0],
    [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0],
    [0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0, 0],
    [0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0, 0],
    [0, 0, 0, 3, 3, 1, 1, 1, 1, 1, 1, 3, 3, 0, 0, 0],
    [0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0],
  ];

  // As 3 espécies de lançamento. Personalidades:
  // - Bolha (teal): redondinho tipo slime → ganha orelhas → asas → coroa
  // - Faísca (laranja): quadradinho elétrico → antenas → raios → aura
  // - Musgo (verde): brotinho → folhas → arbusto andante → árvore mística
  // O implementador desenha cada matriz 16x16 seguindo o formato do ovo acima.
  // REGRAS: estágios maiores ocupam mais pixels (filhote ~8x8 centrado, lendário ~15x15);
  // todo estágio tem 2 olhos visíveis; lendário tem detalhe dourado (última cor da palette).
  static const List<EspecieSprite> especies = [
    EspecieSprite(
      nome: 'Bolha',
      palette: [Color(0xFF7FDBCA), Color(0xFF5CC4B0), Color(0xFF33302A), Color(0xFFF7D046)],
      estagios: [/* 4 matrizes 16x16 desenhadas pelo implementador */],
    ),
    EspecieSprite(
      nome: 'Faísca',
      palette: [Color(0xFFFF9838), Color(0xFFFF5C39), Color(0xFF33302A), Color(0xFFF7D046)],
      estagios: [/* 4 matrizes 16x16 */],
    ),
    EspecieSprite(
      nome: 'Musgo',
      palette: [Color(0xFF7BC96F), Color(0xFF4A9B5E), Color(0xFF33302A), Color(0xFFF7D046)],
      estagios: [/* 4 matrizes 16x16 */],
    ),
  ];

  static EspecieSprite especiePara(int temaId) => especies[temaId % especies.length];
}
```

**Nota pro implementador:** as matrizes dos estágios DEVEM ser preenchidas de verdade (16 linhas × 16 colunas de ints) — o comentário `/* 4 matrizes */` acima é só abreviação do plano. Desenhar seguindo o exemplo do ovo. O teste valida dimensões e índices.

- [ ] **Step 4: Implementar bichinho_sprite.dart**

```dart
// lib/widgets/bichinho/bichinho_sprite.dart
// Renderiza uma matriz pixel via CustomPainter, com bounce idle opcional e humor.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'sprites.dart';

/// Humor do bichinho — muda olhos/boca e efeitos, não o sprite inteiro.
enum HumorBichinho { feliz, neutro, comFome, dormindo }

class BichinhoSprite extends StatefulWidget {
  final int temaId;
  final int estagio; // 0=ovo..4=lendário
  final HumorBichinho humor;
  final double tamanho;
  final bool animado; // bounce idle de 1px

  const BichinhoSprite({
    super.key,
    required this.temaId,
    required this.estagio,
    this.humor = HumorBichinho.feliz,
    this.tamanho = 48,
    this.animado = true,
  });

  @override
  State<BichinhoSprite> createState() => _BichinhoSpriteState();
}

class _BichinhoSpriteState extends State<BichinhoSprite> {
  bool _up = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animado) {
      _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
        if (mounted) setState(() => _up = !_up);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final especie = Sprites.especiePara(widget.temaId);
    final matriz = widget.estagio == 0 ? Sprites.ovo : especie.estagios[widget.estagio - 1];
    final deslocamento = _up ? -widget.tamanho / 48 : 0.0;

    return SizedBox(
      width: widget.tamanho,
      height: widget.tamanho,
      child: Transform.translate(
        offset: Offset(0, deslocamento),
        child: Opacity(
          // dormindo = esmaecido
          opacity: widget.humor == HumorBichinho.dormindo ? 0.55 : 1.0,
          child: CustomPaint(painter: _PixelPainter(matriz, especie.palette)),
        ),
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  final List<List<int>> matriz;
  final List<Color> palette;
  _PixelPainter(this.matriz, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 16;
    final paint = Paint();
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final v = matriz[y][x];
        if (v == 0) continue;
        paint.color = palette[v - 1];
        canvas.drawRect(Rect.fromLTWH(x * px, y * px, px + 0.5, px + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) =>
      old.matriz != matriz || old.palette != palette;
}
```

- [ ] **Step 5: Rodar testes**

Run: `flutter test test/widgets/sprites_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/bichinho/ test/widgets/sprites_test.dart
git commit -m "feat(bichinho): sprites pixel 16x16 e renderer CustomPainter"
```

---

## Task 5: BichinhoRepository + model

**Files:**
- Create: `lib/models/bichinho.dart`
- Create: `lib/repositories/bichinho_repository.dart`
- Test: `test/repositories/bichinho_repository_test.dart`

- [ ] **Step 1: Criar model**

```dart
// lib/models/bichinho.dart
class Bichinho {
  final int id;
  final int temaId;
  final int especie;
  final int estagio; // 0=ovo, 1=filhote, 2=jovem, 3=adulto, 4=lendário
  final int energia;

  const Bichinho({
    required this.id,
    required this.temaId,
    required this.especie,
    this.estagio = 0,
    this.energia = 0,
  });

  factory Bichinho.fromMap(Map<String, dynamic> m) => Bichinho(
        id: m['id'] as int,
        temaId: m['tema_id'] as int,
        especie: m['especie'] as int,
        estagio: m['estagio'] as int,
        energia: m['energia'] as int,
      );

  static const nomesEstagios = ['Ovo', 'Filhote', 'Jovem', 'Adulto', 'Lendário'];
  String get nomeEstagio => nomesEstagios[estagio];
  bool get lendario => estagio == 4;
}

/// Resultado de alimentar — a UI usa `evoluiu` pra disparar a animação.
class ResultadoAlimentar {
  final Bichinho bichinho;
  final int energiaGanha;
  final bool evoluiu;
  const ResultadoAlimentar({required this.bichinho, required this.energiaGanha, required this.evoluiu});
}

/// Resultado de obterOuCriar — `criado` = ovo acabou de nascer (dispara métrica bichinho_nasceu).
class BichinhoCriacao {
  final Bichinho bichinho;
  final bool criado;
  const BichinhoCriacao({required this.bichinho, required this.criado});
}
```

- [ ] **Step 2: Escrever testes do repository**

```dart
// test/repositories/bichinho_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/bichinho_repository.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_sprite.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  Future<int> criarTema() async {
    final db = await DatabaseHelper().banco;
    return db.insert('temas', {'nome': 'CFC', 'emoji': '🚗'});
  }

  test('obterOuCriar cria ovo na primeira visita e reporta criado', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    final r = await repo.obterOuCriar(temaId);
    expect(r.criado, isTrue);
    expect(r.bichinho.estagio, 0);
    expect(r.bichinho.energia, 0);
    expect(r.bichinho.especie, temaId % 3);
    // segunda chamada retorna o mesmo, sem criar
    final r2 = await repo.obterOuCriar(temaId);
    expect(r2.criado, isFalse);
    expect(r2.bichinho.id, r.bichinho.id);
  });

  test('alimentar sem streak soma energia base', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final r = await repo.alimentar(temaId, 10);
    expect(r.energiaGanha, 10);
    expect(r.bichinho.energia, 10);
    expect(r.evoluiu, isFalse);
  });

  test('alimentar com streak ativo aplica multiplicador 1.5 arredondado pra baixo', () async {
    final temaId = await criarTema();
    final db = await DatabaseHelper().banco;
    // streak ativo no perfil
    await db.update('perfil', {'streak_atual': 3});
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final r = await repo.alimentar(temaId, 15);
    expect(r.energiaGanha, 22); // 15 * 1.5 = 22.5 → 22
  });

  test('cruzar threshold promove estágio e reporta evoluiu', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final r = await repo.alimentar(temaId, 50); // threshold_1 = 50
    expect(r.evoluiu, isTrue);
    expect(r.bichinho.estagio, 1);
  });

  test('energia acumulada nunca é perdida e lendário não passa de 4', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    await repo.alimentar(temaId, 2000);
    final r = await repo.alimentar(temaId, 100);
    expect(r.bichinho.estagio, 4);
    expect(r.bichinho.energia, 2100);
    expect(r.evoluiu, isFalse); // já era lendário
  });

  test('humor por inatividade no tema', () async {
    final temaId = await criarTema();
    final repo = BichinhoRepository();
    await repo.obterOuCriar(temaId);
    final db = await DatabaseHelper().banco;

    // sem eventos = dormindo (nunca estudou)
    expect(await repo.humor(temaId), HumorBichinho.dormindo);

    // evento hoje = feliz
    await db.insert('eventos', {'evento': 'card_avaliado', 'tema': 'CFC'});
    expect(await repo.humor(temaId), HumorBichinho.feliz);
  });
}
```

**Nota:** se a tabela `perfil` não tiver linha seedada nos testes, inserir uma no helper `criarTema` (ver seed real em migration existente).

- [ ] **Step 3: Rodar, ver falhar**

Run: `flutter test test/repositories/bichinho_repository_test.dart`
Expected: FAIL — classe não existe.

- [ ] **Step 4: Implementar repository**

```dart
// lib/repositories/bichinho_repository.dart
// Bichinho virtual: criação, alimentação (energia), evolução e humor.
// Streak lido de perfil.streak_atual (>0 = ativo). Config define valores.
import '../db/database_helper.dart';
import '../models/bichinho.dart';
import '../widgets/bichinho/bichinho_sprite.dart';
import 'config_repository.dart';

class BichinhoRepository {
  final DatabaseHelper _db;
  final ConfigRepository _config;

  BichinhoRepository({DatabaseHelper? db, ConfigRepository? config})
      : _db = db ?? DatabaseHelper(),
        _config = config ?? ConfigRepository();

  static const int numEspecies = 3;

  Future<BichinhoCriacao> obterOuCriar(int temaId) async {
    final banco = await _db.banco;
    final rows = await banco.query('bichinhos', where: 'tema_id = ?', whereArgs: [temaId]);
    if (rows.isNotEmpty) {
      return BichinhoCriacao(bichinho: Bichinho.fromMap(rows.first), criado: false);
    }

    final id = await banco.insert('bichinhos', {
      'tema_id': temaId,
      'especie': temaId % numEspecies,
      'estagio': 0,
      'energia': 0,
    });
    final novo = await banco.query('bichinhos', where: 'id = ?', whereArgs: [id]);
    return BichinhoCriacao(bichinho: Bichinho.fromMap(novo.first), criado: true);
  }

  /// Soma energia (com multiplicador de streak) e promove estágio se cruzar threshold.
  Future<ResultadoAlimentar> alimentar(int temaId, int energiaBase) async {
    final banco = await _db.banco;
    final atual = (await obterOuCriar(temaId)).bichinho;

    final mult = await _multiplicadorStreak();
    final ganho = (energiaBase * mult).floor();
    final energiaNova = atual.energia + ganho;

    final estagioNovo = await _estagioPara(energiaNova);
    final evoluiu = estagioNovo > atual.estagio;

    await banco.update(
      'bichinhos',
      {
        'energia': energiaNova,
        'estagio': estagioNovo,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'tema_id = ?',
      whereArgs: [temaId],
    );

    final atualizado = (await obterOuCriar(temaId)).bichinho;
    return ResultadoAlimentar(bichinho: atualizado, energiaGanha: ganho, evoluiu: evoluiu);
  }

  /// Threshold de energia pro próximo estágio (null se lendário).
  Future<int?> proximoThreshold(int estagio) async {
    if (estagio >= 4) return null;
    return _config.getValorInt('bichinho_threshold_${estagio + 1}');
  }

  /// Humor calculado da última atividade registrada em eventos pro tema.
  Future<HumorBichinho> humor(int temaId) async {
    final banco = await _db.banco;
    final tema = await banco.query('temas', where: 'id = ?', whereArgs: [temaId]);
    if (tema.isEmpty) return HumorBichinho.dormindo;
    final nomeTema = tema.first['nome'] as String;

    final rows = await banco.rawQuery(
      '''SELECT CAST(julianday('now', 'localtime') - julianday(MAX(criado_em), 'localtime') AS INTEGER) AS dias
         FROM eventos WHERE tema = ?''',
      [nomeTema],
    );
    final dias = rows.first['dias'] as int?;
    if (dias == null) return HumorBichinho.dormindo; // nunca estudou

    final diasFome = await _config.getValorInt('bichinho_dias_fome', padrao: 2);
    final diasDormindo = await _config.getValorInt('bichinho_dias_dormindo', padrao: 7);

    if (dias >= diasDormindo) return HumorBichinho.dormindo;
    if (dias >= diasFome) return HumorBichinho.comFome;
    if (dias >= 1) return HumorBichinho.neutro;
    return HumorBichinho.feliz;
  }

  Future<double> _multiplicadorStreak() async {
    final banco = await _db.banco;
    final rows = await banco.query('perfil', limit: 1);
    final streak = rows.isEmpty ? 0 : (rows.first['streak_atual'] as int? ?? 0);
    if (streak <= 0) return 1.0;
    final config = await _config.getConfig('bichinho_streak_multiplicador');
    return double.tryParse(config?.valor ?? '1.5') ?? 1.5;
  }

  Future<int> _estagioPara(int energia) async {
    var estagio = 0;
    for (var i = 1; i <= 4; i++) {
      final t = await _config.getValorInt('bichinho_threshold_$i');
      if (energia >= t) estagio = i;
    }
    return estagio;
  }
}
```

**Nota:** verificar o nome real do campo `valor` no model `Config` (`lib/models/config.dart`) e ajustar `config?.valor` se necessário.

- [ ] **Step 5: Rodar testes**

Run: `flutter test test/repositories/bichinho_repository_test.dart`
Expected: PASS (6 testes). Se o seed de `perfil`/`temas` divergir, ajustar o helper do teste consultando `migration_v1.dart`.

- [ ] **Step 6: Commit**

```bash
git add lib/models/bichinho.dart lib/repositories/bichinho_repository.dart test/repositories/bichinho_repository_test.dart
git commit -m "feat(bichinho): repository com energia, evolução por threshold e humor"
```

---

## Task 6: AudioService (sons + haptics + toggles)

**Files:**
- Create: `lib/services/audio_service.dart`
- Test: `test/services/audio_service_test.dart`

- [ ] **Step 1: Escrever teste dos toggles**

```dart
// test/services/audio_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/services/audio_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('toggles default ligados e persistem', () async {
    final audio = AudioService();
    await audio.carregarPreferencias();
    expect(audio.somAtivo, isTrue);
    expect(audio.hapticsAtivo, isTrue);

    await audio.setSomAtivo(false);
    expect(audio.somAtivo, isFalse);

    // nova instância relê do config
    final audio2 = AudioService();
    await audio2.carregarPreferencias();
    expect(audio2.somAtivo, isFalse);
    expect(audio2.hapticsAtivo, isTrue);
  });
}
```

- [ ] **Step 2: Rodar, ver falhar**

Run: `flutter test test/services/audio_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/services/audio_service.dart
// Sons de papel/pixel + haptics, com toggles persistidos em config.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../repositories/config_repository.dart';
import 'metrica_service.dart';

enum Som {
  papelVirar('papel_virar.mp3'),
  papelRecorte('papel_recorte.mp3'),
  carimbo('carimbo.mp3'),
  papelAmassar('papel_amassar.mp3'),
  pixelComer('pixel_comer.mp3'),
  pixelEvolucao('pixel_evolucao.mp3'),
  fanfarra('fanfarra.mp3'),
  confete('confete.mp3');

  final String arquivo;
  const Som(this.arquivo);
}

enum Vibracao { leve, media, pesada, selecao }

class AudioService {
  final ConfigRepository _config;
  final MetricaService _metrica;
  final AudioPlayer _player = AudioPlayer();

  bool _somAtivo = true;
  bool _hapticsAtivo = true;

  AudioService({ConfigRepository? config, MetricaService? metrica})
      : _config = config ?? ConfigRepository(),
        _metrica = metrica ?? MetricaService();

  bool get somAtivo => _somAtivo;
  bool get hapticsAtivo => _hapticsAtivo;

  Future<void> carregarPreferencias() async {
    _somAtivo = await _config.getValorInt('som_ativo', padrao: 1) == 1;
    _hapticsAtivo = await _config.getValorInt('haptics_ativo', padrao: 1) == 1;
  }

  Future<void> setSomAtivo(bool ativo) async {
    _somAtivo = ativo;
    await _config.setConfig('som_ativo', ativo ? '1' : '0');
    await _metrica.registrar('som_toggled', valor: ativo ? 'on' : 'off');
  }

  Future<void> setHapticsAtivo(bool ativo) async {
    _hapticsAtivo = ativo;
    await _config.setConfig('haptics_ativo', ativo ? '1' : '0');
    await _metrica.registrar('haptics_toggled', valor: ativo ? 'on' : 'off');
  }

  Future<void> tocar(Som som) async {
    if (!_somAtivo) return;
    try {
      await _player.play(AssetSource('sounds/${som.arquivo}'));
    } catch (_) {
      // som ausente/erro de player nunca quebra o app
    }
  }

  void vibrar(Vibracao v) {
    if (!_hapticsAtivo) return;
    switch (v) {
      case Vibracao.leve:
        HapticFeedback.lightImpact();
      case Vibracao.media:
        HapticFeedback.mediumImpact();
      case Vibracao.pesada:
        HapticFeedback.heavyImpact();
      case Vibracao.selecao:
        HapticFeedback.selectionClick();
    }
  }
}
```

**Nota:** conferir a assinatura real de `MetricaService.registrar` em `lib/services/metrica_service.dart` e adaptar a chamada (nome do método/parâmetros) ao padrão existente.

- [ ] **Step 4: Rodar teste**

Run: `flutter test test/services/audio_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Prover AudioService no app**

Em `lib/app.dart`, adicionar `Provider<AudioService>` no topo da árvore (junto dos providers existentes), instanciando e chamando `carregarPreferencias()` no boot (ex: `AudioService()..carregarPreferencias()`).

- [ ] **Step 6: Commit**

```bash
git add lib/services/audio_service.dart test/services/audio_service_test.dart lib/app.dart
git commit -m "feat(audio): AudioService com sons, haptics e toggles persistidos"
```

---

## Task 7: Sons placeholder gerados proceduralmente

**Files:**
- Create: `tool/gerar_sons.dart`
- Create: `assets/sounds/*.wav` (8 arquivos gerados) — ajustar enum pra `.wav`

- [ ] **Step 1: Escrever gerador de WAV**

Criar `tool/gerar_sons.dart` — script Dart standalone que sintetiza 8 sons curtos (PCM 16-bit mono 22050Hz) e grava WAVs:

```dart
// tool/gerar_sons.dart
// Gera sons placeholder (substituíveis por CC0 curados depois).
// Rodar: dart run tool/gerar_sons.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;

Uint8List _wav(List<double> amostras) {
  final dados = Int16List(amostras.length);
  for (var i = 0; i < amostras.length; i++) {
    dados[i] = (amostras[i].clamp(-1.0, 1.0) * 32767).round();
  }
  final bytes = dados.buffer.asUint8List();
  final header = BytesBuilder();
  void str(String s) => header.add(s.codeUnits);
  void u32(int v) => header.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => header.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  str('RIFF'); u32(36 + bytes.length); str('WAVE');
  str('fmt '); u32(16); u16(1); u16(1); u32(sampleRate); u32(sampleRate * 2); u16(2); u16(16);
  str('data'); u32(bytes.length);
  header.add(bytes);
  return header.toBytes();
}

List<double> _ruido(double dur, {double decaimento = 12}) {
  final r = Random(7);
  final n = (dur * sampleRate).round();
  return List.generate(n, (i) {
    final t = i / sampleRate;
    return (r.nextDouble() * 2 - 1) * exp(-decaimento * t) * 0.5;
  });
}

List<double> _quadrada(List<(double, double)> notas, {double vol = 0.3}) {
  final out = <double>[];
  for (final (freq, dur) in notas) {
    final n = (dur * sampleRate).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out.add((sin(2 * pi * freq * t) > 0 ? 1 : -1) * vol * exp(-3 * t));
    }
  }
  return out;
}

void main() {
  final dir = Directory('assets/sounds')..createSync(recursive: true);
  final sons = <String, List<double>>{
    'papel_virar.wav': _ruido(0.15, decaimento: 20),
    'papel_recorte.wav': _ruido(0.25, decaimento: 10),
    'carimbo.wav': _ruido(0.12, decaimento: 30) + _quadrada([(90, 0.1)], vol: 0.5),
    'papel_amassar.wav': _ruido(0.3, decaimento: 6),
    'pixel_comer.wav': _quadrada([(660, 0.06), (880, 0.06)]),
    'pixel_evolucao.wav': _quadrada([(523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.25)]),
    'fanfarra.wav': _quadrada([(523, 0.12), (523, 0.08), (659, 0.12), (784, 0.3)]),
    'confete.wav': _quadrada([(1319, 0.05), (1568, 0.05), (2093, 0.1)], vol: 0.2),
  };
  sons.forEach((nome, amostras) {
    File('${dir.path}/$nome').writeAsBytesSync(_wav(amostras));
    stdout.writeln('gerado $nome');
  });
}
```

- [ ] **Step 2: Rodar gerador**

Run: `dart run tool/gerar_sons.dart`
Expected: 8 linhas `gerado *.wav`, arquivos em `assets/sounds/`.

- [ ] **Step 3: Atualizar enum Som pra .wav**

Em `lib/services/audio_service.dart`, trocar todas as extensões `.mp3` → `.wav` no enum `Som`.

- [ ] **Step 4: Testes + analyze**

Run: `flutter test test/services/ && flutter analyze`
Expected: PASS, 0 erros.

- [ ] **Step 5: Commit**

```bash
git add tool/gerar_sons.dart assets/sounds/ lib/services/audio_service.dart
git commit -m "feat(audio): sons placeholder sintetizados (papel + pixel 8-bit)"
```

---

## Task 8: Integração de energia nos controllers + métricas

**Files:**
- Modify: `lib/controllers/flashcard_controller.dart`
- Modify: `lib/controllers/quiz_controller.dart`
- Modify: `lib/controllers/desafio_controller.dart`
- Modify: `lib/controllers/revisao_controller.dart`
- Modify: `lib/controllers/maratona_controller.dart`
- Modify: `lib/services/metrica_service.dart`
- Test: `test/repositories/bichinho_integracao_test.dart`

- [ ] **Step 1: Adicionar eventos no MetricaService**

Seguindo o padrão dos métodos existentes (ver `desafioIniciado()` etc.), adicionar:

```dart
  Future<void> bichinhoNasceu(String tema, int especie) =>
      _registrar('bichinho_nasceu', tema: tema, valor: '$especie');

  Future<void> bichinhoAlimentado(String tema, int energiaGanha, int energiaTotal) =>
      _registrar('bichinho_alimentado', tema: tema, valor: '$energiaGanha',
          metadata: '{"energia_total": $energiaTotal}');

  Future<void> bichinhoEvoluiu(String tema, int estagioNovo) =>
      _registrar('bichinho_evoluiu', tema: tema, valor: '$estagioNovo');

  Future<void> bichinhoPopupAberto(String tema, int estagio) =>
      _registrar('bichinho_popup_aberto', tema: tema, valor: '$estagio');
```

(Adaptar nome/assinatura do método interno `_registrar` ao que o arquivo já usa.)

- [ ] **Step 2: Escrever teste de integração (energia por atividade)**

```dart
// test/repositories/bichinho_integracao_test.dart
// Confere que os valores de energia por atividade vêm da config.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/repositories/config_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('energias por atividade seedadas: card=2, quiz=15, modo=10', () async {
    final config = ConfigRepository();
    expect(await config.getValorInt('bichinho_energia_card'), 2);
    expect(await config.getValorInt('bichinho_energia_quiz'), 15);
    expect(await config.getValorInt('bichinho_energia_modo'), 10);
  });
}
```

Run: `flutter test test/repositories/bichinho_integracao_test.dart`
Expected: PASS (config já seedada na Task 3 — este teste protege regressão).

- [ ] **Step 3: Plugar alimentar() nos controllers**

Em cada controller, injetar `BichinhoRepository` e `ConfigRepository` (seguir padrão de injeção existente — parâmetro opcional no construtor com default). Adicionar campo público `ResultadoAlimentar? ultimoAlimentar` para a UI ler e disparar animação de evolução.

**flashcard_controller.dart** — no método que registra avaliação do card (localizar método que chama `salvarProgresso`), após persistir:

```dart
    final energia = await _configRepo.getValorInt('bichinho_energia_card', padrao: 2);
    ultimoAlimentar = await _bichinhoRepo.alimentar(temaId, energia);
    await _metrica.bichinhoAlimentado(nomeTema, ultimoAlimentar!.energiaGanha, ultimoAlimentar!.bichinho.energia);
    if (ultimoAlimentar!.evoluiu) {
      await _metrica.bichinhoEvoluiu(nomeTema, ultimoAlimentar!.bichinho.estagio);
    }
```

**quiz_controller.dart** — ao concluir o quiz (método que grava `quiz_tentativas` concluída): mesmo bloco com `bichinho_energia_quiz` (padrao: 15).

**desafio_controller.dart / revisao_controller.dart / maratona_controller.dart** — ao concluir a tentativa (métodos `concluirTentativa`/equivalentes): mesmo bloco com `bichinho_energia_modo` (padrao: 10).

**Atenção:** o controller precisa ter acesso ao `temaId` e ao nome do tema — todos já recebem `temaId` por construtor/rota (conferir e usar o que existe). Se o nome do tema não estiver disponível, buscar 1x no `carregar()` via repository existente de temas.

- [ ] **Step 4: Rodar suite inteira**

Run: `flutter test`
Expected: PASS todos (39 antigos + novos). Ajustar mocks/injeções nos testes de controller existentes se construtores mudaram (passar repositories default).

- [ ] **Step 5: Analyze e commit**

Run: `flutter analyze`
Expected: 0 erros.

```bash
git add lib/controllers/ lib/services/metrica_service.dart test/repositories/bichinho_integracao_test.dart
git commit -m "feat(bichinho): energia plugada em flashcard, quiz e modos + métricas"
```

---

## Task 9: BichinhoWidget, popup e animação de evolução

**Files:**
- Create: `lib/widgets/bichinho/bichinho_widget.dart`
- Create: `lib/widgets/bichinho/bichinho_popup.dart`
- Create: `lib/widgets/bichinho/evolucao_overlay.dart`
- Create: `lib/widgets/confete/confete_papel.dart`
- Test: `test/widgets/bichinho_widget_test.dart`

- [ ] **Step 1: Teste de widget**

```dart
// test/widgets/bichinho_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/models/bichinho.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_widget.dart';
import 'package:flashquiz/widgets/bichinho/bichinho_sprite.dart';

void main() {
  testWidgets('BichinhoHeader mostra estágio e barra de energia', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 1, energia: 80);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BichinhoHeader(
          bichinho: b,
          humor: HumorBichinho.feliz,
          proximoThreshold: 200,
        ),
      ),
    ));
    expect(find.text('Filhote'), findsOneWidget);
    expect(find.text('80/200'), findsOneWidget);
  });

  testWidgets('BichinhoHeader lendário não mostra barra', (tester) async {
    const b = Bichinho(id: 1, temaId: 1, especie: 0, estagio: 4, energia: 1500);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BichinhoHeader(bichinho: b, humor: HumorBichinho.feliz, proximoThreshold: null),
      ),
    ));
    expect(find.text('Lendário'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar, ver falhar**

Run: `flutter test test/widgets/bichinho_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar BichinhoHeader + mini**

```dart
// lib/widgets/bichinho/bichinho_widget.dart
// BichinhoMini (linha do tema na Home) e BichinhoHeader (topo da tela do tema).
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

class BichinhoMini extends StatelessWidget {
  final Bichinho bichinho;
  final HumorBichinho humor;
  const BichinhoMini({super.key, required this.bichinho, required this.humor});

  @override
  Widget build(BuildContext context) {
    return BichinhoSprite(
      temaId: bichinho.temaId,
      estagio: bichinho.estagio,
      humor: humor,
      tamanho: 28,
    );
  }
}

class BichinhoHeader extends StatelessWidget {
  final Bichinho bichinho;
  final HumorBichinho humor;
  final int? proximoThreshold; // null = lendário
  final VoidCallback? onTap;

  const BichinhoHeader({
    super.key,
    required this.bichinho,
    required this.humor,
    required this.proximoThreshold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progresso = proximoThreshold == null
        ? 1.0
        : (bichinho.energia / proximoThreshold!).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          BichinhoSprite(
            temaId: bichinho.temaId,
            estagio: bichinho.estagio,
            humor: humor,
            tamanho: 72,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bichinho.nomeEstagio, style: AppTheme.pixel(fontSize: 20)),
                const SizedBox(height: 4),
                if (proximoThreshold != null) ...[
                  // Barra de energia estilo pixel
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.tinta, width: 2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: Container(color: AppColors.verde),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${bichinho.energia}/$proximoThreshold',
                      style: AppTheme.pixel(fontSize: 14, color: AppColors.tintaSuave)),
                ] else
                  Text('★ máximo!', style: AppTheme.pixel(fontSize: 14, color: AppColors.amarelo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar popup (bottom sheet de papel)**

```dart
// lib/widgets/bichinho/bichinho_popup.dart
// Bottom sheet com sprite grande, estágio, energia, humor e dica.
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

Future<void> mostrarBichinhoPopup(
  BuildContext context, {
  required Bichinho bichinho,
  required HumorBichinho humor,
  required int? proximoThreshold,
}) {
  final dicas = {
    HumorBichinho.feliz: 'Tá feliz! Continue assim.',
    HumorBichinho.neutro: 'Estude hoje pra deixar ele feliz!',
    HumorBichinho.comFome: 'Tá com fome! Alimente com 3 cards.',
    HumorBichinho.dormindo: 'Dormiu de tédio... acorde ele estudando!',
  };

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.papel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BichinhoSprite(
            temaId: bichinho.temaId,
            estagio: bichinho.estagio,
            humor: humor,
            tamanho: 128,
          ),
          const SizedBox(height: 12),
          Text(bichinho.nomeEstagio, style: AppTheme.pixel(fontSize: 28)),
          if (proximoThreshold != null)
            Text('${bichinho.energia}/$proximoThreshold energia',
                style: AppTheme.pixel(fontSize: 18, color: AppColors.tintaSuave)),
          const SizedBox(height: 8),
          Text(dicas[humor]!, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 5: Implementar overlay de evolução e confete**

```dart
// lib/widgets/bichinho/evolucao_overlay.dart
// Animação de evolução: sprite antigo treme → flash branco → sprite novo salta.
import 'package:flutter/material.dart';
import '../../models/bichinho.dart';
import '../../theme/app_theme.dart';
import 'bichinho_sprite.dart';

Future<void> mostrarEvolucao(BuildContext context, Bichinho evoluido) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) => _EvolucaoDialog(bichinho: evoluido),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _EvolucaoDialog extends StatefulWidget {
  final Bichinho bichinho;
  const _EvolucaoDialog({required this.bichinho});

  @override
  State<_EvolucaoDialog> createState() => _EvolucaoDialogState();
}

class _EvolucaoDialogState extends State<_EvolucaoDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // fases: 0-0.4 sprite antigo tremendo, 0.4-0.6 flash, 0.6-1.0 sprite novo saltando
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    // fecha sozinho depois de 2.6s
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            if (t < 0.4) {
              // sprite ANTIGO tremendo (estágio - 1)
              final shake = (t * 60).floor() % 2 == 0 ? 2.0 : -2.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: BichinhoSprite(
                  temaId: widget.bichinho.temaId,
                  estagio: widget.bichinho.estagio - 1,
                  tamanho: 128,
                  animado: false,
                ),
              );
            }
            if (t < 0.6) {
              return Container(width: 160, height: 160, color: Colors.white);
            }
            // sprite novo salta (scale elástico) + texto
            final salto = Curves.elasticOut.transform((t - 0.6) / 0.4);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.5 + salto * 0.5,
                  child: BichinhoSprite(
                    temaId: widget.bichinho.temaId,
                    estagio: widget.bichinho.estagio,
                    tamanho: 128,
                    animado: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text('EVOLUIU!', style: AppTheme.pixel(fontSize: 32, color: AppColors.amarelo)),
                Text(widget.bichinho.nomeEstagio,
                    style: AppTheme.pixel(fontSize: 22, color: Colors.white)),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/confete/confete_papel.dart
// Confete de papel picado — retângulos coloridos caindo com rotação.
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ConfetePapel extends StatefulWidget {
  final int particulas;
  const ConfetePapel({super.key, this.particulas = 24});

  @override
  State<ConfetePapel> createState() => _ConfetePapelState();
}

class _ConfetePapelState extends State<ConfetePapel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particula> _parts;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final cores = [AppColors.laranja, AppColors.verde, AppColors.amarelo, AppColors.azul, AppColors.rosa];
    _parts = List.generate(widget.particulas, (i) => _Particula(
          x: r.nextDouble(),
          velY: 0.5 + r.nextDouble() * 0.8,
          fase: r.nextDouble() * 2 * pi,
          cor: cores[i % cores.length],
        ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfetePainter(_parts, _ctrl.value),
        ),
      ),
    );
  }
}

class _Particula {
  final double x, velY, fase;
  final Color cor;
  _Particula({required this.x, required this.velY, required this.fase, required this.cor});
}

class _ConfetePainter extends CustomPainter {
  final List<_Particula> parts;
  final double t;
  _ConfetePainter(this.parts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final y = t * p.velY * size.height;
      if (y > size.height) continue;
      final x = p.x * size.width + sin(t * 6 + p.fase) * 20;
      paint.color = p.cor.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + p.fase);
      canvas.drawRect(const Rect.fromLTWH(-4, -6, 8, 12), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetePainter old) => old.t != t;
}
```

- [ ] **Step 6: Rodar testes**

Run: `flutter test test/widgets/bichinho_widget_test.dart && flutter analyze`
Expected: PASS, 0 erros.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/bichinho/ lib/widgets/confete/ test/widgets/bichinho_widget_test.dart
git commit -m "feat(bichinho): header, mini, popup, overlay de evolução e confete"
```

---

## Task 10: Home reestilizada + bichinho na linha do tema

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/widgets/tema_card_widget.dart`
- Modify: `lib/widgets/streak_card.dart`
- Modify: `lib/widgets/xp_bar_widget.dart`
- Modify: `lib/controllers/home_controller.dart`

- [ ] **Step 1: HomeController carrega bichinhos**

Injetar `BichinhoRepository` (padrão opcional no construtor). No `carregar()`, após carregar temas:

```dart
    _bichinhos = {};
    _humores = {};
    for (final tema in _temas) {
      final criacao = await _bichinhoRepo.obterOuCriar(tema.id);
      _bichinhos[tema.id] = criacao.bichinho;
      _humores[tema.id] = await _bichinhoRepo.humor(tema.id);
      if (criacao.criado) {
        await _metrica.bichinhoNasceu(tema.nome, criacao.bichinho.especie);
      }
    }
```

Expor `Map<int, Bichinho> get bichinhos` e `Map<int, HumorBichinho> get humores`.

- [ ] **Step 2: Reescrever TemaCardWidget como recorte de papel**

`lib/widgets/tema_card_widget.dart` — manter API (`tema`, `onTap`) e ADICIONAR parâmetros opcionais `bichinho`/`humor`:

```dart
// lib/widgets/tema_card_widget.dart
// Tema como recorte de papel: PapelCard torto + emoji grande + bichinho na linha.
import 'package:flutter/material.dart';
import '../models/bichinho.dart';
import '../models/tema.dart';
import '../theme/app_theme.dart';
import 'bichinho/bichinho_sprite.dart';
import 'bichinho/bichinho_widget.dart';
import 'papel/papel_card.dart';

class TemaCardWidget extends StatelessWidget {
  final Tema tema;
  final VoidCallback onTap;
  final Bichinho? bichinho;
  final HumorBichinho? humor;

  const TemaCardWidget({
    super.key,
    required this.tema,
    required this.onTap,
    this.bichinho,
    this.humor,
  });

  @override
  Widget build(BuildContext context) {
    final acento = AppColors.accentFor(tema.id);
    return GestureDetector(
      onTap: onTap,
      child: PapelCard(
        seed: tema.id,
        child: Row(
          children: [
            Text(tema.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tema.nome, style: Theme.of(context).textTheme.titleLarge),
                  Container(height: 3, width: 48, color: acento), // sublinhado de marca-texto
                ],
              ),
            ),
            if (bichinho != null && humor != null)
              BichinhoMini(bichinho: bichinho!, humor: humor!),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.tintaSuave),
          ],
        ),
      ),
    );
  }
}
```

(Conferir campos reais do model `Tema` — `emoji`/`nome` — e ajustar.)

- [ ] **Step 3: Reestilizar HomeScreen, StreakCard e XpBarWidget**

`home_screen.dart`:
- Trocar `backgroundColor: AppColors.background` → envolver body em `FundoPapel`
- Header: "Olá, / Carlos 👋" com `Theme.of(context).textTheme.headlineMedium` (Patrick Hand), cores `AppColors.tintaSuave`/`AppColors.tinta`
- Badge XP: `PostIt` pequeno com `'⚡ ${_formatXP(...)} XP'` em `AppColors.tinta`
- Label `SEUS TEMAS`: cor `AppColors.tintaSuave`
- Passar `bichinho: ctrl.bichinhos[tema.id], humor: ctrl.humores[tema.id]` pro `TemaCardWidget`
- `CircularProgressIndicator(color: AppColors.laranja)`
- Entrada em cascata dos cards de tema: envolver cada item em `TweenAnimationBuilder<double>` (opacity 0→1 + translateY 12→0, duração 250ms, delay `index * 40ms` via `Future.delayed` num `StatefulWidget` wrapper `EntradaCascata(index: i, child: ...)` criado em `lib/widgets/papel/entrada_cascata.dart` — reutilizável nas outras listas do app)

`streak_card.dart`: reescrever como `PostIt` laranja-claro com 🔥 e contagem, mantendo API `StreakCard(streak: int)`.

`xp_bar_widget.dart`: barra com borda `AppColors.tinta` 2px, preenchimento `AppColors.amarelo`, texto Nunito `AppColors.tinta` — mesma API.

- [ ] **Step 4: Verificação visual + testes**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 erros.
Run: `flutter run -d windows` (ou device disponível) — conferir Home: fundo papel, cards tortos, ovos nas linhas dos temas.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/ lib/widgets/ lib/controllers/home_controller.dart lib/models/bichinho.dart lib/repositories/bichinho_repository.dart test/
git commit -m "feat(home): visual Recorte & Cola + bichinho na linha do tema"
```

---

## Task 11: SecoesScreen reestilizada + BichinhoHeader

**Files:**
- Modify: `lib/screens/secoes/secoes_screen.dart`
- Modify: `lib/controllers/secoes_controller.dart`

- [ ] **Step 1: SecoesController expõe bichinho**

Injetar `BichinhoRepository`. No `carregar()`:

```dart
    final criacao = await _bichinhoRepo.obterOuCriar(temaId);
    bichinho = criacao.bichinho;
    humorBichinho = await _bichinhoRepo.humor(temaId);
    proximoThreshold = await _bichinhoRepo.proximoThreshold(bichinho!.estagio);
```

Campos públicos: `Bichinho? bichinho`, `HumorBichinho humorBichinho`, `int? proximoThreshold`.

- [ ] **Step 2: Reestilizar tela**

- Envolver em `FundoPapel`
- Topo: `BichinhoHeader(bichinho: ..., humor: ..., proximoThreshold: ..., onTap: () { metrica.bichinhoPopupAberto(...); mostrarBichinhoPopup(context, ...); })`
- Cards de seção → `PapelCard(seed: secao.id, ...)`
- Bloco "Modos de estudo": cada modo vira `PostIt` (Desafio amarelo, Revisão azul-claro `Color(0xFFB8E0F5)`, Maratona verde-claro `Color(0xFFC8E6C9)`), com título Patrick Hand + subtítulo Nunito e mesmos handlers/estados de hoje (`✓ Feito hoje`, contagem de vencidos, recorde)
- Progresso da seção: barra fina com borda tinta + preenchimento acento do tema
- Após retornar de modo com `ultimoAlimentar?.evoluiu == true` no controller do modo — a evolução dispara na TELA DO MODO (Task 13/14), não aqui. Aqui apenas recarrega via `didPopNext()` já existente.

- [ ] **Step 3: Testes + verificação**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 erros. Verificar visual: bichinho no topo com barra de energia, post-its dos modos.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/secoes/ lib/controllers/secoes_controller.dart
git commit -m "feat(secoes): visual papel + BichinhoHeader com barra de energia"
```

---

## Task 12: TrilhaScreen — costura tracejada e selos

**Files:**
- Modify: `lib/screens/trilha/trilha_screen.dart` (e widgets internos da trilha, se separados)

- [ ] **Step 1: Reestilizar**

- `FundoPapel` no lugar do fundo navy
- Conector do zigzag: substituir linha sólida por pintura tracejada (mesma lógica do `_CosturaPainter` — extrair helper se preciso, cor `AppColors.grao`, tracinho 8/6)
- Nós:
  - Bloqueado: círculo/quadrado com **borda tracejada** cinza (`AppColors.grao`) + cadeado `AppColors.tintaSuave` — "rascunho não preenchido"
  - Em andamento: preenchido `AppColors.laranja`, sombra dura offset(2,2), SEM glow
  - Concluído: preenchido `AppColors.verde` com ✓ branco — "selo carimbado"
- Bottom sheets (fase/quiz): fundo `AppColors.papel`, título Patrick Hand, botão principal `BotaoPapel`
- Textos: tinta/tintaSuave

- [ ] **Step 2: Testes + verificação visual**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 erros. Verificar: trilha legível, estados distinguíveis.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/trilha/
git commit -m "feat(trilha): costura tracejada e nós como selos de papel"
```

---

## Task 13: Flashcard + Revisão reestilizados (fita, botões papel, sons)

**Files:**
- Modify: `lib/screens/flashcard/flashcard_screen.dart`
- Modify: `lib/screens/flashcard/widgets/card_face.dart`
- Modify: `lib/screens/flashcard/widgets/botao_avaliacao.dart`
- Modify: `lib/screens/revisao/revisao_screen.dart`

- [ ] **Step 1: Reestilizar CardFace**

`card_face.dart`: fundo `AppColors.cartao`, borda 4px raio, sombra dura, `Fita` posicionada no topo-centro (Stack, `Positioned(top: -10)`), texto `AppColors.tinta`. Verso: leve tom creme `Color(0xFFFFFDF7)`.

- [ ] **Step 2: BotaoAvaliacao → BotaoPapel**

Manter API (nível SRS, onPressed, habilitado). Cores: Difícil `AppColors.laranja`, Médio `AppColors.amarelo` (texto tinta), Fácil `AppColors.verde`.

- [ ] **Step 3: Sons e haptics no flip e avaliação**

Na tela (flashcard e revisão), obter `AudioService` via `context.read<AudioService>()`:
- Ao virar card: `audio.tocar(Som.papelVirar); audio.vibrar(Vibracao.leve);`
- Ao avaliar: `audio.vibrar(Vibracao.leve);`
- Se `ctrl.ultimoAlimentar?.evoluiu == true` após avaliação: `audio.tocar(Som.pixelEvolucao); audio.vibrar(Vibracao.pesada); await mostrarEvolucao(context, ctrl.ultimoAlimentar!.bichinho);`

- [ ] **Step 4: Fundo e estados das telas**

Ambas as telas: `FundoPapel`, textos tinta, loading `AppColors.laranja`. RevisaoScreen estados vazios (`tudoEmDia`, `sessaoConcluida`): `PapelCard` central com emoji + `Carimbo(texto: 'EM DIA', cor: AppColors.verde)` no estado tudoEmDia.

- [ ] **Step 5: Testes + verificação**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 erros. Verificar flip + som + botões.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/flashcard/ lib/screens/revisao/
git commit -m "feat(flashcard): visual papel com fita, sons e haptics"
```

---

## Task 14: Quiz + Desafio + Maratona reestilizados

**Files:**
- Modify: `lib/screens/quiz/quiz_screen.dart`
- Modify: `lib/screens/quiz/widgets/quiz_timer_bar.dart`
- Modify: `lib/screens/quiz/widgets/quiz_questao_card.dart`
- Modify: `lib/screens/quiz/widgets/quiz_alternativas.dart`
- Modify: `lib/screens/quiz/widgets/tempo_esgotado_banner.dart`
- Modify: `lib/screens/desafio/desafio_screen.dart`
- Modify: `lib/screens/maratona/maratona_screen.dart`

- [ ] **Step 1: Widgets compartilhados do quiz**

- `quiz_questao_card.dart`: questão em `PapelCard` (seed = índice da questão)
- `quiz_alternativas.dart`: cada alternativa = tira de papel (Container branco, borda 1px `AppColors.grao`, sombra dura 1px, raio 3px, rotação alternada ±0.5°); selecionada: borda 2px `AppColors.laranja` + fundo `Color(0xFFFFF3EE)`; desabilitada: opacity 0.5. Haptic leve no tap (`Vibracao.leve` via AudioService — passar callback ou service pela tela)
- `quiz_timer_bar.dart`: régua — fundo creme com marquinhas verticais a cada 10% (`AppColors.grao`), preenchimento `AppColors.laranja` → `AppColors.laranja` escurecida (`Color(0xFFD63A2F)`) quando < 30%; segundos em Patrick Hand
- `tempo_esgotado_banner.dart`: `PostIt` laranja-claro com texto "Tempo esgotado!"

- [ ] **Step 2: Telas**

Quiz/Desafio/Maratona screens: `FundoPapel`, headers com título Patrick Hand + acento (quiz = acento do tema, desafio = laranja, maratona = teal `Color(0xFF7FDBCA)`). Vidas da maratona: corações de papel — `Icon(Icons.favorite, color: AppColors.rosa)` vivos, `Icons.favorite_border` cor grao perdidos. `Vibracao.selecao` ao avançar questão.

- [ ] **Step 3: Testes + verificação**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 erros (testes de maratona controller intactos — só UI mudou).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/quiz/ lib/screens/desafio/desafio_screen.dart lib/screens/maratona/maratona_screen.dart
git commit -m "feat(quiz): tiras de papel, timer régua e corações de papel"
```

---

## Task 15: Telas de resultado — carimbo, confete, sons + limpeza COMPAT

**Files:**
- Modify: `lib/screens/quiz/quiz_result_screen.dart`
- Modify: `lib/screens/desafio/desafio_result_screen.dart`
- Modify: `lib/screens/maratona/maratona_result_screen.dart`
- Modify: `lib/theme/app_theme.dart` (remover aliases COMPAT)

- [ ] **Step 1: QuizResultScreen**

- `FundoPapel`, score gigante Patrick Hand
- Aprovado: `Carimbo(texto: 'APROVADO', cor: AppColors.verde, fontSize: 32)` com animação de batida — `TweenAnimationBuilder(scale 1.6→1.0, 300ms, Curves.easeOutBack)` + no fim `audio.tocar(Som.carimbo); audio.vibrar(Vibracao.media);`
- `Stack` com `ConfetePapel()` por cima quando aprovado + `audio.tocar(Som.confete)`
- 3 estrelas: `audio.tocar(Som.fanfarra); audio.vibrar(Vibracao.pesada);`
- Reprovado: sem carimbo, texto encorajador tinta, `audio.tocar(Som.papelAmassar)` (suave)
- Botões: `BotaoPapel` (Continuar verde, Refazer laranja)
- Evolução: se controller expõe `ultimoAlimentar?.evoluiu == true` → `mostrarEvolucao` + `Som.pixelEvolucao` + `Vibracao.pesada` (após o carimbo, 500ms delay)

- [ ] **Step 2: Desafio e Maratona results**

Mesma linguagem. Maratona com recorde batido: `Carimbo(texto: 'RECORDE', cor: AppColors.laranja)` + fanfarra + confete. Desafio: score + carimbo `FEITO` verde. Ambos: checagem de evolução igual ao Step 1.

- [ ] **Step 3: Remover aliases COMPAT**

Apagar o bloco `// COMPAT` do `app_theme.dart`.

Run: `flutter analyze`
Expected: erros apontam usos restantes das cores antigas → corrigir cada um pro semântico novo (`background→papel`, `purple→laranja`, `gold→amarelo`, `teal→Color(0xFF7FDBCA)` ou verde, `textSecondary→tintaSuave`, `surface→cartao`, `sheetBg→papel`, `divider→grao`). Repetir até 0 erros.

- [ ] **Step 4: Suite completa**

Run: `flutter test && flutter analyze`
Expected: PASS todos, 0 erros.

- [ ] **Step 5: Commit**

```bash
git add lib/
git commit -m "feat(resultados): carimbos, confete e sons + remove paleta antiga"
```

---

## Task 16: Docs, verificação final e regressão manual

**Files:**
- Modify: `CLAUDE.md`
- Modify: `Plano.md`

- [ ] **Step 1: Atualizar CLAUDE.md**

- Seção "Design system": substituir tabela de cores dark pela paleta Recorte & Cola (papel/cartao/tinta/tintaSuave/grao + acentos), fontes (Patrick Hand títulos, Nunito corpo, VT323 pixel), widgets de papel disponíveis em `lib/widgets/papel/`
- Nova seção "Bichinho virtual": regras (1 por tema, 5 estágios, energia por atividade, multiplicador streak, humor), tabela `bichinhos`, configs `bichinho_*`, sprites em código
- Seção sons/haptics: AudioService, toggles `som_ativo`/`haptics_ativo`

- [ ] **Step 2: Atualizar Plano.md**

- Marcar "Plano 3.75 — Recorte & Cola + Bichinho" como concluído na tabela de planos
- Em "Ideias Futuras" adicionar: galeria/coleção de bichinhos, espécies raras, acessórios do bichinho, dark mode papel kraft, copy com personalidade

- [ ] **Step 3: Verificação final**

Run: `flutter test && flutter analyze`
Expected: PASS todos, 0 erros.

Regressão manual (`flutter run`):
1. Home: fundo papel, temas tortos com ovo na linha, streak post-it
2. Abrir tema → BichinhoHeader com ovo + barra 0/50
3. Estudar 1 fase de flashcards → sons de papel, energia sobe
4. Fechar quiz com ≥70 → carimbo APROVADO + confete + energia
5. Cruzar 50 de energia → animação EVOLUIU! + jingle
6. Desafio/Revisão/Maratona funcionam com visual novo
7. Toggle de som desliga sons

- [ ] **Step 4: Commit final**

```bash
git add CLAUDE.md Plano.md
git commit -m "docs: Plano 3.75 Recorte & Cola + bichinho concluído"
```
