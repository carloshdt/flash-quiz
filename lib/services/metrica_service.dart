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

  // ---- Modos de estudo ----

  Future<void> desafioIniciado(int temaId, String nomeTema, int numQuestoes) =>
      _repo.registrar(Evento(
        evento: 'desafio_iniciado',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'num_questoes': numQuestoes},
      ));

  Future<void> desafioConcluido({
    required int temaId,
    required String nomeTema,
    required int nota,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'desafio_concluido',
        tema: nomeTema,
        valor: '$nota',
        metadata: {'tema_id': temaId, 'nota': nota, 'tempo_total_s': tempoTotalS},
      ));

  Future<void> desafioAbandonado({
    required int temaId,
    required String nomeTema,
    required int questaoAtual,
    required int totalQuestoes,
  }) =>
      _repo.registrar(Evento(
        evento: 'desafio_abandonado',
        tema: nomeTema,
        metadata: {
          'tema_id': temaId,
          'questao_atual': questaoAtual,
          'total_questoes': totalQuestoes,
        },
      ));

  Future<void> revisaoIniciada(int temaId, String nomeTema, int cardsVencidos) =>
      _repo.registrar(Evento(
        evento: 'revisao_iniciada',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'cards_vencidos': cardsVencidos},
      ));

  Future<void> revisaoConcluida({
    required int temaId,
    required String nomeTema,
    required int cardsRevisados,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'revisao_concluida',
        tema: nomeTema,
        metadata: {
          'tema_id': temaId,
          'cards_revisados': cardsRevisados,
          'tempo_total_s': tempoTotalS,
        },
      ));

  Future<void> maratonaIniciada(int temaId, String nomeTema) =>
      _repo.registrar(Evento(
        evento: 'maratona_iniciada',
        tema: nomeTema,
        metadata: {'tema_id': temaId},
      ));

  Future<void> maratonaConcluida({
    required int temaId,
    required String nomeTema,
    required int score,
    required bool recordeBatido,
    required int tempoTotalS,
  }) =>
      _repo.registrar(Evento(
        evento: 'maratona_concluida',
        tema: nomeTema,
        valor: '$score',
        metadata: {
          'tema_id': temaId,
          'score': score,
          'recorde_batido': recordeBatido,
          'tempo_total_s': tempoTotalS,
        },
      ));

  Future<void> maratonaAbandonada({
    required int temaId,
    required String nomeTema,
    required int scoreParcial,
  }) =>
      _repo.registrar(Evento(
        evento: 'maratona_abandonada',
        tema: nomeTema,
        metadata: {'tema_id': temaId, 'score_parcial': scoreParcial},
      ));

  // ---- Áudio e haptics ----

  Future<void> somToggled(bool ativo) => _repo.registrar(Evento(
        evento: 'som_toggled',
        valor: ativo ? 'on' : 'off',
      ));

  Future<void> hapticsToggled(bool ativo) => _repo.registrar(Evento(
        evento: 'haptics_toggled',
        valor: ativo ? 'on' : 'off',
      ));
}
