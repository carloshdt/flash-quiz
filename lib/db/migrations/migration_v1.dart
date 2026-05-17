// lib/db/migrations/migration_v1.dart
// Schema completo da versão 1 do banco de dados

class MigrationV1 {
  static Future<void> executar(dynamic db) async {
    await db.execute('''
      CREATE TABLE temas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        icone TEXT NOT NULL,
        desbloqueado INTEGER DEFAULT 1,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE secoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tema_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        ordem INTEGER NOT NULL DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tema_id) REFERENCES temas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE fases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secao_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        ordem INTEGER NOT NULL,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (secao_id) REFERENCES secoes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fase_id INTEGER NOT NULL,
        pergunta TEXT NOT NULL,
        resposta TEXT NOT NULL,
        alternativa_b TEXT NOT NULL,
        alternativa_c TEXT NOT NULL,
        alternativa_d TEXT NOT NULL,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (fase_id) REFERENCES fases(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE progresso_flashcard (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL UNIQUE,
        nivel_srs INTEGER DEFAULT 0,
        total_visto INTEGER DEFAULT 0,
        total_acerto INTEGER DEFAULT 0,
        proxima_revisao DATETIME,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (card_id) REFERENCES cards(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_tentativas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fase_id INTEGER NOT NULL,
        pontuacao INTEGER NOT NULL DEFAULT 0,
        estrelas INTEGER NOT NULL DEFAULT 0,
        tempo_total_segundos INTEGER,
        concluido INTEGER DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (fase_id) REFERENCES fases(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_respostas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tentativa_id INTEGER NOT NULL,
        card_id INTEGER NOT NULL,
        resposta_escolhida TEXT,
        acertou INTEGER DEFAULT 0,
        tempo_segundos INTEGER,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tentativa_id) REFERENCES quiz_tentativas(id),
        FOREIGN KEY (card_id) REFERENCES cards(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE perfil (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT DEFAULT 'Usuário',
        xp_total INTEGER DEFAULT 0,
        nivel INTEGER DEFAULT 1,
        streak_atual INTEGER DEFAULT 0,
        streak_maximo INTEGER DEFAULT 0,
        ultimo_estudo DATE,
        is_premium INTEGER DEFAULT 0,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE eventos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        evento TEXT NOT NULL,
        tema TEXT,
        secao TEXT,
        valor TEXT,
        metadata TEXT,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE conquistas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave TEXT NOT NULL UNIQUE,
        nome TEXT NOT NULL,
        descricao TEXT NOT NULL,
        icone TEXT NOT NULL,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE conquistas_usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conquista_id INTEGER NOT NULL,
        criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (conquista_id) REFERENCES conquistas(id)
      )
    ''');

    // Seed: valores padrão de configuração
    final configs = [
      {'chave': 'quiz_tempo_por_questao', 'valor': '30'},
      {'chave': 'quiz_num_questoes', 'valor': '10'},
      {'chave': 'flashcard_min_percentual_para_quiz', 'valor': '60'},
      {'chave': 'flashcard_cards_por_sessao', 'valor': '20'},
      {'chave': 'xp_por_card_facil', 'valor': '10'},
      {'chave': 'xp_por_card_medio', 'valor': '7'},
      {'chave': 'xp_por_card_dificil', 'valor': '3'},
      {'chave': 'xp_por_quiz_estrela', 'valor': '50'},
      {'chave': 'quiz_max_tentativas_free_por_dia', 'valor': '1'},
    ];
    for (final c in configs) {
      await db.insert('config', c);
    }

    // Seed: conquistas disponíveis
    final conquistas = [
      {'chave': 'primeiro_tema', 'nome': 'Primeiro Passo', 'descricao': 'Iniciou seu primeiro tema', 'icone': '🏁'},
      {'chave': 'streak_7', 'nome': 'Semana Consistente', 'descricao': '7 dias de streak', 'icone': '🔥'},
      {'chave': 'cards_100', 'nome': 'Centenário', 'descricao': 'Viu 100 cards', 'icone': '💯'},
      {'chave': 'quiz_3estrelas', 'nome': 'Perfeito', 'descricao': 'Tirou 5 estrelas num quiz', 'icone': '⭐'},
      {'chave': 'tema_completo', 'nome': 'Mestre', 'descricao': 'Completou todas as fases de um tema', 'icone': '🏆'},
      {'chave': 'streak_30', 'nome': 'Dedicação Total', 'descricao': '30 dias de streak', 'icone': '🎓'},
    ];
    for (final c in conquistas) {
      await db.insert('conquistas', c);
    }

    // Seed: perfil inicial
    await db.insert('perfil', {'nome': 'Usuário'});
  }
}
