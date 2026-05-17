// lib/services/metrica_service.dart
// Wrapper tipado sobre EventoRepository. Todo evento do app passa por aqui.

import '../models/evento.dart';
import '../repositories/evento_repository.dart';

class MetricaService {
  final EventoRepository _repo;
  MetricaService({EventoRepository? repo}) : _repo = repo ?? EventoRepository();

  Future<void> appAberto() => _repo.registrar(const Evento(evento: 'app_aberto'));

  Future<void> temaSelecionado(int temaId, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'tema_selecionado',
        tema: nomeTema,
        metadata: {'tema_id': temaId},
      ));

  Future<void> secaoSelecionada(int secaoId, String nomeSecao, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'secao_selecionada',
        tema: nomeTema,
        secao: nomeSecao,
        metadata: {'secao_id': secaoId},
      ));

  Future<void> faseSelecionada(int faseId, String nomeFase, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'fase_selecionada',
        tema: nomeTema,
        metadata: {'fase_id': faseId, 'nome_fase': nomeFase},
      ));

  Future<void> quizSelecionado(int faseId, String nomeFase, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'quiz_selecionado',
        tema: nomeTema,
        metadata: {'fase_id': faseId, 'nome_fase': nomeFase},
      ));
}
