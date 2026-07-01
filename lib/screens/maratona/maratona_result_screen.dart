// lib/screens/maratona/maratona_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/maratona_controller.dart';
import '../../theme/app_theme.dart';

class MaratonaResultScreen extends StatelessWidget {
  final MaratonaResultado resultado;

  const MaratonaResultScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(resultado.recordeBatido ? '🏆' : '🏃',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${resultado.score}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'acertos',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3060),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    resultado.recordeBatido
                        ? 'Novo recorde! 🎉'
                        : 'Recorde: ${resultado.recorde}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: resultado.recordeBatido ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pushReplacement(
                        '/maratona/${resultado.temaId}'
                        '?nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                      ),
                      child: const Text(
                        'Jogar de novo',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A3060)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Voltar ao tema',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
