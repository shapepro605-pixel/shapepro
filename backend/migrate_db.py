import os
from database import db
from app import create_app
from sqlalchemy import text

def migrate():
    app = create_app()
    with app.app_context():
        try:
            engine = db.engine
            print(f"Rodando migração no banco: {engine.name}")
            
            # Function to safely execute migrations
            def safe_execute(sql):
                try:
                    db.session.execute(text(sql))
                    db.session.commit()
                except Exception as e:
                    db.session.rollback()
                    print(f"Skipping (already exists or error): {e}")

            # Executa o ALTER TABLE de acordo com o banco
            if engine.name == 'postgresql':
                safe_execute("ALTER TABLE users ADD COLUMN foto_perfil VARCHAR(500);")
                safe_execute("ALTER TABLE body_scans ADD COLUMN metrics JSON;")
            else:
                safe_execute("ALTER TABLE users ADD COLUMN foto_perfil TEXT;")
                safe_execute("ALTER TABLE body_scans ADD COLUMN metrics JSON;")
                
            return {"success": True, "message": "Migração incluída com sucesso."}
        except Exception as e:
            return {"success": False, "error": str(e)}

if __name__ == "__main__":
    migrate()
