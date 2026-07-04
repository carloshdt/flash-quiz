// lib/controllers/home_controller.dart
import 'package:flutter/foundation.dart';
import '../models/bichinho.dart';
import '../models/tema.dart';
import '../models/perfil.dart';
import '../repositories/bichinho_repository.dart';
import '../repositories/tema_repository.dart';
import '../repositories/perfil_repository.dart';
import '../services/metrica_service.dart';

class HomeController extends ChangeNotifier {
  final TemaRepository _temaRepo;
  final PerfilRepository _perfilRepo;
  final BichinhoRepository _bichinhoRepo;
  final MetricaService _metrica;

  List<Tema> temas = [];
  Perfil? perfil;
  bool carregando = true;

  Map<int, Bichinho> _bichinhos = {};
  Map<int, HumorBichinho> _humores = {};

  /// Bichinho de cada tema (chave = tema.id).
  Map<int, Bichinho> get bichinhos => _bichinhos;

  /// Humor do bichinho de cada tema (chave = tema.id).
  Map<int, HumorBichinho> get humores => _humores;

  HomeController({
    TemaRepository? temaRepo,
    PerfilRepository? perfilRepo,
    BichinhoRepository? bichinhoRepo,
    MetricaService? metrica,
  })  : _temaRepo = temaRepo ?? TemaRepository(),
        _perfilRepo = perfilRepo ?? PerfilRepository(),
        _bichinhoRepo = bichinhoRepo ?? BichinhoRepository(),
        _metrica = metrica ?? MetricaService() {
    carregar();
  }

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    temas = await _temaRepo.getTemas();
    perfil = await _perfilRepo.getPerfil();
    await _metrica.appAberto();

    // Garante um bichinho por tema desbloqueado (cria o ovo na primeira visita).
    // Temas bloqueados ficam de fora: o card oculta o bichinho e criar o ovo
    // poluiria a métrica bichinho_nasceu.
    _bichinhos = {};
    _humores = {};
    for (final tema in temas) {
      if (!tema.desbloqueado) continue;
      final criacao = await _bichinhoRepo.obterOuCriar(tema.id);
      _bichinhos[tema.id] = criacao.bichinho;
      _humores[tema.id] = await _bichinhoRepo.humor(tema.id);
      if (criacao.criado) {
        await _metrica.bichinhoNasceu(tema.nome, criacao.bichinho.especie);
      }
    }

    carregando = false;
    notifyListeners();
  }
}
