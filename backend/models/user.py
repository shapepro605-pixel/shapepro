from datetime import datetime
from database import db
from models.base import SerialMixin


class User(db.Model, SerialMixin):
    """User account model."""
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    telefone = db.Column(db.String(30), nullable=True, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    nome = db.Column(db.String(100), nullable=False)
    idade = db.Column(db.Integer, nullable=True)
    altura = db.Column(db.Float, nullable=True)  # em cm
    peso = db.Column(db.Float, nullable=True)     # em kg
    sexo = db.Column(db.String(1), nullable=True)  # M ou F
    objetivo = db.Column(db.String(50), nullable=True)  # perder_peso, manter, ganhar_massa
    nivel_atividade = db.Column(db.String(50), nullable=True)  # sedentario, leve, moderado, intenso, muito_intenso
    ritmo_meta = db.Column(db.String(50), default='padrao')  # leve, padrao, agressivo
    treinos_concluidos = db.Column(db.Integer, default=0)
    plano_assinatura = db.Column(db.String(20), default='free')  # free, mensal, anual
    assinatura_ativa = db.Column(db.Boolean, default=False)
    data_criacao = db.Column(db.DateTime, default=datetime.utcnow)
    is_admin = db.Column(db.Boolean, default=False)
    telefone_verificado = db.Column(db.Boolean, default=False)
    otp_code = db.Column(db.String(10), nullable=True)
    # Subscription & Trial Logic
    cartao_cadastrado = db.Column(db.Boolean, default=False)
    data_vencimento = db.Column(db.DateTime, nullable=True) # Used for paid plans or advanced trial
    
    # Streak & Gamification fields
    streak_atual = db.Column(db.Integer, default=0)
    melhor_streak = db.Column(db.Integer, default=0)
    ultimo_treino_data = db.Column(db.DateTime, nullable=True)
    pontos_xp = db.Column(db.Integer, default=0)
    is_active = db.Column(db.Boolean, default=True)
    data_atualizacao = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    dietas = db.relationship('DietPlan', backref='user', lazy=True, cascade='all, delete-orphan')
    treinos = db.relationship('TrainingPlan', backref='user', lazy=True, cascade='all, delete-orphan')
    registros_peso = db.relationship('WeightLog', backref='user', lazy=True, cascade='all, delete-orphan')
    metricas_corpo = db.relationship('BodyMetric', backref='user', lazy=True, cascade='all, delete-orphan')
    registros_agua = db.relationship('WaterLog', backref='user', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        d = super().to_dict()
        d['imc'] = self.calcular_imc()
        # Ensure some defaults for frontend
        d['streak_atual'] = self.streak_atual or 0
        d['melhor_streak'] = self.melhor_streak or 0
        d['pontos_xp'] = self.pontos_xp or 0
        d['cartao_cadastrado'] = self.cartao_cadastrado or False
        d['is_trial'] = self.is_in_trial()
        d['telefone_verificado'] = self.telefone_verificado or False
        return d

    def is_in_trial(self):
        """Check if user is currently in their 2 or 3 day trial period."""
        if self.assinatura_ativa and self.plano_assinatura != 'free':
            return False
            
        from datetime import datetime
        trial_days = 2
        days_active = (datetime.utcnow() - self.data_criacao).days
        return days_active < trial_days

    def calcular_imc(self):
        """Calculate BMI (IMC)."""
        if self.altura and self.peso and self.altura > 0:
            altura_m = self.altura / 100
            return round(self.peso / (altura_m ** 2), 1)
        return None

    def classificar_imc(self):
        """Classify BMI category."""
        from services.i18n import t
        imc = self.calcular_imc()
        if imc is None:
            return None
        if imc < 18.5:
            return t('bmi_underweight')
        elif imc < 25:
            return t('bmi_normal')
        elif imc < 30:
            return t('bmi_overweight')
        elif imc < 35:
            return t('bmi_obesity_1')
        elif imc < 40:
            return t('bmi_obesity_2')
        else:
            return t('bmi_obesity_3')


class DietPlan(db.Model, SerialMixin):
    """Diet plan model."""
    __tablename__ = 'diet_plans'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    calorias_totais = db.Column(db.Float, nullable=False)
    proteinas_g = db.Column(db.Float, nullable=False)
    carboidratos_g = db.Column(db.Float, nullable=False)
    gorduras_g = db.Column(db.Float, nullable=False)
    refeicoes = db.Column(db.Text, nullable=False)  # JSON string
    objetivo = db.Column(db.String(50), nullable=True)
    duracao = db.Column(db.Integer, default=1)  # Duration in days
    ativa = db.Column(db.Boolean, default=True)
    data_criacao = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        import json
        d = super().to_dict()
        if self.refeicoes:
            try:
                d['refeicoes'] = json.loads(self.refeicoes)
            except:
                d['refeicoes'] = []
        return d


class TrainingPlan(db.Model, SerialMixin):
    """Training plan model."""
    __tablename__ = 'training_plans'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    nome = db.Column(db.String(100), nullable=False)
    tipo_treino = db.Column(db.String(50), nullable=False)  # A, B, C, D, E
    grupo_muscular = db.Column(db.String(50), nullable=False)
    exercicios = db.Column(db.Text, nullable=False)  # JSON string
    nivel = db.Column(db.String(20), default='intermediario')
    ativo = db.Column(db.Boolean, default=True)
    data_criacao = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        import json
        d = super().to_dict()
        if self.exercicios:
            try:
                d['exercicios'] = json.loads(self.exercicios)
            except:
                d['exercicios'] = []
        return d


class WeightLog(db.Model, SerialMixin):
    """Weight tracking log."""
    __tablename__ = 'weight_logs'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    peso = db.Column(db.Float, nullable=False)
    data = db.Column(db.DateTime, default=datetime.utcnow)

    # Uses default to_dict from SerialMixin


class BodyMetric(db.Model, SerialMixin):
    """Detailed body measurements tracking."""
    __tablename__ = 'body_metrics'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    cintura = db.Column(db.Float, nullable=True)  # cm
    peito = db.Column(db.Float, nullable=True)    # cm
    braco_esq = db.Column(db.Float, nullable=True) # cm
    braco_dir = db.Column(db.Float, nullable=True) # cm
    coxa_esq = db.Column(db.Float, nullable=True)  # cm
    coxa_dir = db.Column(db.Float, nullable=True)  # cm
    percentual_gordura = db.Column(db.Float, nullable=True)
    data = db.Column(db.DateTime, default=datetime.utcnow)

    # Uses default to_dict from SerialMixin


class WaterLog(db.Model, SerialMixin):
    """Daily hydration tracking."""
    __tablename__ = 'water_logs'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    quantidade_ml = db.Column(db.Integer, nullable=False)
    data = db.Column(db.DateTime, default=datetime.utcnow)

    # Uses default to_dict from SerialMixin
