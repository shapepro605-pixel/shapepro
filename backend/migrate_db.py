import os
from database import db
from sqlalchemy import text

def migrate():
    """Manual migration script to add missing columns to SQLite."""
    print("[MIGRATE] 🚀 Iniciando migração manual do banco de dados...")
    
    # Lista de colunas para verificar/adicionar
    # (Tabela, Coluna, Tipo)
    migrations = [
        ('users', 'telefone', 'VARCHAR(30)'),
        ('users', 'telefone_verificado', 'BOOLEAN DEFAULT 0'),
        ('users', 'otp_code', 'VARCHAR(10)'),
        ('users', 'is_admin', 'BOOLEAN DEFAULT 0'),
        ('users', 'is_active', 'BOOLEAN DEFAULT 1'),
        ('users', 'cartao_cadastrado', 'BOOLEAN DEFAULT 0'),
        ('users', 'data_vencimento', 'DATETIME'),
        ('users', 'streak_atual', 'INTEGER DEFAULT 0'),
        ('users', 'melhor_streak', 'INTEGER DEFAULT 0'),
        ('users', 'ultimo_treino_data', 'DATETIME'),
        ('users', 'pontos_xp', 'INTEGER DEFAULT 0'),
    ]

    with db.engine.connect() as conn:
        for table, column, col_type in migrations:
            try:
                # Verifica se a coluna existe
                result = conn.execute(text(f"PRAGMA table_info({table})"))
                columns = [row[1] for row in result]
                
                if column not in columns:
                    print(f"[MIGRATE] ➕ Adicionando coluna '{column}' na tabela '{table}'...")
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"))
                    conn.commit()
                    print(f"[MIGRATE] ✅ Coluna '{column}' adicionada.")
                else:
                    print(f"[MIGRATE] ✨ Coluna '{column}' já existe em '{table}'.")
            except Exception as e:
                print(f"[MIGRATE] ❌ Erro ao processar {table}.{column}: {e}")
                # Não interrompe para tentar as outras
    
    print("[MIGRATE] 🎉 Migração finalizada.")
