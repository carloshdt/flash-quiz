// lib/widgets/streak_card.dart
import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  const StreakCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🔥 Streak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(
            '$streak dias',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
