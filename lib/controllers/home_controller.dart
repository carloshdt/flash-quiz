// lib/controllers/home_controller.dart
import 'package:flutter/foundation.dart';
import '../models/tema.dart';
import '../models/perfil.dart';
import '../repositories/tema_repository.dart';
import '../repositories/perfil_repository.dart';
import '../services/metrica_service.dart';

class HomeController extends ChangeNotifier {
  final TemaRepository _temaRepo;
  final PerfilRepository _perfilRepo;
  final MetricaService _metrica;

  List<Tema> temas = [];
  Perfil? perfil;
  bool carregando = true;

  HomeController({
    TemaRepository? temaRepo,
    PerfilRepository? perfilRepo,
    MetricaService? metrica,
  })  : _temaRepo = temaRepo ?? TemaRepository(),
        _perfilRepo = perfilRepo ?? PerfilRepository(),
        _metrica = metrica ?? MetricaService() {
    carregar();
  }

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    temas = await _temaRepo.getTemas();
    perfil = await _perfilRepo.getPerfil();
    await _metrica.appAberto();

    carregando = false;
    notifyListeners();
  }
}
