import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app import create_app
from database import db

# Force creation of all tables defined in models
app = create_app()
with app.app_context():
    from models.user import BodyScan
    db.create_all()
    print("Database tables synchronized successfully.")
