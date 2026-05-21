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

  Future<void> cardVisto(int cardId, int faseId, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'card_visto',
        tema: nomeTema,
        metadata: {'card_id': cardId, 'fase_id': faseId},
      ));

  Future<void> cardAvaliado(int cardId, int nivelSrs, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'card_avaliado',
        tema: nomeTema,
        valor: nivelSrs == 0
            ? 'dificil'
            : nivelSrs == 1
                ? 'medio'
                : 'facil',
        metadata: {'card_id': cardId, 'nivel_srs': nivelSrs},
      ));

  Future<void> quizIniciado(int faseId, String nomeTema, int tentativaN) =>
      _repo.registrar(Evento(
        evento: 'quiz_iniciado',
        tema: nomeTema,
        metadata: {'fase_id': faseId, 'tentativa_n': tentativaN},
      ));

  Future<void> quizQuestaoRespondida({
    required int faseId,
    required int cardId,
    required bool acertou,
    required int tempoS,
    required int pontos,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_questao_respondida',
        tema: nomeTema,
        valor: acertou ? 'acerto' : 'erro',
        metadata: {
          'fase_id': faseId,
          'card_id': cardId,
          'acertou': acertou,
          'tempo_s': tempoS,
          'pontos': pontos,
          'tentativa_n': tentativaN,
        },
      ));

  Future<void> quizConcluido({
    required int faseId,
    required int nota,
    required int estrelas,
    required int tempoTotalS,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_concluido',
        tema: nomeTema,
        valor: '$nota',
        metadata: {
          'fase_id': faseId,
          'nota': nota,
          'estrelas': estrelas,
          'tempo_total_s': tempoTotalS,
          'tentativa_n': tentativaN,
        },
      ));

  Future<void> quizAbandonado({
    required int faseId,
    required int questaoAtual,
    required int totalQuestoes,
    required int tentativaN,
    required String nomeTema,
  }) =>
      _repo.registrar(Evento(
        evento: 'quiz_abandonado',
        tema: nomeTema,
        metadata: {
          'fase_id': faseId,
          'questao_atual': questaoAtual,
          'total_questoes': totalQuestoes,
          'tentativa_n': tentativaN,
        },
      ));
}
