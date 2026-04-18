from database import db
from datetime import datetime
from models.base import SerialMixin

class FoodPrice(db.Model, SerialMixin):
    """Stores food prices reported by users or estimated by IA per city/country."""
    __tablename__ = 'food_prices'

    id = db.Column(db.Integer, primary_key=True)
    alimento = db.Column(db.String(100), nullable=False, index=True)
    preco = db.Column(db.Float, nullable=False)
    moeda = db.Column(db.String(3), default='BRL')
    cidade = db.Column(db.String(100), nullable=True, index=True)
    pais = db.Column(db.String(2), default='BR', index=True)
    origem = db.Column(db.String(20), default='user') # 'user' or 'ia_estimate'
    data_atualizacao = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'alimento': self.alimento,
            'preco': self.preco,
            'moeda': self.moeda,
            'cidade': self.cidade,
            'pais': self.pais,
            'origem': self.origem,
            'data_atualizacao': self.data_atualizacao.isoformat()
        }
