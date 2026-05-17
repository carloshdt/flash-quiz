// lib/models/fase.dart
class Fase {
  final int id;
  final int secaoId;
  final String nome;
  final int ordem;

  const Fase({
    required this.id,
    required this.secaoId,
    required this.nome,
    required this.ordem,
  });

  factory Fase.fromMap(Map<String, dynamic> m) => Fase(
    id: m['id'] as int,
    secaoId: m['secao_id'] as int,
    nome: m['nome'] as String,
    ordem: m['ordem'] as int,
  );
}
