// lib/db/migrations/migration_v4.dart
// Tabela modo_tentativas (Desafio Diário e Maratona) + configs dos modos de estudo

class MigrationV4 {
  static Future<void> executar(dynamic db) async {
    await db.execute('''
      CREATE TABLE modo_tentativas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modo TEXT NOT NULL,
        tema_id INTEGER NOT NULL,
        pontuacao INTEGER NOT NULL DEFAULT 0,
        tempo_total_segundos INTEGER,
        concluido INTEGER DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tema_id) REFERENCES temas(id)
      )
    ''');

    final configs = [
      {'chave': 'desafio_num_questoes', 'valor': '5'},
      {'chave': 'revisao_max_cards', 'valor': '20'},
      {'chave': 'maratona_max_erros', 'valor': '3'},
    ];
    for (final c in configs) {
      await db.insert('config', c);
    }
  }
}
