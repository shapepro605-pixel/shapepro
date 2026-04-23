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

            # Add pais and moeda columns to users table
            safe_execute("ALTER TABLE users ADD COLUMN pais VARCHAR(2) DEFAULT 'BR';")
            safe_execute("ALTER TABLE users ADD COLUMN moeda VARCHAR(3) DEFAULT 'BRL';")
            
            # Adicionando orcamento_dieta e renda_mensal caso não existam (já existem no model mas vamos garantir no DB)
            safe_execute("ALTER TABLE users ADD COLUMN orcamento_dieta FLOAT DEFAULT 0;")
            safe_execute("ALTER TABLE users ADD COLUMN renda_mensal FLOAT DEFAULT 0;")
            safe_execute("ALTER TABLE users ADD COLUMN estado VARCHAR(100);")
            safe_execute("ALTER TABLE users ADD COLUMN cidade VARCHAR(100);")
            
            # Missing columns identified during debugging
            safe_execute("ALTER TABLE users ADD COLUMN telefone VARCHAR(30);")
            safe_execute("ALTER TABLE users ADD COLUMN telefone_verificado BOOLEAN DEFAULT FALSE;")
            safe_execute("ALTER TABLE users ADD COLUMN email_verificado BOOLEAN DEFAULT FALSE;")
            safe_execute("ALTER TABLE users ADD COLUMN otp_code VARCHAR(10);")
            safe_execute("ALTER TABLE users ADD COLUMN cartao_cadastrado BOOLEAN DEFAULT FALSE;")
            safe_execute("ALTER TABLE users ADD COLUMN data_vencimento DATETIME;")

            print("Global migration finished successfully.")
        except Exception as e:
            print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
