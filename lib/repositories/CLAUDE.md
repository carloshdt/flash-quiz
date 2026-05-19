# CLAUDE.md — lib/repositories/

## Regras dos Repositories

- Todo repository recebe `DatabaseHelper` via construtor (injeção de dependência)
- Padrão: `MyRepo({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();`
- Nunca instanciar `DatabaseHelper()` fora do construtor do repository
- Queries SQL ficam **exclusivamente** aqui — nunca em controllers ou screens
- Cada repository cuida de uma ou poucas tabelas relacionadas

## Repositories existentes

| Repository | Tabela(s) |
|---|---|
| `TemaRepository` | `temas` |
| `SecaoRepository` | `secoes` |
| `FaseRepository` | `fases` |
| `CardRepository` | `cards` |
| `ConfigRepository` | `config` |
| `EventoRepository` | `eventos` |
| `PerfilRepository` | `perfil` |

## Metrificação

- Eventos **não** são registrados nos repositories
- Eventos são registrados nos **controllers** via `MetricaService`
- `EventoRepository` é usado apenas pelo `MetricaService`

## Testes

- Testar com banco real (`sqflite_common_ffi`) — não mockar
- Ver padrão de isolamento em `test/repositories/`
