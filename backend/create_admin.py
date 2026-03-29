import os
import sys

# Add backend to path
sys.path.append(os.getcwd())

from app import create_app
from database import db
from models.user import User
from flask_bcrypt import Bcrypt

app = create_app()
bcrypt = Bcrypt(app)

def create_admin():
    email = "admin@shapepro.com"
    password = "admin123"
    nome = "Administrador Master"
    
    with app.app_context():
        user = User.query.filter_by(email=email).first()
        password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        
        if user:
            print(f"Updating existing Admin {email}...")
            user.is_admin = True
            user.password_hash = password_hash
            db.session.commit()
            print(f"✅ Admin updated: {email} / {password}")
            return
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
        print(f"✅ Admin created: {email} / {password}")

if __name__ == "__main__":
    create_admin()
