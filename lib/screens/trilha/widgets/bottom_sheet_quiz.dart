// lib/screens/trilha/widgets/bottom_sheet_quiz.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/trilha_controller.dart';

class BottomSheetQuiz extends StatelessWidget {
  final ItemTrilha item;
  final String nomeTema;
  const BottomSheetQuiz({super.key, required this.item, required this.nomeTema});

  // Linha de regra do quiz
  Widget _regra(String icone, String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(icone, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: const TextStyle(fontSize: 11, color: Color(0xFFB0BEC5))),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final melhor = item.melhorTentativa;

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

          // Header: ícone + título
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('📝', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz — ${item.fase.nome}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                  ),
                  const Text('Fase de avaliação', style: TextStyle(fontSize: 10, color: Color(0xFF80CBC4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Melhor resultado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2448),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Melhor resultado', style: TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
                Text(
                  melhor != null && melhor.concluido
                      ? '${'★' * melhor.estrelas}${'☆' * (5 - melhor.estrelas)} ${melhor.pontuacao}pts'
                      : 'Nenhum resultado ainda',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: melhor != null && melhor.concluido
                        ? const Color(0xFFF6C90E)
                        : const Color(0xFF546E7A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Regras do quiz (valores padrão — Plano 3 carrega via ConfigRepository)
          _regra('⏱️', '30 segundos por questão'),
          _regra('🔀', '10 questões aleatórias do banco'),
          _regra('⚠️', 'Sair no meio conta como tentativa abandonada'),
          _regra('🔁', 'Pode refazer quantas vezes quiser'),

          const SizedBox(height: 12),

          // Botão iniciar quiz
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  '/quiz/${item.fase.id}'
                  '?nomeFase=${Uri.encodeComponent(item.fase.nome)}'
                  '&nomeTema=${Uri.encodeComponent(nomeTema)}',
                );
              },
              child: const Text(
                '▶ Iniciar Quiz',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
