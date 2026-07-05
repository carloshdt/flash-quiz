// lib/screens/desafio/desafio_result_screen.dart
// Resultado do desafio diário em linguagem papel: carimbo FEITO com batida,
// confete quando a nota é alta e score gigante manuscrito.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/desafio_controller.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confete/confete_papel.dart';
import '../../widgets/papel/botao_papel.dart';
import '../../widgets/papel/carimbo_batida.dart';
import '../../widgets/papel/fundo_papel.dart';

class DesafioResultScreen extends StatefulWidget {
  final DesafioResultado resultado;

  const DesafioResultScreen({super.key, required this.resultado});

  @override
  State<DesafioResultScreen> createState() => _DesafioResultScreenState();
}

class _DesafioResultScreenState extends State<DesafioResultScreen> {
  bool _efeitosCarimboTocados = false; // garante som/haptic da batida 1x

  bool get _notaAlta => widget.resultado.nota >= 70;

  @override
  void initState() {
    super.initState();
    if (_notaAlta) {
      context.read<AudioService>().tocar(Som.confete);
    }
  }

  void _onCarimboBatida() {
    if (_efeitosCarimboTocados || !mounted) return;
    _efeitosCarimboTocados = true;
    final audio = context.read<AudioService>();
    audio.tocar(Som.carimbo);
    audio.vibrar(Vibracao.media);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.papel,
      body: FundoPapel(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),

                        // Nota gigante manuscrita
                        Text(
                          '${widget.resultado.nota}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(fontSize: 88, height: 1.0),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'pontos',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.tintaSuave,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Carimbo FEITO — desafio do dia cumprido
                        CarimboBatida(
                          texto: 'FEITO',
                          cor: AppColors.verde,
                          fontSize: 32,
                          onBatida: _onCarimboBatida,
                        ),
                        const SizedBox(height: 24),

                        // Divisor de grão
                        Container(
                          width: 48,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.grao,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Desafio de hoje concluído!\nVolte amanhã para um novo desafio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tinta,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24,
                        24 + MediaQuery.of(context).padding.bottom),
                    child: SizedBox(
                      width: double.infinity,
                      child: BotaoPapel(
                        cor: AppColors.laranja,
                        onPressed: () => context.pop(), // volta para SecoesScreen
                        child: const Center(
                          child: Text(
                            'Voltar ao tema',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confete de papel quando a nota é alta
            if (_notaAlta) const Positioned.fill(child: ConfetePapel()),
          ],
        ),
      ),
    );
  }
}
