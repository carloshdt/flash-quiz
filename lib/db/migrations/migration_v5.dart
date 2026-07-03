// lib/db/migrations/migration_v5.dart
// Tabela bichinhos (bichinho virtual por tema) + configs de energia/evolução e toggles de som/haptics

class MigrationV5 {
  static Future<void> executar(dynamic db) async {
    await db.execute('''
      CREATE TABLE bichinhos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tema_id INTEGER NOT NULL UNIQUE,
        especie INTEGER NOT NULL,
        estagio INTEGER NOT NULL DEFAULT 0,
        energia INTEGER NOT NULL DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tema_id) REFERENCES temas(id)
      )
    ''');

    final configs = [
      {'chave': 'bichinho_energia_card', 'valor': '2'},
      {'chave': 'bichinho_energia_quiz', 'valor': '15'},
      {'chave': 'bichinho_energia_modo', 'valor': '10'},
      {'chave': 'bichinho_threshold_1', 'valor': '50'},
      {'chave': 'bichinho_threshold_2', 'valor': '200'},
      {'chave': 'bichinho_threshold_3', 'valor': '500'},
      {'chave': 'bichinho_threshold_4', 'valor': '1000'},
      {'chave': 'bichinho_streak_multiplicador', 'valor': '1.5'},
      {'chave': 'bichinho_dias_fome', 'valor': '2'},
      {'chave': 'bichinho_dias_dormindo', 'valor': '7'},
      {'chave': 'som_ativo', 'valor': '1'},
      {'chave': 'haptics_ativo', 'valor': '1'},
    ];
    for (final c in configs) {
      await db.insert('config', c);
    }
  }
}
