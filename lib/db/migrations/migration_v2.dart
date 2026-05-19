// lib/db/migrations/migration_v2.dart
// Adiciona temas mockados "Em breve"

class MigrationV2 {
  static Future<void> executar(dynamic db) async {
    final temasMock = [
      {'nome': 'Conhecimentos Gerais', 'icone': '🌍', 'desbloqueado': 0},
      {'nome': 'História do Brasil', 'icone': '🏛️', 'desbloqueado': 0},
      {'nome': 'Inglês', 'icone': '🇺🇸', 'desbloqueado': 0},
    ];
    for (final t in temasMock) {
      await db.insert('temas', t);
    }
  }
}
