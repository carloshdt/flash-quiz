// lib/theme/app_theme.dart
// Design system "Recorte & Cola" — scrapbook de papel claro.
// Fundação: papel creme + tinta quase-preta. Acentos vivos usados com parcimônia.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Fundação
  static const Color papel = Color(0xFFF2EDE4);      // fundo geral — papel creme
  static const Color cartao = Color(0xFFFFFFFF);     // superfícies/cards
  static const Color papelVerso = Color(0xFFFFFDF7); // verso do flashcard — creme quase-branco
  static const Color tinta = Color(0xFF33302A);      // texto principal
  static const Color tintaSuave = Color(0xFF8A8378); // texto secundário — lápis
  static const Color grao = Color(0xFFD8D0C0);       // grão do papel, divisores

  // Acentos
  static const Color laranja = Color(0xFFFF5C39); // CTA, energia
  static const Color verde = Color(0xFF5CB270);   // sucesso, aprovado
  static const Color amarelo = Color(0xFFF7D046); // post-its, estrelas
  static const Color azul = Color(0xFF4DA6FF);    // info
  static const Color rosa = Color(0xFFFF9EBB);    // carinho
  static const Color tealPapel = Color(0xFF7FDBCA); // teal papel (maratona)
  static const Color postItLaranja = Color(0xFFFFE0B2); // post-it laranja-claro (streak)
  static const Color postItAzul = Color(0xFFB8E0F5);    // post-it azul-claro (revisão)
  static const Color postItVerde = Color(0xFFC8E6C9);   // post-it verde-claro (maratona)

  static const List<Color> _accents = [
    laranja,
    verde,
    azul,
    rosa,
    amarelo,
    Color(0xFFB48CD9), // roxo suave
    tealPapel,         // teal
    Color(0xFFFF8A7A), // coral
  ];

  static Color accentFor(int id) => _accents[id % _accents.length];

  // COMPAT — remover na task final de limpeza (aliases pro código antigo compilar)
  static const Color background = papel;
  static const Color surface = cartao;
  static const Color headerBg = papel;
  static const Color sheetBg = cartao;
  static const Color purple = laranja;
  static const Color orange = laranja;
  static const Color gold = amarelo;
  static const Color teal = tealPapel;
  static const Color textSecondary = tintaSuave;
  static const Color divider = grao;
}

class AppTheme {
  AppTheme._();

  /// Tema claro único do app. Patrick Hand em títulos, Nunito no corpo.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.papel,
      cardColor: AppColors.cartao, // Card cru rende cartão branco, não papel
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.laranja,
        brightness: Brightness.light,
        surface: AppColors.papel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.papel,
        foregroundColor: AppColors.tinta,
        elevation: 0,
        centerTitle: false,
      ),
      splashFactory: NoSplash.splashFactory, // pressão de papel substitui ripple
      highlightColor: Colors.transparent,
    );

    final corpo = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.tinta,
      displayColor: AppColors.tinta,
    );

    // Títulos manuscritos
    final titulos = GoogleFonts.patrickHand(color: AppColors.tinta);

    return base.copyWith(
      textTheme: corpo.copyWith(
        displayLarge: titulos.copyWith(fontSize: 40),
        displayMedium: titulos.copyWith(fontSize: 32),
        headlineLarge: titulos.copyWith(fontSize: 28),
        headlineMedium: titulos.copyWith(fontSize: 24),
        titleLarge: titulos.copyWith(fontSize: 22),
        titleMedium: titulos.copyWith(fontSize: 18),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: titulos.copyWith(fontSize: 24),
      ),
    );
  }

  /// Fonte pixel usada apenas no contexto do bichinho.
  static TextStyle pixel({double fontSize = 14, Color color = AppColors.tinta}) =>
      GoogleFonts.vt323(fontSize: fontSize, color: color);
}
