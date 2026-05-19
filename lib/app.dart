// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'controllers/flashcard_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/secoes_controller.dart';
import 'controllers/trilha_controller.dart';
import 'screens/flashcard/flashcard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/secoes/secoes_screen.dart';
import 'screens/trilha/trilha_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tema/:temaId/secoes',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nome'] ?? '';
        return SecoesScreen(temaId: temaId, nomeTema: nomeTema);
      },
    ),
    GoRoute(
      path: '/tema/:temaId/secao/:secaoId/trilha',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final secaoId = int.parse(state.pathParameters['secaoId']!);
        final nomeSecao = state.uri.queryParameters['nomeSecao'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return TrilhaScreen(
          temaId: temaId,
          secaoId: secaoId,
          nomeSecao: nomeSecao,
          nomeTema: nomeTema,
        );
      },
    ),
    GoRoute(
      path: '/flashcard/:faseId',
      builder: (_, state) {
        final faseId = int.parse(state.pathParameters['faseId']!);
        final nomeFase = state.uri.queryParameters['nomeFase'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return FlashcardScreen(
          faseId: faseId,
          nomeFase: nomeFase,
          nomeTema: nomeTema,
        );
      },
    ),
  ],
);

class FlashQuizApp extends StatelessWidget {
  const FlashQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => SecoesController()),
        ChangeNotifierProvider(create: (_) => TrilhaController()),
        ChangeNotifierProvider(create: (_) => FlashcardController()),
      ],
      child: MaterialApp.router(
        title: 'FlashQuiz',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C4DFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
