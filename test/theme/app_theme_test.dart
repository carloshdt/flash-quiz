// test/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashquiz/theme/app_theme.dart';

void main() {
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
}
