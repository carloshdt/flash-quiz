// lib/models/perfil.dart
class Perfil {
  final int id;
  final String nome;
  final int xpTotal;
  final int nivel;
  final int streakAtual;
  final int streakMaximo;
  final DateTime? ultimoEstudo;
  final bool isPremium;

  const Perfil({
    required this.id,
    required this.nome,
    this.xpTotal = 0,
    this.nivel = 1,
    this.streakAtual = 0,
    this.streakMaximo = 0,
    this.ultimoEstudo,
    this.isPremium = false,
  });

  factory Perfil.fromMap(Map<String, dynamic> m) => Perfil(
    id: m['id'] as int,
    nome: m['nome'] as String,
    xpTotal: m['xp_total'] as int,
    nivel: m['nivel'] as int,
    streakAtual: m['streak_atual'] as int,
    streakMaximo: m['streak_maximo'] as int,
    ultimoEstudo: m['ultimo_estudo'] != null
        ? DateTime.parse(m['ultimo_estudo'] as String)
        : null,
    isPremium: (m['is_premium'] as int) == 1,
  );

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'xp_total': xpTotal,
    'nivel': nivel,
    'streak_atual': streakAtual,
    'streak_maximo': streakMaximo,
    'ultimo_estudo': ultimoEstudo?.toIso8601String().split('T').first,
    'is_premium': isPremium ? 1 : 0,
    'atualizado_em': DateTime.now().toIso8601String(),
  };
}
