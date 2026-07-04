// lib/widgets/streak_card.dart
// Streak como post-it laranja-claro: 🔥 grande + dias em Patrick Hand.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'papel/post_it.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  const StreakCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return PostIt(
      cor: AppColors.postItLaranja,
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sequência ativa',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.tinta),
                ),
                const Text(
                  'Continue hoje!',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tintaSuave,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$streak ${streak == 1 ? 'dia' : 'dias'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.tinta,
                  fontSize: 22,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}
