// lib/screens/desafio/desafio_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/desafio_controller.dart';
import '../../theme/app_theme.dart';

class DesafioResultScreen extends StatelessWidget {
  final DesafioResultado resultado;

  const DesafioResultScreen({super.key, required this.resultado});

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
                  const Text('⚡', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${resultado.nota}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'pontos',
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
                  const Text(
                    'Desafio de hoje concluído!\nVolte amanhã para um novo desafio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.pop(), // volta para SecoesScreen
                  child: const Text(
                    'Voltar ao tema',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
