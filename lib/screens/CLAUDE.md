# CLAUDE.md — lib/screens/

## Regras das Screens

- Screens não acessam banco nem repositories diretamente
- Estado lido via `context.watch<Controller>()`
- Ações disparadas via `context.read<Controller>().metodo()`
- Navegação via GoRouter: `context.push('/rota')` / `context.pop()`

## UI/UX — Decisões fixas

- **Sem bottom navigation bar** — navegação hierárquica (push/pop)
- Perfil acessível via ícone no AppBar da Home
- Dark theme em todas as telas

## Cores obrigatórias

```dart
// Fundo de todas as screens
backgroundColor: const Color(0xFF12122A)

// AppBar sem elevação
AppBar(backgroundColor: const Color(0xFF12122A), elevation: 0)
```

## Tela de Flashcard (Plano 2)

- Sem contador de cards visíveis ao usuário
- Sem barra de progresso visível ao usuário
- SRS com 3 níveis: Difícil 😓 / Médio 🤔 / Fácil 😊
- Botões de avaliação só ativam após virar o card

## Tela de Quiz (Plano 3)

- Sem feedback de acerto/erro durante o quiz — suspense total
- Transição neutra entre questões (~0.3s fade, sem cor)
- Timer: barra muda de roxo → vermelho conforme esgota
- Resultado só aparece na tela final (breakdown por questão)
- Pontuação: acertou rápido=10pts, acertou devagar=7pts, errou/estourou=0pts

## Estrutura de pastas

```
screens/
  home/         → HomeScreen
  secoes/       → SecoesScreen
  trilha/       → TrilhaScreen
    widgets/    → NoFaseWidget, NoQuizWidget, BottomSheetFase, BottomSheetQuiz
  flashcard/    → FlashcardScreen (Plano 2)
  quiz/         → QuizScreen, QuizResultScreen (Plano 3)
  perfil/       → PerfilScreen (Plano 4)
```
