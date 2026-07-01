// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'controllers/desafio_controller.dart';
import 'controllers/flashcard_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/maratona_controller.dart';
import 'controllers/revisao_controller.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/secoes_controller.dart';
import 'controllers/trilha_controller.dart';
import 'screens/desafio/desafio_result_screen.dart';
import 'screens/desafio/desafio_screen.dart';
import 'screens/flashcard/flashcard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/maratona/maratona_result_screen.dart';
import 'screens/maratona/maratona_screen.dart';
import 'screens/revisao/revisao_screen.dart';
import 'screens/quiz/quiz_result_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/secoes/secoes_screen.dart';
import 'screens/trilha/trilha_screen.dart';

// Observer para telas que precisam recarregar ao voltar ao topo da pilha
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final _router = GoRouter(
  observers: [routeObserver],
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
    GoRoute(
      path: '/quiz/:faseId',
      builder: (_, state) {
        final faseId = int.parse(state.pathParameters['faseId']!);
        final nomeFase = state.uri.queryParameters['nomeFase'] ?? '';
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => QuizController(),
          child: QuizScreen(
            faseId: faseId,
            nomeFase: nomeFase,
            nomeTema: nomeTema,
          ),
        );
      },
    ),
    GoRoute(
      path: '/quiz-resultado',
      builder: (_, state) {
        final resultado = state.extra as QuizResultado;
        return QuizResultScreen(resultado: resultado);
      },
    ),
    GoRoute(
      path: '/desafio/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => DesafioController(),
          child: DesafioScreen(temaId: temaId, nomeTema: nomeTema),
        );
      },
    ),
    GoRoute(
      path: '/desafio-resultado',
      builder: (_, state) {
        final resultado = state.extra as DesafioResultado;
        return DesafioResultScreen(resultado: resultado);
      },
    ),
    GoRoute(
      path: '/maratona/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => MaratonaController(),
          child: MaratonaScreen(temaId: temaId, nomeTema: nomeTema),
        );
      },
    ),
    GoRoute(
      path: '/maratona-resultado',
      builder: (_, state) {
        final resultado = state.extra as MaratonaResultado;
        return MaratonaResultScreen(resultado: resultado);
      },
    ),
    GoRoute(
      path: '/revisao/:temaId',
      builder: (_, state) {
        final temaId = int.parse(state.pathParameters['temaId']!);
        final nomeTema = state.uri.queryParameters['nomeTema'] ?? '';
        return ChangeNotifierProvider(
          create: (_) => RevisaoController(),
          child: RevisaoScreen(temaId: temaId, nomeTema: nomeTema),
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
          scaffoldBackgroundColor: const Color(0xFF151C35),
          textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
