# CLAUDE.md — FlashQuiz

> Lido no início de cada sessão. Prioridade máxima — nunca ignorar.
> Para visão do produto, roadmap e detalhes de implementação: ver `Plano.md`.

---

## 1. REGRAS DE NEGÓCIO

### Fluxo principal
```
HomeScreen
  └─ tap tema → SecoesScreen (lista seções + progresso geral do tema)
       └─ tap seção → TrilhaScreen (trilha ziguezague)
            ├─ tap nó FASE → BottomSheetFase → FlashcardScreen
            └─ tap nó QUIZ → BottomSheetQuiz → QuizScreen → QuizResultScreen
```

### Telas implementadas
| Tela | Arquivo | Status |
|------|---------|--------|
| HomeScreen | `screens/home/home_screen.dart` | ✅ |
| SecoesScreen | `screens/secoes/secoes_screen.dart` | ✅ |
| TrilhaScreen | `screens/trilha/trilha_screen.dart` | ✅ |
| FlashcardScreen | `screens/flashcard/flashcard_screen.dart` | ✅ |
| QuizScreen | `screens/quiz/quiz_screen.dart` | ⏳ Plano 3 |
| QuizResultScreen | `screens/quiz/quiz_result_screen.dart` | ⏳ Plano 3 |
| PerfilScreen | `screens/perfil/perfil_screen.dart` | ⏳ Plano 4 |

### Trilha — estados dos nós
Cada fase gera 2 nós na trilha: **nó de flashcard** (círculo) e **nó de quiz** (quadrado).

| Estado | Condição | Visual |
|--------|----------|--------|
| Bloqueado | Fase anterior não concluída | Cinza + cadeado |
| Em andamento | Desbloqueado mas não concluído | Laranja + glow |
| Concluído | Quiz com nota ≥ 70 | Roxo + ✓ verde |

- Nó de quiz só desbloqueia após ≥ 60% dos cards da fase vistos (`flashcard_min_percentual_para_quiz` em `config`)
- Primeira fase de cada seção sempre desbloqueada

### Flashcard / SRS
- Usuário vê pergunta → vira card → avalia com 3 botões: **Difícil / Médio / Fácil**
- Botões só ativam após virar o card
- Intervalos de revisão:
  - Difícil → mesmo dia (0 dias)
  - Médio → +1 dia
  - Fácil → +3 dias
- Sessão interrompida = recomeça do zero, cards re-sorteados
- Sem contador de cards visível ao usuário durante a sessão
- Progresso da fase = cards vistos únicos ÷ total cards da fase

### Quiz
- Múltipla escolha, questões sorteadas aleatoriamente a cada tentativa
- Sem feedback de acerto/erro durante o quiz — resultado só na tela final
- Timer por questão: barra muda de roxo → vermelho conforme esgota
- Transição entre questões: fade neutro ~0.3s
- Saiu no meio = tentativa abandonada (registrar questão atual nas métricas)
- Pode refazer ilimitadamente pra melhorar estrelas

**Pontuação por questão:**
- Acertou em < metade do tempo → **10 pts**
- Acertou em ≥ metade do tempo → **7 pts**
- Errou ou estourou o tempo → **0 pts**

**Estrelas (nota 0–100):**
```
0  – 69  → Reprovado — não desbloqueia próxima fase
70 – 79  → ⭐
80 – 89  → ⭐⭐
90 – 100 → ⭐⭐⭐
```

### Progressão de seção
- % da seção = SUM(melhor pontuação por fase) ÷ (total_fases × 100)
- Calculado em `SecaoRepository.getProgressoPorTema()` via `quiz_tentativas`
- Antes do quiz ser implementado: todas as seções mostram 0% (esperado)

### Gamificação
- XP por card: Fácil = 10 | Médio = 7 | Difícil = 3
- XP por estrela de quiz: 50
- Streak: incrementa se estudou hoje, reseta se passou 1 dia sem estudar
- Conquistas seed: `primeiro_tema`, `streak_7`, `cards_100`, `quiz_3estrelas`, `tema_completo`, `streak_30`
- **Todos os valores numéricos ficam na tabela `config` — nunca hardcodar**

---

## 2. METRIFICAÇÃO OBRIGATÓRIA

**Tudo que for implementado DEVE ser metrificado.** Antes de fechar qualquer tarefa, perguntar: *"Isso está sendo registrado em `eventos`?"*

### O que registrar (exemplos — não limitado a isso)
- Abertura do app, tema/seção selecionados
- Card visualizado, card avaliado (acerto/erro + nível SRS)
- Quiz iniciado, questão respondida (card_id, acertou, tempo_s, tentativa_nº)
- Quiz concluído (nota, estrelas, tempo_total, tentativa_nº)
- Quiz abandonado (questao_atual, total_questoes)
- Fase concluída / abandonada
- Streak atualizado, notificação clicada, anúncio exibido, compra realizada

### Schema da tabela `eventos`
```sql
CREATE TABLE eventos (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  evento     TEXT NOT NULL,     -- ex: "quiz_concluido", "card_avaliado"
  tema       TEXT,              -- ex: "CFC"
  secao      TEXT,              -- ex: "Placas"
  valor      TEXT,              -- ex: "acerto", "85", "3_estrelas"
  metadata   TEXT,              -- JSON com dados extras
  criado_em  DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Exemplos de metadata
```json
{ "card_id": 42, "acertou": true, "tempo_segundos": 8, "tentativa": 2 }
{ "fase_id": 3, "nota": 85, "estrelas": 2, "tempo_total_segundos": 134, "tentativa": 1 }
{ "fase_id": 3, "questao_atual": 6, "total_questoes": 10 }
```

---

## 3. STACK E ARQUITETURA

**Stack:** Flutter 3.x · sqflite · provider · go_router · App 100% offline

**3 camadas obrigatórias — nunca misturar:**
```
UI (screens/widgets)  →  Controllers (ChangeNotifier)  →  Repositories → SQLite
```
- SQL nunca aparece em controllers ou screens
- Comentários sempre em português
- Todo schema novo = migration versionada (`migration_vN.dart`) — nunca alterar migration anterior
- Toda tabela nova: campos `criado_em` e `atualizado_em`

**Cores dark theme:**
```dart
Color(0xFF12122A)  // fundo
Color(0xFF0F3460)  // cards/containers
Color(0xFF7C4DFF)  // roxo primário (ação, progresso)
Color(0xFFFF6F00)  // laranja (streak, nó atual)
Color(0xFF00897B)  // teal (quiz concluído)
Color(0xFF90CAF9)  // azul claro (texto secundário)
Color(0xFF1565C0)  // azul escuro (header)
```
