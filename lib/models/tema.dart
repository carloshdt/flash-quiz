// lib/models/tema.dart
class Tema {
  final int id;
  final String nome;
  final String icone;
  final bool desbloqueado;

  const Tema({
    required this.id,
    required this.nome,
    required this.icone,
    this.desbloqueado = true,
  });

  factory Tema.fromMap(Map<String, dynamic> m) => Tema(
    id: m['id'] as int,
    nome: m['nome'] as String,
    icone: m['icone'] as String,
    desbloqueado: (m['desbloqueado'] as int) == 1,
  );
}
