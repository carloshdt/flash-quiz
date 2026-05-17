// lib/controllers/secoes_controller.dart
import 'package:flutter/foundation.dart';
import '../models/secao.dart';
import '../repositories/secao_repository.dart';
import '../services/metrica_service.dart';

class SecoesController extends ChangeNotifier {
  final SecaoRepository _repo;
  final MetricaService _metrica;

  List<Secao> secoes = [];
  bool carregando = false;

  SecoesController({SecaoRepository? repo, MetricaService? metrica})
      : _repo = repo ?? SecaoRepository(),
        _metrica = metrica ?? MetricaService();

  Future<void> carregar(int temaId, String nomeTema) async {
    carregando = true;
    notifyListeners();

    secoes = await _repo.getSecoesPorTema(temaId);
    await _metrica.temaSelecionado(temaId, nomeTema);

    carregando = false;
    notifyListeners();
  }
}
