// lib/screens/quiz/widgets/quiz_alternativas.dart
// Lista A/B/C/D como tiras de papel — selecionada ganha borda laranja.
import 'package:flutter/material.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/papel/papel_util.dart';

class QuizAlternativas extends StatelessWidget {
  final List<String> alternativas;
  final int? respostaSelecionada;
  final bool desabilitada;
  final ValueChanged<int> onSelecionar;

  const QuizAlternativas({
    super.key,
    required this.alternativas,
    required this.respostaSelecionada,
    required this.desabilitada,
    required this.onSelecionar,
  });

  void _tocar(BuildContext context, int indice) {
    // Haptic via AudioService — respeita o toggle haptics_ativo
    vibrarSeDisponivel(context, Vibracao.leve);
    onSelecionar(indice);
  }

  @override
  Widget build(BuildContext context) {
    const letras = ['A', 'B', 'C', 'D'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: alternativas.length,
      itemBuilder: (_, i) {
        final selecionadaEsta = respostaSelecionada == i;
        // Tira de papel torta: rotação alternada ±0.5°
        return Transform.rotate(
          angle: grausParaRad(i.isEven ? 0.5 : -0.5),
          child: GestureDetector(
            onTap: desabilitada ? null : () => _tocar(context, i),
            child: Opacity(
              // Desabilitada esmaece, mas a selecionada segue legível
              opacity: desabilitada && !selecionadaEsta ? 0.5 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selecionadaEsta
                      ? AppColors.laranjaClaro
                      : AppColors.cartao,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: selecionadaEsta ? AppColors.laranja : AppColors.grao,
                    width: selecionadaEsta ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x26000000),
                        offset: Offset(1, 2),
                        blurRadius: 0),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      letras[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selecionadaEsta
                            ? AppColors.laranja
                            : AppColors.tintaSuave,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alternativas[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.tinta,
                          fontWeight: selecionadaEsta
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
