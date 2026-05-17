// lib/controllers/trilha_controller.dart
import 'package:flutter/foundation.dart';
import '../models/fase.dart';
import '../models/quiz_tentativa.dart';
import '../repositories/fase_repository.dart';
import '../repositories/card_repository.dart';

// Representa um item na trilha: pode ser fase de flashcard ou nó de quiz
class ItemTrilha {
  final bool ehQuiz; // false = flashcard, true = quiz
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
      ? (melhorTentativa?.concluido ?? false) && (melhorTentativa?.pontuacao ?? 0) >= 70
      : cardsVistos >= totalCards && totalCards > 0;

  bool get emAndamento => !concluido && desbloqueado;

  double get percentualVisto =>
      totalCards > 0 ? cardsVistos / totalCards : 0.0;
}

class TrilhaController extends ChangeNotifier {
  final FaseRepository _faseRepo;
  final CardRepository _cardRepo;

  List<ItemTrilha> itens = [];
  bool carregando = false;

  TrilhaController({FaseRepository? faseRepo, CardRepository? cardRepo})
      : _faseRepo = faseRepo ?? FaseRepository(),
        _cardRepo = cardRepo ?? CardRepository();

  Future<void> carregar(int secaoId) async {
    carregando = true;
    notifyListeners();

    final fases = await _faseRepo.getFasesPorSecao(secaoId);
    final novosItens = <ItemTrilha>[];

    for (int i = 0; i < fases.length; i++) {
      final fase = fases[i];
      final total = await _cardRepo.contarCardsPorFase(fase.id);
      // Primeira fase sempre desbloqueada; as seguintes dependem do quiz anterior
      final desbloqueada = i == 0 ||
          (novosItens.isNotEmpty && novosItens.last.concluido);

      // Nó de flashcard
      novosItens.add(ItemTrilha(
        ehQuiz: false,
        fase: fase,
        totalCards: total,
        cardsVistos: 0, // Plano 2: buscar de progresso_flashcard
        desbloqueado: desbloqueada,
      ));

      // Nó de quiz (sempre após o flashcard da mesma fase)
      novosItens.add(ItemTrilha(
        ehQuiz: true,
        fase: fase,
        totalCards: total,
        cardsVistos: 0,
        desbloqueado: desbloqueada, // Plano 3: checar percentual real
      ));
    }

    itens = novosItens;
    carregando = false;
    notifyListeners();
  }
}
