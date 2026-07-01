# Design — Modos de Estudo Extras (Plano 3.5)

> Data: 2026-07-01 · Status: aprovado pelo usuário
> Escopo: Desafio Diário, Revisão Inteligente e Maratona — todos por tema.

## Contexto

Quiz de fase (Plano 3) está implementado e testado. Este sub-projeto adiciona
três modos de estudo que reaproveitam os motores existentes (quiz e flashcard)
sem tocar na progressão de fases. Entrada dos modos: bloco "Modos de estudo"
no topo da `SecoesScreen` de cada tema.

Decisões de produto tomadas:
- Modos vivem **dentro de cada tema** (não na Home).
- Simulado Completo fica fora — permanece no v1.2.
- Ideias descartadas por ora (decks do usuário, IA, viral) anotadas em
  Plano.md → Ideias Futuras.

## Regras dos modos

### ⚡ Desafio Diário
- 1x por dia por tema; reseta à meia-noite local.
- `desafio_num_questoes` (default 5) questões sorteadas das **fases já
  desbloqueadas** do tema — nunca mostra conteúdo à frente.
- Mesmo fluxo do quiz de fase: timer por questão, pontuação 10/7/0,
  sem feedback durante.
- Nota final 0–100 proporcional (soma dos pontos ÷ máximo × 100).
- **Não** afeta estrelas nem desbloqueio de fase. Registra eventos que
  alimentarão streak/XP quando o Plano 4 fizer o wiring.
- Já fez hoje → card do modo mostra "✓ Feito hoje" + nota; bloqueado até amanhã.

### 🧠 Revisão Inteligente
- Sessão de flashcards apenas com cards **vencidos** do SRS
  (`proxima_revisao <= hoje`) do tema, cruzando seções e fases desbloqueadas.
- Ordenação: mais atrasados primeiro.
- Máximo `revisao_max_cards` (default 20) por sessão.
- Avaliação Difícil/Médio/Fácil normal — atualiza SRS como sessão comum.
- Sem cards vencidos → estado vazio: "Tudo em dia! Volte mais tarde 🎉".

### 🏃 Maratona
- Questões sem fim, sorteadas do pool de fases desbloqueadas do tema.
- Sem repetição até esgotar o pool; depois re-embaralha.
- `maratona_max_erros` (default 3) erros encerram a partida.
  Timer estourado conta como erro.
- Timer por questão reusa `quiz_tempo_por_questao`.
- Score = total de acertos da partida. Recorde pessoal por tema salvo/exibido.
- Tela final: score, recorde, botão "Jogar de novo".

## Banco de dados (migration_v4)

Tabela nova — `quiz_tentativas` fica intocada (alimenta progressão; zero risco):

```sql
CREATE TABLE modo_tentativas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  modo TEXT NOT NULL,                    -- 'desafio' | 'maratona'
  tema_id INTEGER NOT NULL,
  pontuacao INTEGER NOT NULL DEFAULT 0,  -- desafio: nota 0-100 | maratona: acertos
  tempo_total_segundos INTEGER,
  concluido INTEGER DEFAULT 0,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tema_id) REFERENCES temas(id)
);
```

- Revisão Inteligente não precisa de tabela — usa `progresso_flashcard`.
- Seeds de config na v4: `desafio_num_questoes=5`, `revisao_max_cards=20`,
  `maratona_max_erros=3`.
- Gate diário do desafio: `SELECT ... WHERE modo='desafio' AND tema_id=?
  AND date(criado_em)=date('now','localtime') AND concluido=1`.
- Recorde maratona: `MAX(pontuacao) WHERE modo='maratona' AND tema_id=?
  AND concluido=1`.

## Arquitetura de código

Camadas obrigatórias mantidas: UI → Controller (ChangeNotifier) → Repository → SQLite.

```
screens/quiz/widgets/           ← extraídos do QuizScreen (compartilhados)
  quiz_timer_bar.dart
  quiz_alternativas.dart
  quiz_questao_card.dart

services/quiz_pontuacao.dart    ← helper 10/7/0 (extraído, usado por quiz/desafio)

repositories/modo_repository.dart
  - iniciarTentativa / concluirTentativa / abandonarTentativa
  - desafioFeitoHoje(temaId) → nota ou null
  - recordeMaratona(temaId)
  - cardsPoolDesbloqueado(temaId) → cards de fases desbloqueadas
  - cardsVencidos(temaId, limite) → revisão

controllers/desafio_controller.dart   → screens/desafio/desafio_screen.dart
controllers/maratona_controller.dart  → screens/maratona/maratona_screen.dart
                                        + maratona_result_screen.dart
controllers/revisao_controller.dart   → screens/revisao/revisao_screen.dart
```

- `QuizController` e `FlashcardController` atuais **não são alterados**
  (funcionam e têm testes). Widgets de UI são extraídos; controllers novos
  são finos e específicos.
- Resultado do desafio: `DesafioResultScreen` própria e simples — nota grande
  centralizada, sem estrelas, botões "Voltar ao tema" (refazer só amanhã).
- Rotas go_router: `/desafio/:temaId`, `/revisao/:temaId`, `/maratona/:temaId`.
- `SecoesScreen`: bloco "Modos de estudo" acima da lista de seções —
  3 cards (Desafio com estado feito/pendente, Revisão com contagem de
  vencidos, Maratona com recorde).

## Fluxo de dados

```
SecoesScreen (bloco modos)
  ├─ ⚡ → DesafioScreen → DesafioController → ModoRepository → modo_tentativas
  ├─ 🧠 → RevisaoScreen → RevisaoController → ModoRepository + ProgressoRepository
  └─ 🏃 → MaratonaScreen → MaratonaController → ModoRepository → modo_tentativas
```

## Tratamento de erros / casos-limite

- Tema sem fase desbloqueada com cards suficientes → desafio/maratona exibem
  estado vazio orientando estudar primeiro.
- Pool menor que `desafio_num_questoes` → usa o que houver (mínimo 1).
- Sair no meio (desafio/maratona) → diálogo de confirmação (padrão do quiz)
  → tentativa marcada `concluido=0` + evento de abandono. Desafio abandonado
  **não** conta como "feito hoje".
- Revisão interrompida → cards já avaliados mantêm atualização SRS
  (comportamento natural do motor existente).

## Metrificação (obrigatória)

| Evento | Metadata |
|---|---|
| `desafio_iniciado` | tema, num_questoes |
| `desafio_concluido` | tema, nota, tempo_total_segundos |
| `desafio_abandonado` | tema, questao_atual, total_questoes |
| `revisao_iniciada` | tema, cards_vencidos |
| `revisao_concluida` | tema, cards_revisados, tempo_total_segundos |
| `maratona_iniciada` | tema |
| `maratona_concluida` | tema, score, recorde_batido (bool), tempo_total_segundos |
| `maratona_abandonada` | tema, score_parcial |

## Testes

Seguir padrão existente (sqflite_common_ffi):
- `modo_repository_test.dart` — CRUD tentativas, gate diário (feito hoje /
  não feito / abandonado não conta), recorde maratona, pool desbloqueado,
  cards vencidos com limite.
- Controllers — pontuação do desafio, vidas/fim da maratona, sorteio sem
  repetição até esgotar pool, estado vazio da revisão.
- Migration v4 — tabela criada + seeds de config presentes.

## Fora de escopo

- XP/streak wiring completo (Plano 4 — modos apenas registram eventos).
- Simulado Completo (v1.2).
- AdMob nos modos (Plano 6).
