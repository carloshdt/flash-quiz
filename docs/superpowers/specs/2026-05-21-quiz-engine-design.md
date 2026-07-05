# Quiz Engine — Design Spec (Plano 3)

**Data:** 2026-05-21  
**Status:** Aprovado

---

## 1. Visão Geral

Implementar `QuizScreen`, `QuizResultScreen`, `QuizController` e `QuizRepository` para permitir que o usuário faça o quiz de validação de fase. Nota mínima 70 para desbloquear próxima fase.

---

## 2. Fluxo de Navegação

```
TrilhaScreen
  └─ tap nó QUIZ → BottomSheetQuiz
       └─ botão "Iniciar Quiz" → QuizScreen (rota: /quiz/:faseId)
            ├─ conclui → QuizResultScreen (push de substituição)
            └─ abandona (diálogo) → volta para TrilhaScreen
```

- `QuizResultScreen` recebe os dados do resultado via `extra` no GoRouter (sem rota própria separada)
- Botão "Continuar" na ResultScreen faz `context.go('/trilha/...')` para atualizar estado

---

## 3. QuizScreen — Mecânica

### 3.1 Estado da questão

```
aguardando_resposta
  → (usuário toca opção) → selecionada [highlight roxo, timer para]
      → (~1s) → próxima_questao [fade 0.3s]
  → (timer esgota) → tempo_esgotado [opções desabilitam, texto "Tempo esgotado"]
      → (usuário toca tela) → próxima_questao [fade 0.3s]
```

### 3.2 Timer
- Duração: lê `quiz_tempo_por_questao` da tabela `config`
- Barra visual: roxo (`0xFF7C4DFF`) → vermelho (`0xFFFF3D00`) quando restam < 30% do tempo
- Número ao lado da barra mostra segundos restantes
- Para ao selecionar resposta; esgota → estado `tempo_esgotado`

### 3.3 Pontuação por questão
- Acertou em < metade do tempo → **10 pts**
- Acertou em ≥ metade do tempo → **7 pts**
- Errou ou estourou tempo → **0 pts**

### 3.4 Abandon
- Usuário aperta voltar → diálogo: "Deseja sair? Esta tentativa será registrada como abandonada."
  - Confirmar → registra evento `quiz_abandonado` + tentativa como abandonada → pop para TrilhaScreen
  - Cancelar → continua quiz

### 3.5 Questões
- Sorteadas aleatoriamente a cada tentativa (shuffle no início do quiz)
- Total: lê `quiz_num_questoes` da tabela `config`
- Sem feedback de acerto/erro durante — resultado só na tela final

---

## 4. QuizResultScreen — Mecânica

### 4.1 Cálculo de nota
```
nota = SUM(pontos por questão) / (total_questoes * 10) * 100
```

### 4.2 Estrelas
```
0–69   → reprovado (sem estrelas)
70–79  → ⭐
80–89  → ⭐⭐
90–100 → ⭐⭐⭐
```

### 4.3 Layout
- Score grande centralizado na tela
- Estrelas acima do número (reprovado: estrelas apagadas)
- Aprovado: texto verde "Próxima fase desbloqueada!"
- Reprovado: texto vermelho "Mínimo 70 para avançar"
- Aprovado: botões "Continuar →" + "Refazer quiz"
- Reprovado: botões "Tentar novamente" + "Voltar para trilha"

### 4.4 Melhor pontuação
- Salva apenas se a nota atual for maior que a melhor tentativa anterior
- `TrilhaController` lê `melhorTentativa` de `quiz_tentativas` para definir nó como concluído

---

## 5. Arquitetura

### 5.1 Camadas

```
QuizScreen / QuizResultScreen
        ↓
  QuizController (ChangeNotifier)
        ↓
  QuizRepository → SQLite (quiz_tentativas, quiz_respostas)
```

### 5.2 QuizController

```dart
class QuizController extends ChangeNotifier {
  // Estado
  List<Card> questoes;          // sorteadas no início
  int questaoAtual;
  int? respostaSelecionada;     // índice da alternativa
  EstadoQuestao estado;         // aguardando / selecionada / tempo_esgotado
  Timer? _timer;
  int segundosRestantes;
  List<RespostaLocal> respostas; // acumuladas durante o quiz
  int tentativaNumero;

  // Métodos principais
  void iniciar(int faseId, List<Card> todasQuestoes);
  void selecionarResposta(int indice);
  void avancarQuestao();
  Future<QuizResultado> concluir();
  Future<void> abandonar();
}
```

### 5.3 QuizRepository

```dart
class QuizRepository {
  Future<int> iniciarTentativa(int faseId, int numeroTentativa);
  Future<void> salvarResposta(int tentativaId, QuizResposta resposta);
  Future<void> concluirTentativa(int tentativaId, int pontuacao, int estrelas, int tempoTotal);
  Future<void> abandonarTentativa(int tentativaId, int questaoAtual, int totalQuestoes);
  Future<QuizTentativa?> melhorTentativa(int faseId);
  Future<int> contarTentativas(int faseId);
}
```

### 5.4 Integração TrilhaController

- `TrilhaController.carregarFases()` já chama `SecaoRepository` que usa `quiz_tentativas`
- Adicionar: `QuizRepository.melhorTentativa(faseId)` para expor `concluido` no nó de quiz
- Nó de quiz `concluido` = `melhorTentativa?.pontuacao >= 70`

---

## 6. Rota

```dart
GoRoute(
  path: '/quiz/:faseId',
  builder: (context, state) {
    final faseId = int.parse(state.pathParameters['faseId']!);
    final nomeFase = state.uri.queryParameters['nomeFase'] ?? '';
    final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
    return QuizScreen(faseId: faseId, nomeFase: nomeFase, nomeTema: nomeTema);
  },
),
```

BottomSheetQuiz dispara:
```dart
context.push('/quiz/$faseId?nomeFase=$nomeFase&nomeTema=$nomeTema');
```

---

## 7. Métricas Obrigatórias

| Evento | Quando | Metadata |
|---|---|---|
| `quiz_iniciado` | Ao montar QuizScreen | `{fase_id, tentativa_n}` |
| `quiz_questao_respondida` | A cada resposta (incluindo timeout) | `{fase_id, card_id, acertou, tempo_s, pontos, tentativa_n}` |
| `quiz_concluido` | Ao salvar resultado | `{fase_id, nota, estrelas, tempo_total_s, tentativa_n}` |
| `quiz_abandonado` | Ao confirmar saída | `{fase_id, questao_atual, total_questoes, tentativa_n}` |

---

## 8. Arquivos a Criar / Modificar

**Criar:**
- `lib/screens/quiz/quiz_screen.dart`
- `lib/screens/quiz/quiz_result_screen.dart`
- `lib/controllers/quiz_controller.dart`
- `lib/repositories/quiz_repository.dart`

**Modificar:**
- `lib/app.dart` — adicionar rota `/quiz/:faseId`
- `lib/screens/trilha/bottom_sheet_quiz.dart` — wiring do botão Iniciar
- `lib/controllers/trilha_controller.dart` — ler `melhorTentativa` para nó concluído

**Sem migration:** tabelas `quiz_tentativas` e `quiz_respostas` já existem no schema.
