// lib/models/secao.dart
class Secao {
  final int id;
  final int temaId;
  final String nome;
  final int ordem;

  const Secao({
    required this.id,
    required this.temaId,
    required this.nome,
    required this.ordem,
  });

  factory Secao.fromMap(Map<String, dynamic> m) => Secao(
    id: m['id'] as int,
    temaId: m['tema_id'] as int,
    nome: m['nome'] as String,
    ordem: m['ordem'] as int,
  );
}
