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
    
    # ── Twilio Configuration ──────────────────────────────────────────
    TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID', '')
    TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN', '')
    TWILIO_VERIFY_SERVICE_SID = os.getenv('TWILIO_VERIFY_SERVICE_SID', '')
    
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
    DEBUG = False
    # Move database to the root for maximum reliability on Railway
    _base_dir = os.path.abspath(os.path.dirname(__file__))
    _db_path = os.path.join(_base_dir, 'shapepro.db')
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', f'sqlite:///{_db_path}')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)


config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
}
