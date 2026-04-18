from database import db
from app import create_app
from sqlalchemy import text

def migrate():
    app = create_app()
    with app.app_context():
        try:
            # Safely execute migrations
            def safe_execute(sql):
                try:
                    db.session.execute(text(sql))
                    db.session.commit()
                    print(f"Executed: {sql}")
                except Exception as e:
                    db.session.rollback()
                    print(f"Skipping: {e}")

            # Create food_prices table
            # Since we are using SQLAlchemy, we could use db.create_all(), 
            # but let's do it via raw SQL to be consistent with existing migration style.
            sql = """
            CREATE TABLE IF NOT EXISTS food_prices (
                id SERIAL PRIMARY KEY,
                alimento VARCHAR(100) NOT NULL,
                preco FLOAT NOT NULL,
                moeda VARCHAR(3) DEFAULT 'BRL',
                cidade VARCHAR(100),
                pais VARCHAR(2) DEFAULT 'BR',
                origem VARCHAR(20) DEFAULT 'user',
                data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
            # If not postgres, use slightly different syntax for SERIAL/AUTOINCREMENT
            engine = db.engine
            if engine.name != 'postgresql':
                sql = sql.replace('SERIAL PRIMARY KEY', 'INTEGER PRIMARY KEY AUTOINCREMENT')
            
            safe_execute(sql)
            safe_execute("CREATE INDEX IF NOT EXISTS idx_food_alimento ON food_prices(alimento);")
            safe_execute("CREATE INDEX IF NOT EXISTS idx_food_cidade ON food_prices(cidade);")
            safe_execute("CREATE INDEX IF NOT EXISTS idx_food_pais ON food_prices(pais);")

            print("FoodPrice migration finished successfully.")
        except Exception as e:
            print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
