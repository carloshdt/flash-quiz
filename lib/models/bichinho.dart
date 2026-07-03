// lib/models/bichinho.dart
class Bichinho {
  final int id;
  final int temaId;
  final int especie;
  final int estagio; // 0=ovo, 1=filhote, 2=jovem, 3=adulto, 4=lendário
  final int energia;

  const Bichinho({
    required this.id,
    required this.temaId,
    required this.especie,
    this.estagio = 0,
    this.energia = 0,
  });

  factory Bichinho.fromMap(Map<String, dynamic> m) => Bichinho(
        id: m['id'] as int,
        temaId: m['tema_id'] as int,
        especie: m['especie'] as int,
        estagio: m['estagio'] as int,
        energia: m['energia'] as int,
      );

  static const nomesEstagios = ['Ovo', 'Filhote', 'Jovem', 'Adulto', 'Lendário'];
  String get nomeEstagio => nomesEstagios[estagio];
  bool get lendario => estagio == 4;
}

/// Resultado de alimentar — a UI usa `evoluiu` pra disparar a animação.
class ResultadoAlimentar {
  final Bichinho bichinho;
  final int energiaGanha;
  final bool evoluiu;
  const ResultadoAlimentar({required this.bichinho, required this.energiaGanha, required this.evoluiu});
}

/// Resultado de obterOuCriar — `criado` = ovo acabou de nascer (dispara métrica bichinho_nasceu).
class BichinhoCriacao {
  final Bichinho bichinho;
  final bool criado;
  const BichinhoCriacao({required this.bichinho, required this.criado});
}
