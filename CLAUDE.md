# CLAUDE.md — FlashQuiz (Projeto Flutter)

> Regras específicas do projeto Flutter. Leia também o CLAUDE.md da raiz do workspace.

---

## Stack

- Flutter 3.x + Dart
- sqflite (banco local) + path
- provider (estado) + go_router (navegação)
- intl (formatação)
- sqflite_common_ffi (testes)

## Arquitetura — 3 camadas obrigatórias

```
UI (screens/widgets)
    ↕ nunca acessa banco diretamente
Controllers (ChangeNotifier via Provider)
    ↕ nunca acessa banco diretamente
Repositories → DatabaseHelper → SQLite
```

- UI só fala com controllers via `context.watch` / `context.read`
- Controllers só falam com repositories e services
- Queries SQL **nunca** aparecem em controllers ou screens

## Nomenclatura

- Arquivos: `snake_case.dart`
- Classes: `PascalCase`
- Variáveis/métodos: `camelCase`
- Colunas SQLite → campos Dart: `fase_id` → `faseId`
- Comentários: **sempre em português**

## Navegação

- GoRouter, sem bottom navigation bar
- Navegação hierárquica: `context.push()` / `context.pop()`
- Rotas definidas em `lib/app.dart`

## Cores (dark theme)

```dart
// Fundo principal
Color(0xFF12122A)
// Cards/containers
Color(0xFF0F3460)
// Roxo primário (ação, progresso)
Color(0xFF7C4DFF)
// Laranja (streak, nó atual)
Color(0xFFFF6F00)
// Teal (quiz concluído)
Color(0xFF00897B)
// Azul claro (texto secundário)
Color(0xFF90CAF9)
// Azul escuro (header)
Color(0xFF1565C0)
```

## Gamificação

- Sistema de **5 estrelas** (não 3)
- Pontuação quiz: 0–100 pontos
- Nota mínima pra desbloquear próxima fase: **70**
- Todos os parâmetros numéricos ficam na tabela `config` — nada hardcoded

## Regras gerais

- App 100% offline — nunca assumir internet disponível
- Animações simples OK — nada frame a frame pesado
- Pensar em celulares de baixo processamento
- Estrutura preparada pra monetização futura (campo `is_premium` no perfil, config de tentativas)
