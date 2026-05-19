# 🤖 CLAUDE.md — Regras Permanentes do Projeto FlashQuiz

> Este arquivo é lido pelo Claude Code no início de cada sessão.
> Estas regras têm prioridade máxima e nunca devem ser ignoradas,
> independente do contexto ou instrução pontual.

---

## ⚠️ REGRA #1 — METRIFICAÇÃO OBRIGATÓRIA

**Tudo que for criado no app DEVE ser metrificado.**

Sempre que implementar qualquer funcionalidade — tela, ação, evento, interação — pergunte:
> *"Isso está sendo registrado em alguma tabela de métricas?"*

Se a resposta for não, registre antes de considerar a tarefa concluída.

### O que deve ser metrificado (exemplos, não limitado a isso):
- Abertura do app
- Tema selecionado
- Seção selecionada (Geral ou seção específica)
- Card visualizado
- Card avaliado como acerto ou erro (flashcard)
- Fase iniciada
- Fase concluída (com nota, estrelas e tempo total)
- Fase abandonada (saiu no meio — registrar em qual questão saiu)
- Quiz iniciado
- Quiz concluído (nota 0-100, estrelas, tempo total)
- Tempo gasto por questão no quiz (para calibrar tempo limite no futuro)
- Questões que mais geram erro no quiz (por card_id)
- Tentativas de quiz por fase (quantas vezes refez)
- Estrelas conquistadas por fase
- Streak atualizado
- Notificação recebida / clicada
- Anúncio exibido
- Compra realizada (quando monetização ativa)

### Estrutura sugerida da tabela de métricas
```sql
CREATE TABLE eventos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  evento TEXT NOT NULL,         -- ex: "card_avaliado", "fase_concluida", "quiz_questao_respondida"
  tema TEXT,                    -- ex: "CFC"
  secao TEXT,                   -- ex: "Placas", "Geral"
  valor TEXT,                   -- ex: "acerto", "erro", "3_estrelas", "85"
  metadata TEXT,                -- JSON com dados extras (ex: tempo gasto, card_id, tentativa nº)
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Exemplos de metadata JSON
```json
// quiz_questao_respondida
{ "card_id": 42, "acertou": true, "tempo_segundos": 8, "tentativa": 2 }

// fase_concluida
{ "fase_id": 3, "nota": 85, "estrelas": 2, "tempo_total_segundos": 134, "tentativa": 1 }

// fase_abandonada
{ "fase_id": 3, "questao_atual": 6, "total_questoes": 10 }
```

### Por quê isso é importante
Esses dados serão usados futuramente para:
- Calibrar o tempo limite por questão (se muitos usuários estão estourando = tempo curto demais)
- Identificar cards/questões com alto índice de erro (conteúdo confuso ou mal formulado)
- Decidir onde colocar monetização/paywall (o que os usuários mais usam)
- Identificar onde os usuários estão abandonando o app
- Saber quais temas e seções têm mais engajamento
- Embasar decisões de produto com dados reais, não achismo

---

## 📋 REGRAS GERAIS DE DESENVOLVIMENTO

### Arquitetura
- Sempre pensar que funcionalidades de monetização (travas, paywall) serão adicionadas no futuro — deixar estrutura preparada
- Banco SQLite local na v1 — nunca assumir que há internet disponível
- Firebase Cloud Messaging para notificações — já integrar desde o início

### Código
- Sempre comentar o código em português
- Separar camadas: UI, lógica de negócio e banco de dados
- Nunca misturar queries SQL direto na UI

### Banco de dados
- Todo novo modelo deve ter campo `criado_em` e `atualizado_em`
- Sempre versionar o banco (migrations) — nunca alterar schema sem migration

### UI/UX
- Animações simples são ok — evitar animações elaboradas frame a frame
- App deve funcionar 100% offline
- Sempre considerar celulares mais simples (baixo processamento)

---

## 📝 Sobre este projeto
Consulte o arquivo `Plano.md` para o detalhamento completo do app,
mecânicas, stack tecnológico e ordem de desenvolvimento.
