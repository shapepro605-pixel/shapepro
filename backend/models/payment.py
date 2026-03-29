from database import db
from models.base import SerialMixin
from datetime import datetime

class SubscriptionPlan(db.Model, SerialMixin):
    __tablename__ = 'subscription_plans'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False) # e.g. "Plano Mensal"
    code = db.Column(db.String(50), unique=True, nullable=False) # e.g. "mensal"
    duration_months = db.Column(db.Integer, nullable=False) # 1, 3, 12
    price = db.Column(db.Float, nullable=False) # e.g. 29.90
    is_active = db.Column(db.Boolean, default=True)

    # Uses default to_dict from SerialMixin

class PromoCode(db.Model, SerialMixin):
    __tablename__ = 'promo_codes'

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False) # e.g. "MUITO_VIP"
    discount_percent = db.Column(db.Float, default=0.0) # 0 to 100
    is_free = db.Column(db.Boolean, default=False) # If true, 100% off
    max_uses = db.Column(db.Integer, default=1)
    current_uses = db.Column(db.Integer, default=0)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def is_valid(self):
        return self.is_active and self.current_uses < self.max_uses

    # Uses default to_dict from SerialMixin
