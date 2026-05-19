// lib/widgets/tema_card_widget.dart
import 'package:flutter/material.dart';
import '../models/tema.dart';

class TemaCardWidget extends StatelessWidget {
  final Tema tema;
  final VoidCallback onTap;

  const TemaCardWidget({super.key, required this.tema, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bloqueado = !tema.desbloqueado;

    return GestureDetector(
      onTap: bloqueado ? null : onTap,
      child: Opacity(
        opacity: bloqueado ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A237E)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(tema.icone, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tema.nome,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(
                      bloqueado ? 'Em breve' : 'Toque para estudar',
                      style: TextStyle(
                        fontSize: 11,
                        color: bloqueado ? const Color(0xFF666688) : const Color(0xFF90CAF9),
                      ),
                    ),
                  ],
                ),
              ),
              bloqueado
                  ? const Icon(Icons.lock_outline, color: Color(0xFF444466), size: 18)
                  : const Icon(Icons.chevron_right, color: Color(0xFF7C4DFF)),
            ],
          ),
        ),
      ),
    );
  }
}
