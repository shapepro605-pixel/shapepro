import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration."""
    SECRET_KEY = os.getenv('SECRET_KEY', 'shapepro-default-secret')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'shapepro-jwt-default')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
    
    # ── Firebase Configuration ────────────────────────────────────────
    FIREBASE_CREDENTIALS_JSON = os.getenv('FIREBASE_CREDENTIALS_JSON', '')
    
    # ── Email (Flask-Mail) Configuration ──────────────────────────────
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 465))
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS', 'False').lower() == 'true'
    MAIL_USE_SSL = os.getenv('MAIL_USE_SSL', 'True').lower() == 'true'
    MAIL_USERNAME = os.getenv('MAIL_USERNAME')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD')
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', MAIL_USERNAME)

    
    # ── App Management ────────────────────────────────────────────────
    APP_NAME = "ShapePro"
    APP_VERSION = "1.0.1"
    APP_MIN_VERSION = "1.0.1" # Force update if lower
    APP_UPDATE_URL = "https://shapepro-production.up.railway.app"


class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///shapepro.db')


class ProductionConfig(Config):
    """Production configuration."""
    _db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'shapepro.db'))
    db_url = os.getenv('DATABASE_URL')
    if db_url and db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_DATABASE_URI = db_url or f'sqlite:///{_db_path}'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)


config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
}
