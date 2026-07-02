# Spec — Identidade "Recorte & Cola" + Bichinho Virtual

> Aprovada em 2026-07-02. Reformulação visual completa (Plano 3.75) do FlashQuiz.
> Features de retenção (onboarding, notificações, celebrações de streak) ficam em spec separada futura.

## Visão

O FlashQuiz abandona o dark navy genérico e ganha identidade própria: **Recorte & Cola** — um scrapbook artesanal de papel, com cards tortos, fita adesiva, post-its, carimbos e costura tracejada. Cada tema tem um **bichinho virtual pixel** que nasce de um ovo e evolui conforme o usuário estuda (efeito tamagotchi de retenção).

Decisões tomadas em brainstorm (2026-07-02):
- Direção visual: Recorte & Cola (vencedora contra Neon Arcade, Papel & Tinta, Brutalista Pop, Aurora Premium, Bauhaus)
- Mascote: bichinho virtual pixel evolutivo (vencedor após 5 rodadas de conceitos)
- Tema claro apenas (dark mode descaracteriza; fica pra futuro distante)
- Estratégia big-bang: design system inteiro trocado de uma vez, depois telas
- Personalidade: mascote + micro-animações + haptics + sons (sem copy nova por ora)

---

## 1. Design System

### 1.1 Cores (`AppColors` reescrito — nomes semânticos)

```dart
// Fundação
papel        #F2EDE4   // fundo geral — papel creme
cartao       #FFFFFF   // superfícies/cards
tinta        #33302A   // texto principal — quase-preto quente
tintaSuave   #8A8378   // texto secundário — lápis
grao         #D8D0C0   // textura pontilhada do fundo, divisores

// Acentos
laranja      #FF5C39   // CTA, energia, destaque primário
verde        #5CB270   // sucesso, aprovado
amarelo      #F7D046   // post-its, destaque, estrelas
azul         #4DA6FF   // info, água
rosa         #FF9EBB   // carinho, bochechas, coração
```

`AppColors.accentFor(id)` mantido, ciclando acentos novos: laranja, verde, azul, rosa, amarelo, + variações (roxo suave `#B48CD9`, teal `#7FDBCA`, coral `#FF8A7A`).

### 1.2 Tipografia (google_fonts)

| Uso | Fonte | Notas |
|-----|-------|-------|
| Títulos, headers, botões | **Patrick Hand** | manuscrita legível |
| Corpo, listas, questões | **Nunito** | mantida |
| Widget do bichinho (nome, energia, estágio) | **VT323** | pixel, só no contexto do pet |

### 1.3 Componentes de papel (`lib/widgets/papel/`)

| Widget | Descrição |
|--------|-----------|
| `PapelCard` | Card branco, raio 4px, rotação determinística -1.5° a +1.5° (seed = hash do conteúdo/id, pra não mudar a cada build), sombra dura offset(2,3) sem blur grande |
| `PostIt` | Quadrado amarelo (ou cor passada) com dobra de canto, leve rotação |
| `Fita` | Retângulo translúcido (branco 40% alpha) rotacionado, "colando" o topo de um card |
| `Carimbo` | Texto em caixa com borda dupla, rotacionado, cor sólida (verde APROVADO, laranja RECORDE) |
| `BotaoPapel` | Botão com sombra dura que "afunda" ao pressionar (scale 0.97, sombra some) |
| `LinhaCostura` | Divisor tracejado tipo costura/recorte de tesoura |
| `FundoPapel` | Scaffold wrapper com cor papel + textura pontilhada sutil (CustomPainter, grão determinístico) |

Regra: **elementos de identidade com parcimônia** — fita e carimbo só em momentos-chave, não em todo card.

### 1.4 Material → Papel

- Ripple do Material substituído por pressão de papel (scale + sombra) nos componentes novos
- `ThemeData` light completo: scaffoldBackground = papel, appBar transparente/creme com título Patrick Hand, elevation 0 em tudo
- Nada de gradientes, nada de glow, nada de glassmorphism

---

## 2. Bichinho Virtual

### 2.1 Regras

- **1 bichinho por tema.** Nasce OVO quando o usuário abre o tema pela primeira vez.
- **Espécie por tema:** designs pixel ciclam por `tema.id % numEspecies` (lançamento: 3 espécies + ovo; mais espécies = Ideias Futuras).
- **5 estágios:** Ovo (0) → Filhote (1) → Jovem (2) → Adulto (3) → Lendário (4).
- **Energia** acumulada por atividades NO tema:

| Atividade | Energia |
|-----------|---------|
| Card avaliado (flashcard/revisão) | 2 |
| Quiz concluído | 15 |
| Desafio Diário concluído | 10 |
| Revisão Inteligente concluída | 10 |
| Maratona concluída | 10 |

