# CLAUDE.md — lib/services/

## Regras dos Services

- Services são wrappers tipados sobre repositories
- Instanciados diretamente (sem Provider) — controllers criam suas instâncias
- Recebem repository via construtor para testabilidade

## MetricaService — OBRIGATÓRIO

**Todo evento relevante do app deve passar pelo MetricaService.**

Métodos existentes:
- `appAberto()`
- `temaSelecionado(temaId, nomeTema)`
- `secaoSelecionada(secaoId, nomeSecao, nomeTema)`
- `faseSelecionada(faseId, nomeFase, nomeTema)`
- `quizSelecionado(faseId, nomeFase, nomeTema)`

Ao implementar novos fluxos (flashcard, quiz, perfil), adicionar métodos correspondentes:
- `cardVisto(cardId, faseId, nomeTema)`
- `cardAvaliado(cardId, nivelSrs, nomeTema)` — Difícil/Médio/Fácil
- `quizIniciado(...)`, `quizConcluido(...)`, `quizAbandonado(...)`
- `streakAtualizado(diasStreak)`

Ver CLAUDE.md da raiz para lista completa de eventos que devem ser metrificados.
