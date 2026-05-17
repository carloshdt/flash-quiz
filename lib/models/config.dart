// lib/models/config.dart
class Config {
  final String chave;
  final String valor;

  const Config({required this.chave, required this.valor});

  factory Config.fromMap(Map<String, dynamic> m) => Config(
    chave: m['chave'] as String,
    valor: m['valor'] as String,
  );

  int get valorInt => int.parse(valor);
  double get valorDouble => double.parse(valor);
}
