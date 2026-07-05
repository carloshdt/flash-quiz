// lib/screens/quiz/widgets/estado_vazio_modo.dart
// Estado vazio dos modos (desafio/maratona): pool sem cards desbloqueados.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/botao_papel.dart';

class EstadoVazioModo extends StatelessWidget {
  final String mensagem;
  final VoidCallback onVoltar;

  const EstadoVazioModo({
    super.key,
    required this.mensagem,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📖', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Nada por aqui ainda',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.tintaSuave),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: BotaoPapel(
                  onPressed: onVoltar,
                  child: const Center(child: Text('Voltar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
