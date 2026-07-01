# 📱 FlashQuiz — Plano do App

> ⚠️ Nome temporário — decidir nome final antes de publicar

---

## 💡 Conceito
App de estudos com flashcards e quiz organizados em uma timeline de progressão por tema.
O usuário avança fase por fase, do conteúdo mais simples ao mais difícil, desbloqueando novas etapas conforme domina o conteúdo anterior.

---

## 🎯 Objetivo
- Aprender o processo completo de publicar na Play Store
- Gerar renda passiva via AdMob + monetização futura
- Estratégia de volume: esse é o primeiro de vários apps
- Não precisa escalar absurdamente — crescimento orgânico e natural

---

## 🛠️ Stack Tecnológico

| Tecnologia | Uso | Custo |
|---|---|---|
| Flutter | Código do app (Android + iOS) | Gratuito |
| SQLite | Dados locais (perfil, progresso, recordes) | Gratuito |
| Firebase Cloud Messaging | Notificações push | Gratuito |
| Google AdMob | Monetização por anúncios | Gratuito |
| Firebase Firestore | Sincronização na nuvem | Futuro |

**Princípio:** Zero custo de servidor na v1. Tudo local no dispositivo.

---

## 🎮 Mecânicas Principais

### Flashcard
- Usuário vê a pergunta, pensa na resposta
- Vira o card e se autoavalia (acertei / errei)
- Sistema SRS (Spaced Repetition): acertou = card demora mais pra voltar / errou = card volta logo
- Sem punição — foco em memorização e estudo, não em teste
- Saiu no meio da sessão = recomeça do zero com cards re-sorteados
- Usuário pode configurar quantos cards por sessão (padrão a definir)
- O número de cards configurado afeta só o ritmo — a barreira de progressão é sempre o quiz
- Pra avançar de fase o usuário precisa ter visto um mínimo de cards únicos da fase (número a definir)

### Quiz
- Múltipla escolha com tempo limite por questão
- Questões sorteadas aleatoriamente do pool da fase a cada tentativa
- Questões sempre re-sorteadas — evita memorização de posição
- Saiu no meio = conta como tentativa abandonada, recomeça com questões re-sorteadas
- Pode refazer quantas vezes quiser pra melhorar estrelas
- Tempo limite por questão: **a definir com base em métricas reais de uso**

**Pontuação (0 a 100):**
- Acertou rápido (0 a metade do tempo) → 10 pontos
- Acertou devagar (metade até o fim do tempo) → 7 pontos
- Errou ou estourou o tempo → 0 pontos

**Nota define as estrelas da fase:**
```
0  - 69  → Reprovado — refaz o quiz pra desbloquear próxima fase
70 - 79  → ⭐
80 - 89  → ⭐⭐
90 - 100 → ⭐⭐⭐
```
- Nota mínima pra desbloquear próxima fase: **70**
- Compartilhável: "tirei 85/100 no simulado de CFC!"
- Usado como validação no final de cada fase e como Desafio Diário

### Como se complementam
```
Timeline de fases
    ↓
Cada fase → estuda com Flashcard (SRS) até ver mínimo de cards únicos
    ↓
Final da fase → Quiz de validação pra desbloquear próxima fase (mín. 70)
    ↓
Tema completo → Simulado final em modo Quiz
```

---

## 🗺️ Timeline de Progressão

- Cada tema tem uma jornada linear de fases por dificuldade
- Fases desbloqueadas conforme o usuário passa no quiz da fase anterior (nota mínima 70)
- Cada fase tem estrelas (1, 2 ou 3) baseadas na nota do quiz
- Incentiva voltar pra melhorar a nota mesmo após já ter passado
- Cards difíceis ficam nas fases avançadas — o usuário chega preparado

**Exemplo para o tema CFC:**
```
[Fase 1] Fácil        ⭐⭐⭐
[Fase 2] Médio        ⭐⭐☆  ← usuário aqui
[Fase 3] Difícil      🔒
[Fase 4] Simulado     🔒
```

---

## 📂 Estrutura de Temas e Seções

