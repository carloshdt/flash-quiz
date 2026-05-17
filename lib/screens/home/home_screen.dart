// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/xp_bar_widget.dart';
import '../../widgets/tema_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // XP necessário por nível (nível * 1000)
  int _xpProximoNivel(int nivel) => nivel * 1000;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFF12122A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        elevation: 0,
        title: const Text('FlashQuiz', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {}, // Plano 4: tela de perfil
          ),
        ],
      ),
      body: ctrl.carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : RefreshIndicator(
              onRefresh: ctrl.carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (ctrl.perfil != null) ...[
                    StreakCard(streak: ctrl.perfil!.streakAtual),
                    const SizedBox(height: 10),
                    XpBarWidget(
                      nivel: ctrl.perfil!.nivel,
                      xpAtual: ctrl.perfil!.xpTotal,
                      xpProximo: _xpProximoNivel(ctrl.perfil!.nivel),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'TEMAS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ctrl.temas.map((tema) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TemaCardWidget(
                      tema: tema,
                      onTap: () => context.push(
                        '/tema/${tema.id}/secoes?nome=${Uri.encodeComponent(tema.nome)}',
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}
