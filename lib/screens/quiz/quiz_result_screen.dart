// lib/screens/quiz/quiz_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/quiz_controller.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResultado resultado;

  const QuizResultScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final aprovado = resultado.aprovado;
    final corNota = aprovado ? Colors.white : const Color(0xFFFF5252);
    final estrelas = resultado.estrelas;

    return Scaffold(
      backgroundColor: const Color(0xFF151C35),
      body: SafeArea(
        child: Column(
          children: [
            // Corpo centralizado com score
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Estrelas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Text(
                        i < estrelas ? '⭐' : '☆',
                        style: TextStyle(
                          fontSize: 32,
                          color: i < estrelas
                              ? const Color(0xFFF6C90E)
                              : const Color(0xFF2A3060),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Nota
                  Text(
                    '${resultado.nota}',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: corNota,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'pontos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF90CAF9),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divisor
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3060),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status
                  Text(
                    aprovado
                        ? 'Próxima fase desbloqueada!'
                        : 'Mínimo 70 para avançar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: aprovado
                          ? const Color(0xFF00897B)
                          : const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
            ),

            // Botões
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: aprovado
                          ? () => context.pop() // Continuar → volta para TrilhaScreen
                          : () => context.pushReplacement( // Tentar novamente → novo quiz
                                '/quiz/${resultado.faseId}'
                                '?nomeFase=${Uri.encodeComponent(resultado.nomeFase)}'
                                '&nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                              ),
                      child: Text(
                        aprovado ? 'Continuar →' : 'Tentar novamente',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white),
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
                      onPressed: aprovado
                          ? () => context.pushReplacement( // Refazer quiz → novo quiz
                                '/quiz/${resultado.faseId}'
                                '?nomeFase=${Uri.encodeComponent(resultado.nomeFase)}'
                                '&nomeTema=${Uri.encodeComponent(resultado.nomeTema)}',
                              )
                          : () => context.pop(), // Voltar para trilha
                      child: Text(
                        aprovado ? 'Refazer quiz' : 'Voltar para trilha',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF90CAF9)),
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
