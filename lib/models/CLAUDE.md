# CLAUDE.md — lib/models/

## Regras dos Models

- Models são **imutáveis** (`final` em todos os campos, construtor `const`)
- Todo model que lê do banco precisa de `factory fromMap(Map<String, dynamic> m)`
- Todo model que escreve no banco precisa de `Map<String, dynamic> toMap()`
- Sem lógica de negócio nos models — apenas mapeamento de dados
- Campos Dart em `camelCase`; mapeiam colunas SQLite em `snake_case`

## Mapeamento de tipos SQLite → Dart

| SQLite | Dart |
|---|---|
| INTEGER (0/1) | bool → `(m['campo'] as int) == 1` |
| INTEGER nullable | `int?` |
| DATETIME string | `DateTime.parse(...)` |
| TEXT nullable | `String?` |

## Models existentes

`Tema` · `Secao` · `Fase` · `CardModel` · `ProgressoFlashcard` · `QuizTentativa` · `QuizResposta` · `Perfil` · `Config` · `Evento`

## Notas

- `CardModel.alternativasEmbaralhadas()` — retorna lista das 4 alternativas embaralhada (uso no quiz)
- `ProgressoFlashcard.nivelSrs`: 0=difícil, 1=médio, 2=fácil
- `Config.valorInt` e `Config.valorDouble` — getters de conveniência
- `Evento.toMap()` usa `jsonEncode` para serializar `metadata`
- `Perfil.isPremium` — campo reservado para monetização futura
