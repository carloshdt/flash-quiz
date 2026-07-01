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
| QuizScreen | `screens/quiz/quiz_screen.dart` | ✅ |
| QuizResultScreen | `screens/quiz/quiz_result_screen.dart` | ✅ |
| DesafioScreen | `screens/desafio/desafio_screen.dart` | ✅ |
| DesafioResultScreen | `screens/desafio/desafio_result_screen.dart` | ✅ |
| MaratonaScreen | `screens/maratona/maratona_screen.dart` | ✅ |
| MaratonaResultScreen | `screens/maratona/maratona_result_screen.dart` | ✅ |
| RevisaoScreen | `screens/revisao/revisao_screen.dart` | ✅ |
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
- Timer por questão: barra muda de roxo → vermelho quando resta < 30% do tempo; número de segundos ao lado
- Resposta selecionada → highlight roxo, timer para → ~1s → próxima questão (fade 0.3s)
- Timer estourado → opções desabilitam, exibe "Tempo esgotado" → usuário toca pra avançar (0 pts)
- Saiu no meio → diálogo de confirmação ("tentativa será registrada como abandonada") → Sim/Não
- Pode refazer ilimitadamente pra melhorar estrelas

**QuizResultScreen:**
- Score grande centralizado (sem breakdown por questão)
- Aprovado: estrelas + texto verde "Próxima fase desbloqueada!" + botões Continuar / Refazer
- Reprovado: estrelas apagadas + texto vermelho "Mínimo 70 para avançar" + botões Tentar novamente / Voltar para trilha

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

### Modos de estudo (por tema, entrada na SecoesScreen)
- **Desafio Diário:** 1x/dia por tema, `desafio_num_questoes` questões do pool desbloqueado, nota 0-100, não afeta progressão. Gate: `ModoRepository.notaDesafioHoje`.
- **Revisão Inteligente:** flashcards vencidos do SRS no tema (`revisao_max_cards` máx), atualiza SRS normal.
- **Maratona:** questões sem fim do pool desbloqueado, `maratona_max_erros` erros encerram, score = acertos, recorde por tema. Avança sem delay de 1s (modo arcade).
- Tentativas dos modos ficam em `modo_tentativas` (nunca em `quiz_tentativas` — essa alimenta progressão).
- Pool desbloqueado = mesma regra da trilha (primeira fase da seção OU fase anterior com quiz ≥ 70).
- SecoesScreen recarrega via `routeObserver` (app.dart) ao voltar ao topo da pilha.

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

**Design system:** `lib/theme/app_theme.dart` — usar `AppColors.*` em vez de hex direto.

**Cores dark theme (AppColors):**
```dart
AppColors.background  // Color(0xFF151C35) — fundo navy
AppColors.surface     // Color(0xFF1C2448) — cards/containers
AppColors.headerBg    // Color(0xFF1A2F6E) — header AppBar
AppColors.sheetBg     // Color(0xFF1C2040) — bottom sheets
AppColors.purple      // Color(0xFF7C4DFF) — roxo primário
AppColors.orange      // Color(0xFFFF8C00) — laranja (streak, nó atual)
AppColors.gold        // Color(0xFFFFD600) — dourado (XP badge)
AppColors.teal        // Color(0xFF00897B) — teal (quiz concluído)
AppColors.textSecondary // Color(0xFF90CAF9) — texto secundário
```

**Font:** Nunito (google_fonts) aplicado app-wide via ThemeData.textTheme.
**Acento por tema:** `AppColors.accentFor(tema.id)` — cicla palette de 8 cores.
**Cards de tema:** emoji grande, sem caixinha, border `accentFor(id).withValues(alpha: 0.22)`.
