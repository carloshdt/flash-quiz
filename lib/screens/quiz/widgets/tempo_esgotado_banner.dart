// lib/screens/quiz/widgets/tempo_esgotado_banner.dart
// Post-it laranja: tempo acabou, toque pra avançar (0 pts).
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/post_it.dart';

class TempoEsgotadoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const TempoEsgotadoBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: PostIt(
          cor: AppColors.postItLaranja,
          angulo: -1,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Tempo esgotado!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.tinta),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Toque para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.tintaSuave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
