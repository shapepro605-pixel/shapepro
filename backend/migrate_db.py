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
            
            # Executa o ALTER TABLE de acordo com o banco
            if engine.name == 'postgresql':
                db.session.execute(text("ALTER TABLE users ADD COLUMN foto_perfil VARCHAR(500);"))
            else:
                db.session.execute(text("ALTER TABLE users ADD COLUMN foto_perfil TEXT;"))
                
            db.session.commit()
            return {"success": True, "message": "Migração incluída com sucesso."}
        except Exception as e:
            db.session.rollback()
            return {"success": False, "error": str(e)}

if __name__ == "__main__":
    migrate()
