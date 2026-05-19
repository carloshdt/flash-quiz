// lib/db/migrations/migration_v3.dart
// Adiciona coluna icone em secoes e popula ícones do CFC

class MigrationV3 {
  static Future<void> executar(dynamic db) async {
    await db.execute("ALTER TABLE secoes ADD COLUMN icone TEXT NOT NULL DEFAULT '📚'");

    final iconesPorNome = {
      'Geral': '📚',
      'Placas e Sinais': '🚦',
      'Legislação': '⚖️',
      'Direção Defensiva': '🛡️',
      'Primeiros Socorros': '🚑',
      'Mecânica Básica': '🔧',
    };

    for (final entry in iconesPorNome.entries) {
      await db.execute(
        "UPDATE secoes SET icone = ? WHERE nome = ?",
        [entry.value, entry.key],
      );
    }
  }
}
