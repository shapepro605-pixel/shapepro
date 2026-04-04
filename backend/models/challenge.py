"""
ShapePro - Challenge & Achievement Models
Inspired by BetFit's challenge system.
"""

from datetime import datetime
from database import db
from models.base import SerialMixin


class Challenge(db.Model, SerialMixin):
    """Fitness challenge definition."""
    __tablename__ = 'challenges'

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text, nullable=True)
    tipo = db.Column(db.String(20), nullable=False)  # diario, semanal, mensal
    categoria = db.Column(db.String(30), nullable=False)  # treino, agua, peso, sono, passos
    icone = db.Column(db.String(10), default='🏆')
    meta_valor = db.Column(db.Float, nullable=False)  # target value
    meta_unidade = db.Column(db.String(20), default='vezes')  # vezes, ml, kg, horas, passos
    pontos_xp = db.Column(db.Integer, default=50)  # XP reward
    dificuldade = db.Column(db.String(20), default='medio')  # facil, medio, dificil
    ativo = db.Column(db.Boolean, default=True)
    data_criacao = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    participantes = db.relationship('UserChallenge', backref='challenge', lazy=True, cascade='all, delete-orphan')

    # Uses default to_dict from SerialMixin


class UserChallenge(db.Model, SerialMixin):
    """User participation in a challenge."""
    __tablename__ = 'user_challenges'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    challenge_id = db.Column(db.Integer, db.ForeignKey('challenges.id'), nullable=False)
    progresso = db.Column(db.Float, default=0)
    status = db.Column(db.String(20), default='ativo')  # ativo, concluido, falhou
    data_inicio = db.Column(db.DateTime, default=datetime.utcnow)
    data_conclusao = db.Column(db.DateTime, nullable=True)

    # Relationship to user
    user = db.relationship('User', backref=db.backref('desafios', lazy=True, cascade='all, delete-orphan'))

    def to_dict(self):
        d = super().to_dict()
        pct = 0
        if self.challenge:
            pct = min(round((self.progresso / self.challenge.meta_valor) * 100, 1), 100)
            d['challenge'] = self.challenge.to_dict()
        d['percentual'] = pct
        return d


class Achievement(db.Model, SerialMixin):
    """Achievement / Badge definition."""
    __tablename__ = 'achievements'

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text, nullable=True)
    icone = db.Column(db.String(10), default='🏅')
    categoria = db.Column(db.String(30), default='geral')  # treino, dieta, streak, desafio, corpo
    criterio_tipo = db.Column(db.String(30), nullable=False)  # treinos_concluidos, streak, desafios_concluidos, peso_perdido
    criterio_valor = db.Column(db.Float, nullable=False)  # value to reach
    pontos_xp = db.Column(db.Integer, default=100)
    raridade = db.Column(db.String(20), default='comum')  # comum, raro, epico, lendario

    # Uses default to_dict from SerialMixin


class UserAchievement(db.Model, SerialMixin):
    """Unlocked achievement for a user."""
    __tablename__ = 'user_achievements'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    achievement_id = db.Column(db.Integer, db.ForeignKey('achievements.id'), nullable=False)
    data_desbloqueio = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship('User', backref=db.backref('conquistas', lazy=True, cascade='all, delete-orphan'))
    achievement = db.relationship('Achievement', backref='usuarios')

    def to_dict(self):
        d = super().to_dict()
        if self.achievement:
            d['achievement'] = self.achievement.to_dict()
        return d


class SleepLog(db.Model, SerialMixin):
    """Sleep tracking log."""
    __tablename__ = 'sleep_logs'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    hora_dormir = db.Column(db.String(5), nullable=False)   # HH:MM format
    hora_acordar = db.Column(db.String(5), nullable=False)  # HH:MM format
    duracao_horas = db.Column(db.Float, nullable=False)      # calculated hours
    qualidade = db.Column(db.Integer, default=3)             # 1-5 stars
    notas = db.Column(db.Text, nullable=True)
    data = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship to user
    user = db.relationship('User', backref=db.backref('registros_sono', lazy=True, cascade='all, delete-orphan'))

    # Uses default to_dict from SerialMixin


class JournalEntry(db.Model, SerialMixin):
    """Wellness journal entry."""
    __tablename__ = 'journal_entries'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    humor = db.Column(db.Integer, default=3)       # 1-5
    energia = db.Column(db.Integer, default=3)      # 1-5
    estresse = db.Column(db.Integer, default=3)     # 1-5
    notas = db.Column(db.Text, nullable=True)
    tags = db.Column(db.String(200), nullable=True)  # comma-separated tags
    data = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship to user
    user = db.relationship('User', backref=db.backref('diario', lazy=True, cascade='all, delete-orphan'))

    def to_dict(self):
        d = super().to_dict()
        if self.tags:
            d['tags'] = self.tags.split(',')
        else:
            d['tags'] = []
        return d