### Conceito
Cada tema é dividido em seções (ex: CFC tem Placas, Multas, Regras, etc).
O usuário pode estudar pelo **Modo Geral** (todos os cards do tema misturados) ou filtrar por **Seção** específica.
O progresso é salvo separadamente por caminho — pode estar no nível 3 do Geral e nível 1 de Placas ao mesmo tempo.

### Estrutura do banco de dados
```
cards
[card_id, tema, seção, dificuldade, pergunta, resposta, alternativas]

Modo Geral  → SELECT * WHERE tema = "CFC" ORDER BY dificuldade
Modo Seção  → SELECT * WHERE tema = "CFC" AND seção = "Placas" ORDER BY dificuldade
```

### Exemplo CFC
```
TEMA: CFC
    ├── Geral (todos os cards misturados por dificuldade)
    ├── Placas de sinalização
    ├── Regras de trânsito
    ├── Multas e infrações
    ├── Direção defensiva
    ├── Primeiros socorros
    └── Mecânica básica
```

Dentro de qualquer caminho (Geral ou Seção), a timeline de dificuldade funciona igual:
Fácil → Médio → Difícil → Simulado final

**Vantagem:** O conteúdo é criado uma vez só e serve todos os modos. É apenas um filtro diferente na query.

---

## 👤 Perfil & Gamificação

### Perfil do Usuário
- Salvo localmente (SQLite) na v1
- Migração para Firebase Firestore planejada para versão futura
- Customização de temas e cards próprios — planejado para versão futura

### Estatísticas do Perfil
- Total de cards respondidos
- Taxa de acerto geral
- Streak de dias estudando
- Temas iniciados e concluídos
- Nível por tema (Iniciante → Expert)

### Gamificação
- **XP e níveis** por tema — cada card respondido dá XP
- **Streak diário** — sequência de dias estudando (notificação se estiver em risco)
- **Barra de domínio** — % de cards dominados por tema
- **Medalhas internas** — primeiro tema completo, 7 dias seguidos, 100 cards, etc
- **Ranking semanal** — quem respondeu mais cards na semana por tema

---

## 🔔 Notificações (Firebase Cloud Messaging)
- Lembrete diário de estudo (horário configurável pelo usuário)
- Alerta de streak em risco: *"Você está há X dias seguidos! Não perca agora."*
- Novo tema disponível após atualização do app

---

## 📚 Temas (Conteúdo)

### Estratégia de conteúdo
- Conteúdo montado com auxílio do Claude — gerado e revisado manualmente
- Temas embutidos no próprio app (sem servidor de conteúdo na v1)
- Novo tema = atualização do app
- Futuro: usuário poderá criar temas e cards próprios

### Temas para lançamento (avaliar)
**Alto potencial:**
- 🚗 CFC / Habilitação
- 🏛️ Concurso público (geral)
- 🇧🇷 Português / gramática

**Médio potencial:**
- ⚖️ OAB
- 📊 Excel e informática básica
- 🇬🇧 Inglês básico

**Casual / Engajamento:**
- ⚽ Futebol brasileiro
- 🧠 Curiosidades gerais

---

## 💰 Monetização

### Estratégia
- **Lançar sem travas** — todos os temas desbloqueados inicialmente
- Coletar métricas reais de uso antes de decidir onde colocar paywall
- Código já estruturado pra suportar travas — só mudar configuração quando chegar a hora

### Modelos possíveis (decidir após métricas)
- **Freemium por tema** — 1-2 temas grátis, demais comprados avulso (~R$ 4,99)
- **Tudo grátis + remove anúncios** — R$ 4,99 uma vez
- **Assinatura** — acesso total por R$ 9,99/mês ou R$ 49,99/ano

### Anúncios (AdMob)
- Banner na tela principal e tela de perfil
- Intersticial ao completar uma fase
- Rewarded (opcional): assistir anúncio pra ganhar dica no quiz

---

## 📦 Ordem de Desenvolvimento

