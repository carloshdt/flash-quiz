# CLAUDE.md — lib/db/

## Regras do Banco de Dados

### Migrations

- Toda alteração de schema = nova migration (`migration_v2.dart`, etc.)
- **Nunca** alterar `migration_v1.dart` após deploy — criar nova migration
- `DatabaseHelper` controla versão via `openDatabase(version: N)`
- Cada migration recebe o `db` e executa `ALTER TABLE` / novos `CREATE TABLE`

### Schema

- Toda tabela deve ter `criado_em DATETIME DEFAULT CURRENT_TIMESTAMP`
- Tabelas que têm updates devem ter `atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP`
- Foreign keys sempre declaradas explicitamente
- Nomes de tabelas: `snake_case`, plural (ex: `quiz_tentativas`)
- Nomes de colunas: `snake_case` (ex: `fase_id`, `total_visto`)

### Tabelas existentes (v1)

`temas` · `secoes` · `fases` · `cards` · `progresso_flashcard` · `quiz_tentativas` · `quiz_respostas` · `perfil` · `config` · `eventos` · `conquistas` · `conquistas_usuario`

### Tabela config

Todos os parâmetros ajustáveis do app ficam aqui. Nunca hardcodar valores de negócio.

Chaves existentes:
- `quiz_tempo_por_questao` (segundos)
- `quiz_num_questoes`
- `flashcard_min_percentual_para_quiz`
- `flashcard_cards_por_sessao`
- `xp_por_card_facil` / `xp_por_card_medio` / `xp_por_card_dificil`
- `xp_por_quiz_estrela`
- `quiz_max_tentativas_free_por_dia`

### Testes

- Usar `sqflite_common_ffi` para testes — não mockar banco
- `DatabaseHelper.fecharParaTeste()` no `setUp` e `tearDown` de cada teste
- Chamar `databaseFactoryFfi.deleteDatabase(path)` no setUp para garantir isolamento
