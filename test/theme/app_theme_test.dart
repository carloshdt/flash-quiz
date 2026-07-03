// test/theme/app_theme_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/theme/app_theme.dart';

void main() {
  // GoogleFonts consulta o AssetManifest ao montar o TextTheme.
  TestWidgetsFlutterBinding.ensureInitialized();

  // GoogleFonts dispara download das fontes em background, que falha em
  // ambiente de teste (sem rede). Computamos o tema uma única vez numa zona
  // guardada pra esses erros assíncronos não vazarem pros testes — os asserts
  // só inspecionam o ThemeData, não dependem da fonte carregada.
  late final ThemeData tema;
  runZonedGuarded(
    () => tema = AppTheme.light,
    (_, __) {}, // erro de fetch de fonte é esperado e irrelevante aqui
  );

  group('AppColors Recorte & Cola', () {
    test('cores da fundação existem com valores da spec', () {
      expect(AppColors.papel, const Color(0xFFF2EDE4));
      expect(AppColors.cartao, const Color(0xFFFFFFFF));
      expect(AppColors.tinta, const Color(0xFF33302A));
      expect(AppColors.tintaSuave, const Color(0xFF8A8378));
      expect(AppColors.grao, const Color(0xFFD8D0C0));
    });

    test('acentos existem com valores da spec', () {
      expect(AppColors.laranja, const Color(0xFFFF5C39));
      expect(AppColors.verde, const Color(0xFF5CB270));
      expect(AppColors.amarelo, const Color(0xFFF7D046));
      expect(AppColors.azul, const Color(0xFF4DA6FF));
      expect(AppColors.rosa, const Color(0xFFFF9EBB));
    });

    test('accentFor cicla e é determinístico', () {
      expect(AppColors.accentFor(0), AppColors.accentFor(8));
      expect(AppColors.accentFor(1), isNot(AppColors.accentFor(2)));
    });
  });

  group('AppTheme.light', () {
    test('é tema claro com fundo papel', () {
      expect(tema.brightness, Brightness.light);
      expect(tema.scaffoldBackgroundColor, AppColors.papel);
    });

    test('AppBar usa papel sem elevação', () {
      expect(tema.appBarTheme.backgroundColor, AppColors.papel);
      expect(tema.appBarTheme.elevation, 0);
    });

    test('ripple desativado — pressão de papel substitui', () {
      expect(tema.splashFactory, NoSplash.splashFactory);
    });

    test('títulos usam Patrick Hand', () {
      expect(tema.textTheme.titleLarge!.fontFamily, contains('PatrickHand'));
    });

    test('Card cru usa cor cartão', () {
      expect(tema.cardColor, AppColors.cartao);
    });
  });
}
