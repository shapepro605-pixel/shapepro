import sqlite3
import os

def migrate():
    db_path = os.path.join(os.path.dirname(__file__), 'shapepro.db')
    instance_path = os.path.join(os.path.dirname(__file__), 'instance', 'shapepro.db')
    
    if os.path.exists(instance_path):
        db_path = instance_path
    
    if not os.path.exists(db_path):
        print(f"Banco de dados não encontrado em: {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Verifica se a coluna já existe
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'foto_perfil' not in columns:
            print("Adicionando coluna 'foto_perfil' à tabela 'users'...")
            cursor.execute("ALTER TABLE users ADD COLUMN foto_perfil TEXT")
            conn.commit()
            print("Migração concluída com sucesso!")
        else:
            print("A coluna 'foto_perfil' já existe.")
            
    except Exception as e:
        print(f"Erro durante a migração: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