### v1.0 — Base do app
- [x] Estruturar projeto Flutter + dependências
- [x] Modelagem do banco SQLite (perfil, progresso, temas, seções, cards, fases)
- [x] Tela inicial + navegação
- [x] Tela de seleção de temas
- [x] Tela de seleção de seção (Geral ou seção específica)
- [x] Timeline de fases por dificuldade
- [x] Modo Flashcard com SRS
- [x] Quiz de validação de fase (nota 0-100, estrelas, tempo por questão)
- [x] Modos de estudo extras (Desafio Diário, Revisão Inteligente, Maratona)
- [ ] Tela de perfil + estatísticas + streak
- [ ] Integrar AdMob (banner + intersticial)
- [ ] Montar conteúdo do 1º tema (CFC)
- [ ] **Publicar na Play Store**

### v1.1 — Gamificação
- [ ] Sistema de XP e níveis por tema
- [ ] Medalhas internas
- [ ] Ranking semanal
- [ ] Integrar Firebase Cloud Messaging (notificações)
- [ ] **Atualizar na Play Store**

### v1.2 — Expansão de conteúdo
- [ ] Adicionar 2-3 temas novos
- [ ] Simulado final por tema completo
- [ ] Compartilhamento de resultado do quiz
- [ ] **Atualizar na Play Store**

### Futuro
- [ ] Monetização (baseada em métricas reais)
- [ ] Sincronização na nuvem (Firebase Firestore)
- [ ] Temas customizados pelo usuário

---

## 🚀 Planos de Implementação

> Contexto técnico de cada próximo passo. Atualizar conforme planos forem concluídos.

| Plano | Descrição | Status |
|-------|-----------|--------|
| Plano 1 | Arquitetura base (DB, models, repos, controllers, screens, trilha ziguezague) | ✅ Concluído |
| Plano 2 | FlashcardScreen + SRS engine (3 níveis: Difícil/Médio/Fácil) | ✅ Concluído |
| Plano 3 | QuizScreen + QuizResultScreen | ✅ Concluído |
| Plano 3.5 | Modos de estudo extras (Desafio Diário, Revisão Inteligente, Maratona) | ✅ Concluído |
| Plano 4 | PerfilScreen + XP / streak / conquistas | ⏳ Próximo |
| Plano 5 | Seed de conteúdo real CFC | ⏳ Pendente |
| Plano 6 | AdMob + FCM + estrutura de paywall | ⏳ Pendente |

### Plano 3 — Quiz Engine

**O que implementar:**
- `QuizScreen` — múltipla escolha, timer por questão, sem feedback durante (suspense total)
- `QuizResultScreen` — breakdown por questão, nota 0–100, estrelas, botão refazer
- `QuizRepository` — salvar `quiz_tentativas` e `quiz_respostas`
- `QuizController` — lógica de sorteio, pontuação, timer

**Regras:**
- Acertou rápido (< metade do tempo) → 10 pts | devagar → 7 pts | errou/estourou → 0 pts
- Estrelas: 0–69 = reprovado, 70–79 = ⭐, 80–89 = ⭐⭐, 90–100 = ⭐⭐⭐
- Nota mínima pra desbloquear próxima fase: **70**
- Questões re-sorteadas a cada tentativa
- Timer: barra muda roxo → vermelho conforme esgota; transição entre questões: fade ~0.3s

**Já existe no banco:** `quiz_tentativas`, `quiz_respostas`, `quiz_num_questoes`, `quiz_tempo_por_questao` (config)

**Impacto:** `TrilhaController` precisa ler `quiz_tentativas` pra determinar nó concluído; `SecaoRepository.getProgressoPorTema()` já lê `quiz_tentativas` — popula automaticamente

**Métricas obrigatórias:** `quiz_iniciado`, `quiz_questao_respondida` (card_id, acertou, tempo_s, tentativa), `quiz_concluido` (nota, estrelas, tempo_total), `quiz_abandonado` (questao_atual)

### Plano 4 — Perfil + Gamificação

**O que implementar:**
- `PerfilScreen` — stats, streak, XP, nível, conquistas
- `PerfilController` — carregar e atualizar perfil
- Sistema de XP por card avaliado + quiz concluído
- Streak: incrementa se estudou hoje, reseta se passou um dia sem estudar
- Conquistas: verificar e desbloquear após ações relevantes

**XP (já em config):** Fácil=10, Médio=7, Difícil=3 por card | 50 XP por estrela de quiz

**Conquistas já no seed:** `primeiro_tema`, `streak_7`, `cards_100`, `quiz_3estrelas`, `tema_completo`, `streak_30`

