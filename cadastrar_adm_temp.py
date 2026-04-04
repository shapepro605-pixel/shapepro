import os
import sys

# Adiciona o backend ao path para carregar os modelos
sys.path.append(os.getcwd())

from backend.app import create_app
from backend.database import db
from backend.models.user import User
from flask_bcrypt import Bcrypt

def cadastrar_adm():
    email = "macssuelusa@gmail.com"
    password = "708090ma"
    nome = "Macssuel Admin"
    
    app = create_app()
    bcrypt = Bcrypt(app)
    
    with app.app_context():
        user = User.query.filter_by(email=email).first()
        password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        
        if user:
            print(f"Atualizando usuário existente para ADMIN: {email}")
            user.is_admin = True
            user.password_hash = password_hash
            db.session.commit()
            print(f"✅ Usuário atualizado com sucesso!")
        else:
            print(f"Criando NOVO ADMIN: {email}")
            new_admin = User(
                email=email,
                password_hash=password_hash,
                nome=nome,
                telefone="+5511999999999", # Placeholder obrigatório
                is_admin=True,
                plano_assinatura='anual',
                assinatura_ativa=True
            )
            db.session.add(new_admin)
            db.session.commit()
            print(f"✅ Usuário criado com sucesso!")

if __name__ == "__main__":
    cadastrar_adm()
