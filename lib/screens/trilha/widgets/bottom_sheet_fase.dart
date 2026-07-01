// lib/screens/trilha/widgets/bottom_sheet_fase.dart
import 'package:flutter/material.dart';
import '../../../controllers/trilha_controller.dart';

class BottomSheetFase extends StatelessWidget {
  final ItemTrilha item;
  final VoidCallback onIniciar;
  const BottomSheetFase({super.key, required this.item, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final percentual = (item.percentualVisto * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C2040),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Título da fase
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.fase.nome,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),

          // Barra de progresso dos cards vistos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$percentual% dos cards vistos',
                style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9)),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.percentualVisto.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1A2060),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botão iniciar ou continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onIniciar();
              },
              child: Text(
                item.cardsVistos > 0 ? '▶ Continuar Flashcards' : '▶ Iniciar Flashcards',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
