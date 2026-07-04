// lib/models/bichinho.dart

/// Humor do bichinho — calculado pela inatividade no tema (repository) e
/// consumido pela UI (sprite). Vive no model pra não acoplar camadas.
enum HumorBichinho { feliz, neutro, comFome, dormindo }

class Bichinho {
  /// Último estágio (lendário) — não evolui além disso.
  static const int estagioMax = 4;

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
  bool get lendario => estagio == estagioMax;
}

/// Resultado de alimentar — a UI usa `evoluiu` pra disparar a animação.
/// `nasceuAgora` = o obterOuCriar interno criou o bichinho nesse alimentar
/// (o BichinhoService usa pra disparar a métrica bichinho_nasceu).
class ResultadoAlimentar {
  final Bichinho bichinho;
  final int energiaGanha;
  final bool evoluiu;
  final bool nasceuAgora;
  const ResultadoAlimentar({
    required this.bichinho,
    required this.energiaGanha,
    required this.evoluiu,
    this.nasceuAgora = false,
  });
}

/// Resultado de obterOuCriar — `criado` = ovo acabou de nascer (dispara métrica bichinho_nasceu).
class BichinhoCriacao {
  final Bichinho bichinho;
  final bool criado;
  const BichinhoCriacao({required this.bichinho, required this.criado});
}
