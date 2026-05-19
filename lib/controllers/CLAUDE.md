# CLAUDE.md — lib/controllers/

## Regras dos Controllers

- Todo controller extende `ChangeNotifier`
- Chamar `notifyListeners()` após qualquer mudança de estado
- Injetar dependências via construtor (repositories, services)
- Nunca acessar banco diretamente — só via repositories
- Nunca fazer navegação — navegação é responsabilidade da screen

## Padrão de carregamento

```dart
bool carregando = true; // ou false se não carrega no construtor

Future<void> carregar(...) async {
  carregando = true;
  notifyListeners();
  // ... busca dados ...
  carregando = false;
  notifyListeners();
}
```

## Metrificação obrigatória

Todo controller que representa uma ação do usuário deve registrar o evento via `MetricaService`.

```dart
final MetricaService _metrica;
// No método relevante:
await _metrica.eventoRelevante(...);
```

## Providers registrados em `lib/app.dart`

`HomeController` · `SecoesController` · `TrilhaController`

Novos controllers adicionados nos planos seguintes devem ser registrados no `MultiProvider` de `app.dart`.