- **Thresholds de evolução:** 50 → Filhote, 200 → Jovem, 500 → Adulto, 1000 → Lendário.
- **Multiplicador de streak:** streak global ativo (estudou ontem ou hoje) = energia ×1.5, arredondado pra baixo. Sem streak = ×1. Quebrar streak desacelera a evolução — energia acumulada NUNCA é perdida.
- **Humor** (calculado de `eventos`/última atividade no tema, não armazenado):
  - Feliz: estudou o tema hoje
  - Neutro: estudou ontem (usa sprite de feliz, sem partículas de coração)
  - Com fome: 2–6 dias sem estudar o tema
  - Dormindo: 7+ dias
- **Todos os valores numéricos na tabela `config`:** `bichinho_energia_card`, `bichinho_energia_quiz`, `bichinho_energia_modo`, `bichinho_threshold_1..4`, `bichinho_streak_multiplicador`, `bichinho_dias_fome`, `bichinho_dias_dormindo`.

### 2.2 UI

- **Home:** sprite 24–28px na linha de cada tema (ovo ou bicho no humor atual).
- **SecoesScreen (tela do tema):** widget maior (~72px) no header com nome do estágio e barra de energia até a próxima evolução (estilo pixel, VT323).
- **Tap no bichinho (qualquer lugar):** popup (bottom sheet de papel) com sprite grande, estágio, energia atual/threshold, humor e dica contextual ("Alimente com 3 cards!").
- **Evolução:** animação em overlay — ovo racha / flash branco 8-bit / sprite novo salta + jingle + haptic pesado. Dispara na primeira tela após a energia cruzar o threshold.
- **Lendário:** sem mais barra de energia; badge dourado.

### 2.3 Sprites

- Pixel art **em código**: matrizes de inteiros (0 = transparente, 1..N = índice de cor) renderizadas via `CustomPainter` com `shape-rendering` crisp (retângulos por pixel).
- Grid 16×16 por sprite. Cada espécie: 4 sprites (estágios 1–4) × 3 humores (feliz/fome/dormindo = variação de olhos/boca, não sprite inteiro novo). Ovo é compartilhado (com palette da espécie).
- Arquivo `lib/widgets/bichinho/sprites.dart` com dados; `BichinhoSprite` widget que recebe espécie/estágio/humor/tamanho.
- Animação idle: 2 frames (bounce de 1px) alternando a cada ~800ms.

### 2.4 Dados

`migration_v5.dart`:

