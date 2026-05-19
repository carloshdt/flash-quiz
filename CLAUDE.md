# CLAUDE.md — FlashQuiz

> Lido no início de cada sessão. Prioridade máxima — nunca ignorar.
> Para visão do produto, roadmap e detalhes de implementação: ver `Plano.md`.

---

## 1. REGRAS DE NEGÓCIO

### Quiz
- Pontuação por questão: acertou rápido (< metade do tempo) = **10 pts** | acertou devagar = **7 pts** | errou ou estourou = **0 pts**
- Estrelas por fase:
  ```
  0  – 69  → Reprovado (não desbloqueia próxima fase)
  70 – 79  → ⭐
  80 – 89  → ⭐⭐
  90 – 100 → ⭐⭐⭐
  ```
- Nota mínima pra desbloquear próxima fase: **70**
- Questões re-sorteadas a cada tentativa (não memoriza posição)
- Saiu no meio = tentativa abandonada — registrar em qual questão saiu

### Flashcard / SRS
- 3 níveis de avaliação após virar o card:
  - **Difícil** → revisão no mesmo dia (intervalo 0)
  - **Médio** → revisão em +1 dia
  - **Fácil** → revisão em +3 dias
- Sessão interrompida = recomeça do zero com cards re-sorteados
- % mínimo de cards vistos pra liberar quiz da fase: **60%** (configurável em `config`)

### Progressão
- Usuário avança fase por fase dentro de cada seção
- Desbloqueio: passar no quiz da fase anterior com nota ≥ 70
- Pode refazer quiz quantas vezes quiser pra melhorar estrelas
- Progresso de seção = SUM(melhor pontuação por fase) ÷ (total_fases × 100)

### Gamificação
- XP por card: Fácil = 10 | Médio = 7 | Difícil = 3
- XP por estrela de quiz: 50
- Streak: incrementa se estudou hoje, reseta se passou um dia sem estudar
- Todos os valores numéricos ficam na tabela `config` — nunca hardcodar

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
