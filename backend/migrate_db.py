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
                
                # Novas colunas da refatoração nutricional
                safe_execute("ALTER TABLE diet_plans ADD COLUMN peso_inicial FLOAT;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN perda_estimada_kg FLOAT;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN fibra_total_g FLOAT;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN agua_recomendada_ml INTEGER;")
            else:
                safe_execute("ALTER TABLE users ADD COLUMN foto_perfil TEXT;")
                safe_execute("ALTER TABLE body_scans ADD COLUMN metrics JSON;")
                
                # Novas colunas da refatoração nutricional (SQLite)
                safe_execute("ALTER TABLE diet_plans ADD COLUMN peso_inicial REAL;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN perda_estimada_kg REAL;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN fibra_total_g REAL;")
                safe_execute("ALTER TABLE diet_plans ADD COLUMN agua_recomendada_ml INTEGER;")
                
            # Run the other migrations securely
            from migrate_global import migrate as migrate_global
            migrate_global()

            from migrate_food_prices import migrate as migrate_food_prices
            migrate_food_prices()
                
            return {"success": True, "message": "Migração incluída com sucesso."}
        except Exception as e:
            return {"success": False, "error": str(e)}

if __name__ == "__main__":
    migrate()
