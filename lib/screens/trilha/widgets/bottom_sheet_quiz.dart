// lib/screens/trilha/widgets/bottom_sheet_quiz.dart
// Stub — implementação completa no Plano Task 10
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class BottomSheetQuiz extends StatelessWidget {
  final ItemTrilha item;
  const BottomSheetQuiz({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quiz — ${item.fase.nome}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
              onPressed: () => Navigator.pop(context),
              child: const Text('▶ Iniciar Quiz', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
