import os
import sys

# Adiciona o diretório atual do script (backend) ao path de forma correta
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

try:
    from app import create_app
    from database import db
    from models.user import User
    from flask_bcrypt import Bcrypt
except ImportError as e:
    print(f"Erro ao importar módulos do backend: {e}")
    sys.exit(1)

def cadastrar_admin():
    email = "macssuelusa@gmail.com"
    password = "708090ma"
    nome = "Macssuel Admin"
    
    app = create_app()
    bcrypt = Bcrypt(app)
    
    with app.app_context():
        # Busca o usuário
        user = User.query.filter_by(email=email).first()
        password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        
        if user:
            print(f"Promovendo usuário {email} a Administrador...")
            user.is_admin = True
            user.password_hash = password_hash
            db.session.commit()
            print(f"✅ Usuário {email} agora é ADMINISTRADOR!")
        else:
            print(f"Criando novo Administrador: {email}...")
            new_admin = User(
                email=email,
                password_hash=password_hash,
                nome=nome,
                is_admin=True,
                plano_assinatura='anual',
                assinatura_ativa=True
            )
            db.session.add(new_admin)
            db.session.commit()
            print(f"✅ NOVO ADMINISTRADOR criado com sucesso!")

if __name__ == "__main__":
    cadastrar_admin()
