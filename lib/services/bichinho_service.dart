// lib/services/bichinho_service.dart
// Orquestra alimentação do bichinho: config + repository + métricas num ponto único.
import 'package:flutter/foundation.dart';
import '../models/bichinho.dart';
import '../repositories/bichinho_repository.dart';
import '../repositories/config_repository.dart';
import 'metrica_service.dart';

class BichinhoService {
  final ConfigRepository _configRepo;
  final BichinhoRepository _bichinhoRepo;
  final MetricaService _metrica;

  BichinhoService({
    ConfigRepository? configRepo,
    BichinhoRepository? bichinhoRepo,
    MetricaService? metrica,
  })  : _configRepo = configRepo ?? ConfigRepository(),
        _bichinhoRepo = bichinhoRepo ?? BichinhoRepository(),
        _metrica = metrica ?? MetricaService();

  /// Alimenta o bichinho do tema com a energia da config `chaveEnergia` e
  /// registra as métricas: bichinho_nasceu (se criado agora), bichinho_alimentado
  /// e bichinho_evoluiu (se cruzou threshold).
  /// Retorna null se o temaId não foi resolvido — alimentação pulada.
  Future<ResultadoAlimentar?> alimentarComMetricas({
    required int? temaId,
    required String nomeTema,
    required String chaveEnergia,
    required int padrao,
  }) async {
    if (temaId == null) {
      debugPrint(
          'BichinhoService: temaId não resolvido pra "$nomeTema" — alimentação pulada');
      return null;
    }

    final energia = await _configRepo.getValorInt(chaveEnergia, padrao: padrao);
    final resultado = await _bichinhoRepo.alimentar(temaId, energia);

    if (resultado.nasceuAgora) {
      await _metrica.bichinhoNasceu(nomeTema, resultado.bichinho.especie);
    }
    await _metrica.bichinhoAlimentado(
        nomeTema, resultado.energiaGanha, resultado.bichinho.energia);
    if (resultado.evoluiu) {
      await _metrica.bichinhoEvoluiu(nomeTema, resultado.bichinho.estagio);
    }

    return resultado;
  }
}