```sql
CREATE TABLE bichinhos (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  tema_id       INTEGER NOT NULL UNIQUE,
  especie       INTEGER NOT NULL,          -- índice da espécie
  estagio       INTEGER NOT NULL DEFAULT 0, -- 0=ovo..4=lendário
  energia       INTEGER NOT NULL DEFAULT 0,
  criado_em     DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

+ seeds de `config` (valores da seção 2.1).

`BichinhoRepository`:
- `obterOuCriar(temaId)` — cria ovo na primeira visita
- `alimentar(temaId, energiaBase)` — aplica multiplicador de streak, soma energia, promove estágio se cruzar threshold; retorna resultado com `evoluiu: bool` pra UI disparar animação
- `humor(temaId)` — calcula de última atividade
- Streak calculado de `eventos`: existe atividade registrada hoje OU ontem (qualquer tema) = streak ativo. Quando o Plano 4 implementar streak persistido, o repository troca a fonte sem mudar a interface

**Integração:** controllers existentes chamam `alimentar()` ao concluir card avaliado / quiz / modo. UI escuta retorno pra animação de evolução. Nenhum SQL fora do repository.

### 2.5 Métricas (tabela `eventos`)

- `bichinho_nasceu` (tema, especie)
- `bichinho_alimentado` (tema, energia_ganha, multiplicador, energia_total)
- `bichinho_evoluiu` (tema, estagio_novo)
- `bichinho_popup_aberto` (tema, estagio, humor)

---

## 3. Micro-animações, Haptics e Sons

### 3.1 Animações (Flutter puro)

| Momento | Animação |
|---------|----------|
| Listas entram | Cascata: fade + slide 12px + assenta na rotação torta (stagger 40ms) |
| Tap em card/botão | Pressão de papel: scale 0.97 + sombra dura some (100ms) |
| Acerto no quiz | Confete de papel picado (CustomPainter, ~20 partículas nas cores de acento) |
| Resultado aprovado | Carimbo APROVADO bate: scale 1.6→1.0 + micro-shake + haptic médio |
| Evolução do bichinho | Overlay: racha/flash/salto 8-bit |
| Flip flashcard | Mantido 3D atual + som de papel |

### 3.2 Haptics (`HapticFeedback`, sem dependência)

| Intensidade | Momentos |
|-------------|----------|
| `lightImpact` | tocar alternativa, virar card |
| `mediumImpact` | acerto, carimbo |
| `heavyImpact` | evolução, recorde de maratona, 3 estrelas |
| `selectionClick` | navegação entre questões |

### 3.3 Sons (package `audioplayers`, assets CC0 em `assets/sounds/`)

| Arquivo | Momento |
|---------|---------|
| `papel_virar.mp3` | flip do flashcard |
| `papel_recorte.mp3` | transição de tela principal |
| `carimbo.mp3` | carimbo APROVADO/RECORDE |
| `papel_amassar.mp3` | erro (suave, não punitivo) |
| `pixel_comer.mp3` | bichinho alimentado (só no popup/tela do tema) |
| `pixel_evolucao.mp3` | jingle 8-bit de evolução |
| `fanfarra.mp3` | recorde/3 estrelas |
| `confete.mp3` | confete de acerto no resultado |

- **Serviço:** `lib/services/audio_service.dart` — singleton, pré-carrega, respeita toggle.
- **Toggles separados** (som / haptics) persistidos em `config` (`som_ativo`, `haptics_ativo`, default ligados). UI de toggle: ícones no header da Home (ou tela de perfil no Plano 4).
- Eventos: `som_toggled`, `haptics_toggled`.

---

## 4. Escopo de Telas (todas)

| Tela | Tratamento Recorte & Cola |
|------|---------------------------|
| Home | Temas como recortes colados (PapelCard + emoji grande), sprite do bichinho na linha, header com streak em post-it |
| SecoesScreen | Widget do bichinho no header, seções em PapelCard, modos de estudo como post-its coloridos |
| TrilhaScreen | Zigzag vira costura tracejada (LinhaCostura), nós = selos de papel (círculo flashcard / quadrado quiz), estados: cinza rascunho (bloqueado), laranja (atual), carimbadinho verde (concluído) |
| FlashcardScreen | Card branco com Fita no topo, flip 3D mantido, botões SRS como BotaoPapel |
| QuizScreen | Questão em PapelCard, alternativas como tiras de papel, timer = régua com lápis riscando (barra atual reestilizada) |
| QuizResultScreen | Carimbo APROVADO/tenta de novo, confete, estrelas amarelas desenhadas à mão |
| Desafio/Result | Mesma linguagem, acento laranja mantido |
| Maratona/Result | Acento teal, corações de papel como vidas, carimbo RECORDE |
| RevisaoScreen | Igual flashcard, acento próprio |

Regras de negócio, rotas, controllers e repositories **não mudam** (exceto adições do bichinho). Reforma é de UI + tema.

---

## 5. Arquitetura

```
lib/theme/app_theme.dart              → REESCRITO (AppColors semântico light + ThemeData)
lib/widgets/papel/                    → NOVO (7 widgets, seção 1.3)
lib/widgets/bichinho/sprites.dart     → NOVO (matrizes pixel)
lib/widgets/bichinho/bichinho_sprite.dart → NOVO (CustomPainter)
lib/widgets/bichinho/bichinho_widget.dart → NOVO (widget home/header + popup)
lib/widgets/confete/confete_papel.dart    → NOVO (partículas)
lib/repositories/bichinho_repository.dart → NOVO
lib/db/migrations/migration_v5.dart   → NOVO
lib/services/audio_service.dart       → NOVO
assets/sounds/                        → NOVO (8 arquivos CC0)
telas existentes                      → reestilizadas, lógica intacta
```

- Camadas UI → Controller → Repository → SQLite mantidas. SQL só em repositories. Comentários em português.
- Migration versionada, campos criado_em/atualizado_em, valores em `config`.
- pubspec: + `audioplayers` (única dependência nova).

## 6. Testes

- `migration_v5_test.dart` — tabela existe, configs seedadas
- `bichinho_repository_test.dart` — criação de ovo, alimentar com/sem streak, evolução em threshold, energia nunca perde, humor por inatividade
- `sprites_test.dart` — toda matriz 16×16, índices de cor válidos
- Testes existentes (39) continuam passando

## 7. Fora de escopo (specs futuras)

- Onboarding, notificações, celebração de streak (spec de retenção)
- Galeria/coleção de bichinhos, espécies raras, acessórios (Ideias Futuras no Plano.md)
- Dark mode "papel kraft"
- Copy/voz com personalidade
- PerfilScreen (Plano 4)
