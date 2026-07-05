// lib/screens/trilha/widgets/bottom_sheet_quiz.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/trilha_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/botao_papel.dart';

class BottomSheetQuiz extends StatelessWidget {
  final ItemTrilha item;
  final String nomeTema;
  const BottomSheetQuiz(
      {super.key, required this.item, required this.nomeTema});

  // Linha de regra do quiz
  Widget _regra(String icone, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(icone, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.tintaSuave)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final melhor = item.melhorTentativa;
    final temResultado = melhor != null && melhor.concluido;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.papel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.grao,
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
                  color: AppColors.verde,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('📝', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz — ${item.fase.nome}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.tinta),
                  ),
                  const Text('Fase de avaliação',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.tintaSuave)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Melhor resultado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cartao,
              border: Border.all(color: AppColors.grao),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Melhor resultado',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.tintaSuave)),
                Text(
                  temResultado
                      ? '${'★' * melhor.estrelas}${'☆' * (5 - melhor.estrelas)} ${melhor.pontuacao}pts'
                      : 'Nenhum resultado ainda',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        temResultado ? AppColors.tinta : AppColors.tintaSuave,
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
            child: BotaoPapel(
              cor: AppColors.verde,
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  '/quiz/${item.fase.id}'
                  '?nomeFase=${Uri.encodeComponent(item.fase.nome)}'
                  '&nomeTema=${Uri.encodeComponent(nomeTema)}',
                );
              },
              child: const Center(child: Text('▶ Iniciar Quiz')),
            ),
          ),
        ],
      ),
    );
  }
}
