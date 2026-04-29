from datetime import datetime
from database import db
from models.base import SerialMixin

class WearableData(db.Model, SerialMixin):
    """Daily data synced from wearables/health connect."""
    __tablename__ = 'wearable_data'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    data = db.Column(db.Date, nullable=False, default=datetime.utcnow().date)
    steps = db.Column(db.Integer, default=0)
    calories = db.Column(db.Integer, default=0)
    distance = db.Column(db.Float, default=0.0)
    heart_rate = db.Column(db.Integer, default=0)
    sleep_minutes = db.Column(db.Integer, default=0)
    fitness_score = db.Column(db.Float, default=0.0)
    source = db.Column(db.String(50), default='health_connect') # health_connect, manual, apple_health
    last_sync = db.Column(db.DateTime, default=datetime.utcnow)

    # Unique constraint per user and date
    __table_args__ = (db.UniqueConstraint('user_id', 'data', name='_user_date_uc'),)

    def to_dict(self):
        d = super().to_dict()
        if d.get('data'):
            d['data'] = d['data'].isoformat()
        if d.get('last_sync'):
            d['last_sync'] = d['last_sync'].isoformat()
        return d
