from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def init_db(app):
    """Initialize the database with the Flask app."""
    db.init_app(app)
    with app.app_context():
        # Import models so they are registered with SQLAlchemy
        from models.user import User, DietPlan, TrainingPlan, WeightLog, BodyMetric, WaterLog  # noqa: F401
        db.create_all()
        print("[ShapePro] ✅ Database initialized successfully.")
