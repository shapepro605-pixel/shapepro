"""
ShapePro - Backend API Server
Professional fitness & diet application
"""

import os
import sys

from flask import Flask, jsonify, render_template
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from config import config_by_name
from database import db, init_db


def create_app(config_name=None):
    """Application factory."""
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')

    app = Flask(__name__)
    app.config.from_object(config_by_name[config_name])

    # ── Initialize extensions ─────────────────────────────────────────
    from flask_mail import Mail
    app.mail = Mail(app)
    
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    JWTManager(app)
    Bcrypt(app)

    # ── Initialize Limiter (Security / Anti-Scraping) ────────────────
    limiter = Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
        storage_uri="memory://",
    )
    app.limiter = limiter # Store for blueprint access

    # ── Initialize database ───────────────────────────────────────────
    init_db(app)

    # ── Initialize Firebase Admin SDK ─────────────────────────────────
    from firebase_init import init_firebase
    init_firebase()

    # ── Register blueprints ───────────────────────────────────────────
    from routes.auth import auth_bp
    from routes.plan import plan_bp
    from routes.admin import admin_bp
    from routes.payment import payment_bp
    from routes.tracking import tracking_bp
    from routes.challenge import challenge_bp
    from routes.journal import journal_bp
    from routes.body_scan import body_scan_bp
    from routes.food_prices import food_prices_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(plan_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(payment_bp)
    app.register_blueprint(tracking_bp)
    app.register_blueprint(challenge_bp)
    app.register_blueprint(journal_bp)
    app.register_blueprint(body_scan_bp)
    app.register_blueprint(food_prices_bp)

    # ── Import new models so tables are created ───────────────────────
    with app.app_context():
        from models.user import (
            User, BodyScan
        )
        from models.challenge import (
            Challenge, UserChallenge, Achievement,
            UserAchievement, SleepLog, JournalEntry
        )
        db.create_all()

        # Seed default challenges and achievements
        from services.streak_service import StreakService
        StreakService.seed_achievements()
        StreakService.seed_challenges()

    # ── Error handlers ────────────────────────────────────────────────
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({'error': 'Requisição inválida', 'details': str(error)}), 400

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Recurso não encontrado'}), 404

    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Erro interno do servidor'}), 500

    # ── Admin Migration ───────────────────────────────────────────────
    @app.route('/api/admin/migrate', methods=['GET'])
    def run_migration():
        """Route to manually trigger DB migration in prod."""
        from migrate_db import migrate
        try:
            res = migrate()
            return jsonify(res), 200
        except Exception as e:
            return jsonify({'success': False, 'error': str(e)}), 500

    # ── App Configuration ─────────────────────────────────────────────
    @app.route('/api/app/config', methods=['GET'])
    def app_config():
        """Returns the current app configuration and version info."""
        return jsonify({
            'app_name': app.config.get('APP_NAME'),
            'version': app.config.get('APP_VERSION'),
            'min_version': app.config.get('APP_MIN_VERSION'),
            'update_url': app.config.get('APP_UPDATE_URL'),
            'status': 'active'
        }), 200

    # ── Health check ──────────────────────────────────────────────────
    @app.route('/health', methods=['GET'])
    def health_check():
        """Railway health check endpoint."""
        return jsonify({'status': 'healthy', 'version': app.config.get('APP_VERSION')}), 200

    # ── Web Frontend ──────────────────────────────────────────────────
    @app.route('/api/debug-routes', methods=['GET'])
    def list_routes_json():
        """Returns all registered routes for debugging purposes."""
        routes = []
        for rule in app.url_map.iter_rules():
            routes.append({
                'endpoint': rule.endpoint,
                'path': str(rule.rule),
                'methods': list(rule.methods)
            })
        return jsonify({'routes': routes}), 200

    @app.route('/', methods=['GET'])
    def index():
        return render_template('index.html')

    print("""
    ==========================================
              [ShapePro API v1.0]          
         Dieta & Treino Personalizado      
    ==========================================
    """)

    return app


# Module-level app instance for gunicorn (Railway production)
app = create_app()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
