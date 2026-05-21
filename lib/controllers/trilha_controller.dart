// lib/controllers/trilha_controller.dart
import 'package:flutter/foundation.dart';
import '../models/fase.dart';
import '../models/quiz_tentativa.dart';
import '../repositories/card_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/fase_repository.dart';
import '../repositories/progresso_repository.dart';
import '../repositories/quiz_repository.dart';

class ItemTrilha {
  final bool ehQuiz;
  final Fase fase;
  final int totalCards;
  final int cardsVistos;
  final QuizTentativa? melhorTentativa;
  final bool desbloqueado;

  ItemTrilha({
    required this.ehQuiz,
    required this.fase,
    this.totalCards = 0,
    this.cardsVistos = 0,
    this.melhorTentativa,
    this.desbloqueado = false,
  });

  bool get concluido => ehQuiz
      ? (melhorTentativa?.concluido ?? false) &&
          (melhorTentativa?.pontuacao ?? 0) >= 70
      : cardsVistos >= totalCards && totalCards > 0;

  bool get emAndamento => !concluido && desbloqueado;

  double get percentualVisto =>
      totalCards > 0 ? cardsVistos / totalCards : 0.0;
}

class TrilhaController extends ChangeNotifier {
  final FaseRepository _faseRepo;
  final CardRepository _cardRepo;
  final ProgressoRepository _progressoRepo;
  final ConfigRepository _configRepo;
  final QuizRepository _quizRepo;

  List<ItemTrilha> itens = [];
  bool carregando = false;

  TrilhaController({
    FaseRepository? faseRepo,
    CardRepository? cardRepo,
    ProgressoRepository? progressoRepo,
    ConfigRepository? configRepo,
    QuizRepository? quizRepo,
  })  : _faseRepo = faseRepo ?? FaseRepository(),
        _cardRepo = cardRepo ?? CardRepository(),
        _progressoRepo = progressoRepo ?? ProgressoRepository(),
        _configRepo = configRepo ?? ConfigRepository(),
        _quizRepo = quizRepo ?? QuizRepository();

  Future<void> carregar(int secaoId) async {
    carregando = true;
    notifyListeners();

    final fases = await _faseRepo.getFasesPorSecao(secaoId);
    final minPercentual = await _configRepo.getValorInt(
        'flashcard_min_percentual_para_quiz',
        padrao: 60);

    final novosItens = <ItemTrilha>[];

    for (int i = 0; i < fases.length; i++) {
      final fase = fases[i];
      final total = await _cardRepo.contarCardsPorFase(fase.id);
      final vistos = await _progressoRepo.getCardsVistosCount(fase.id);
      final melhor = await _quizRepo.melhorTentativa(fase.id);

      final desbloqueadaFlashcard =
          i == 0 || (novosItens.isNotEmpty && novosItens.last.concluido);

      final itemFlashcard = ItemTrilha(
        ehQuiz: false,
        fase: fase,
        totalCards: total,
        cardsVistos: vistos,
        desbloqueado: desbloqueadaFlashcard,
      );
      novosItens.add(itemFlashcard);

      final percentualAtingido =
          total > 0 && (vistos / total) >= (minPercentual / 100.0);
      novosItens.add(ItemTrilha(
        ehQuiz: true,
        fase: fase,
        totalCards: total,
        cardsVistos: vistos,
        melhorTentativa: melhor,
        desbloqueado: desbloqueadaFlashcard && percentualAtingido,
      ));
    }

    itens = novosItens;
    carregando = false;
    notifyListeners();
  }
}
