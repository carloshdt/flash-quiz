// lib/widgets/tema_card_widget.dart
import 'package:flutter/material.dart';
import '../models/tema.dart';
import '../theme/app_theme.dart';

class TemaCardWidget extends StatelessWidget {
  final Tema tema;
  final VoidCallback onTap;

  const TemaCardWidget({super.key, required this.tema, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bloqueado = !tema.desbloqueado;
    final accent = AppColors.accentFor(tema.id);

    return GestureDetector(
      onTap: bloqueado ? null : onTap,
      child: Opacity(
        opacity: bloqueado ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(tema.icone, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  tema.nome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              bloqueado
                  ? Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.25), size: 16)
                  : Text(
                      '›',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withValues(alpha: 0.3),
                        height: 1,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
