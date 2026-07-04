// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/papel/entrada_cascata.dart';
import '../../widgets/papel/fundo_papel.dart';
import '../../widgets/papel/post_it.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/xp_bar_widget.dart';
import '../../widgets/tema_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _xpProximoNivel(int nivel) => nivel * 1000;

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.papel,
      body: FundoPapel(
        child: SafeArea(
          child: ctrl.carregando
              ? const Center(child: CircularProgressIndicator(color: AppColors.laranja))
              : RefreshIndicator(
                  onRefresh: ctrl.carregar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    children: [
                      // Header personalizado
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 18, 4, 22),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Olá,',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.tintaSuave,
                                    ),
                                  ),
                                  Text(
                                    'Carlos 👋',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(height: 1.1),
                                  ),
                                ],
                              ),
                            ),
                            if (ctrl.perfil != null)
                              PostIt(
                                child: Text(
                                  '⚡ ${_formatXP(ctrl.perfil!.xpTotal)} XP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tinta,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Streak + barra XP
                      if (ctrl.perfil != null) ...[
                        StreakCard(streak: ctrl.perfil!.streakAtual),
                        const SizedBox(height: 10),
                        XpBarWidget(
                          nivel: ctrl.perfil!.nivel,
                          xpAtual: ctrl.perfil!.xpTotal,
                          xpProximo: _xpProximoNivel(ctrl.perfil!.nivel),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Label seção
                      const Text(
                        'SEUS TEMAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.tintaSuave,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Cards de tema com entrada em cascata
                      ...ctrl.temas.asMap().entries.map((entry) {
                        final i = entry.key;
                        final tema = entry.value;
                        return EntradaCascata(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TemaCardWidget(
                              tema: tema,
                              bichinho: ctrl.bichinhos[tema.id],
                              humor: ctrl.humores[tema.id],
                              onTap: () => context.push(
                                '/tema/${tema.id}/secoes?nome=${Uri.encodeComponent(tema.nome)}',
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