**Tabelas já existem:** `perfil`, `conquistas`, `conquistas_usuario`

### Plano 5 — Conteúdo Real CFC

Substituir cards placeholder (5 genéricos por fase) por conteúdo real via migration_v4.

**Seções já criadas no banco:** Geral (📚), Placas e Sinais (🚦), Legislação (⚖️), Direção Defensiva (🛡️), Primeiros Socorros (🚑), Mecânica Básica (🔧)

### Plano 6 — Monetização e Notificações

- AdMob: banner na Home e PerfilScreen, intersticial ao completar fase
- FCM: notificação diária + streak em risco
- Paywall: `is_premium` já em `perfil`, `quiz_max_tentativas_free_por_dia` já em `config`

**Decisões pendentes:** modelo de monetização (freemium / remove ads / assinatura) — decidir após métricas

---

## 🎨 UI/UX
> ⚠️ A ser detalhado — tópico em debate

---

## 🔢 Valores a Definir
> Estes valores serão calibrados com base em métricas reais de uso após o lançamento

- [ ] Número padrão de cards por sessão de flashcard
- [ ] Opções configuráveis de cards por sessão (ex: 10, 20, 30)
- [ ] Número mínimo de cards únicos vistos pra liberar o quiz da fase
- [ ] Número de questões por quiz (referência atual: 10)
- [ ] Tempo limite por questão no quiz
- [ ] XP ganho por card respondido no flashcard
- [ ] XP ganho por questão acertada no quiz
- [ ] XP necessário pra subir de nível por tema

---


## 📋 Pendências / Decisões
- [ ] Nome final do app
- [ ] Ícone do app
- [ ] Paleta de cores / identidade visual
- [ ] Quais temas lançar primeiro
- [ ] Detalhamento completo de UI/UX e fluxos
- [ ] Criar conta Google Play Developer (taxa única US$ 25)
- [ ] Configurar AdMob
- [ ] Configurar Firebase Cloud Messaging

---

## 💡 Ideias Futuras (pós-métricas)

> Não implementar agora. Decisões baseadas em dados reais de uso após launch.

### Monetização
- **Freemium por tema** — 1-2 temas grátis, demais ~R$4,99 cada
- **Remove ads** — R$4,99 ou R$9,99 (compra única)
- **Assinatura** — R$9,99/mês ou R$49,99/ano

### Limite de retentativa de quiz (freemium)
- Usuário free: X tentativas por dia por quiz (ex: 1)
- Usuário premium: ilimitado
- Variações: cooldown de X horas, ou N tentativas free lifetime por quiz
- Config já prevista: `quiz_max_tentativas_free_por_dia` na tabela `config`
- Métrica-chave: quantas vezes usuário tenta refazer o mesmo quiz (coletar antes de decidir)

### Rewarded ads
- Assistir anúncio = ganhar 1 tentativa extra de quiz
- Alternativa menos agressiva ao paywall, mantém engajamento

### Outras ideias
- Ranking semanal por tema
- Simulado final por tema completo
- Compartilhamento de resultado do quiz
- Temas customizados pelo usuário
- Sincronização na nuvem (Firebase Firestore)

### Decks criados pelo usuário (zero servidor)
- Usuário cria temas/cards próprios no app — tudo local
- Grande potencial de retenção; antecipar pra v1.x se métricas indicarem

### IA: geração automática de cards (custo API)
- Usuário cola texto/foto de apostila → IA (Claude) gera deck completo
- Feature "uau" e diferencial forte, mas exige API paga → feature premium
- Depende de decks do usuário existirem primeiro

### Viral / social leve (zero servidor)
- Compartilhar resultado do quiz como imagem bonita (share sheet nativo)
- Desafiar amigo via link
- Widget de streak na home screen do celular
- Crescimento orgânico sem backend

---

## 📝 Notas Gerais
- Complexidade de código nunca é problema — Claude Code resolve
- Animações simples são ok — evitar animações elaboradas
- Estratégia de volume: esse app é o primeiro de vários
- Sem servidor na v1 = lucro quase 100% do AdMob
- Conteúdo dos cards gerado com Claude = zero custo de produção
