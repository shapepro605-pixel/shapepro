"""
ShapePro - Streak & Achievement Service
Manages workout streaks and unlocks achievements automatically.
"""

from datetime import datetime, timedelta
from database import db


class StreakService:
    """Manage user streaks and achievements."""

    @staticmethod
    def atualizar_streak(user):
        """
        Update user streak after completing a workout.
        Call this from the concluir_treino endpoint.
        """
        hoje = datetime.utcnow().date()
        ultimo = None
        if user.ultimo_treino_data:
            ultimo = user.ultimo_treino_data.date() if isinstance(user.ultimo_treino_data, datetime) else user.ultimo_treino_data

        if ultimo == hoje:
            # Already trained today, no streak change
            return user.streak_atual or 0

        if ultimo == hoje - timedelta(days=1):
            # Consecutive day — increment streak
            user.streak_atual = (user.streak_atual or 0) + 1
        else:
            # Streak broken — restart at 1
            user.streak_atual = 1

        # Update best streak
        if (user.streak_atual or 0) > (user.melhor_streak or 0):
            user.melhor_streak = user.streak_atual

        user.ultimo_treino_data = datetime.utcnow()
        return user.streak_atual

    @staticmethod
    def verificar_conquistas(user):
        """
        Check and unlock new achievements for the user.
        Returns list of newly unlocked achievements.
        """
        from models.challenge import Achievement, UserAchievement

        # Get already unlocked achievement IDs
        unlocked_ids = {
            ua.achievement_id for ua in
            UserAchievement.query.filter_by(user_id=user.id).all()
        }

        # Get all achievements
        all_achievements = Achievement.query.all()
        novas = []

        for ach in all_achievements:
            if ach.id in unlocked_ids:
                continue

            desbloqueou = False
            criterio = ach.criterio_tipo
            valor = ach.criterio_valor

            if criterio == 'treinos_concluidos':
                desbloqueou = (user.treinos_concluidos or 0) >= valor
            elif criterio == 'streak':
                desbloqueou = (user.streak_atual or 0) >= valor
            elif criterio == 'melhor_streak':
                desbloqueou = (user.melhor_streak or 0) >= valor
            elif criterio == 'desafios_concluidos':
                from models.challenge import UserChallenge
                count = UserChallenge.query.filter_by(
                    user_id=user.id, status='concluido'
                ).count()
                desbloqueou = count >= valor
            elif criterio == 'pontos_xp':
                desbloqueou = (user.pontos_xp or 0) >= valor

            if desbloqueou:
                ua = UserAchievement(
                    user_id=user.id,
                    achievement_id=ach.id
                )
                db.session.add(ua)
                user.pontos_xp = (user.pontos_xp or 0) + ach.pontos_xp
                novas.append(ach)

        if novas:
            db.session.commit()

        return novas

    @staticmethod
    def seed_achievements():
        """Seed default achievements into the database."""
        from models.challenge import Achievement

        defaults = [
            # Treino achievements
            {'nome': 'Primeiro Treino', 'descricao': 'Complete seu primeiro treino', 'icone': '💪',
             'categoria': 'treino', 'criterio_tipo': 'treinos_concluidos', 'criterio_valor': 1,
             'pontos_xp': 50, 'raridade': 'comum'},
            {'nome': 'Dedicado', 'descricao': 'Complete 10 treinos', 'icone': '🔥',
             'categoria': 'treino', 'criterio_tipo': 'treinos_concluidos', 'criterio_valor': 10,
             'pontos_xp': 100, 'raridade': 'comum'},
            {'nome': 'Guerreiro', 'descricao': 'Complete 50 treinos', 'icone': '⚔️',
             'categoria': 'treino', 'criterio_tipo': 'treinos_concluidos', 'criterio_valor': 50,
             'pontos_xp': 300, 'raridade': 'raro'},
            {'nome': 'Lenda', 'descricao': 'Complete 100 treinos', 'icone': '👑',
             'categoria': 'treino', 'criterio_tipo': 'treinos_concluidos', 'criterio_valor': 100,
             'pontos_xp': 500, 'raridade': 'lendario'},
            # Streak achievements
            {'nome': 'Consistente', 'descricao': 'Mantenha um streak de 3 dias', 'icone': '🔥',
             'categoria': 'streak', 'criterio_tipo': 'streak', 'criterio_valor': 3,
             'pontos_xp': 75, 'raridade': 'comum'},
            {'nome': 'Imparável', 'descricao': 'Mantenha um streak de 7 dias', 'icone': '🚀',
             'categoria': 'streak', 'criterio_tipo': 'streak', 'criterio_valor': 7,
             'pontos_xp': 150, 'raridade': 'raro'},
            {'nome': 'Máquina', 'descricao': 'Mantenha um streak de 30 dias', 'icone': '🤖',
             'categoria': 'streak', 'criterio_tipo': 'streak', 'criterio_valor': 30,
             'pontos_xp': 500, 'raridade': 'epico'},
            {'nome': 'Imortal', 'descricao': 'Mantenha um streak de 100 dias', 'icone': '⭐',
             'categoria': 'streak', 'criterio_tipo': 'melhor_streak', 'criterio_valor': 100,
             'pontos_xp': 1000, 'raridade': 'lendario'},
            # Challenge achievements
            {'nome': 'Desafiante', 'descricao': 'Complete 1 desafio', 'icone': '🏆',
             'categoria': 'desafio', 'criterio_tipo': 'desafios_concluidos', 'criterio_valor': 1,
             'pontos_xp': 100, 'raridade': 'comum'},
            {'nome': 'Campeão', 'descricao': 'Complete 5 desafios', 'icone': '🏅',
             'categoria': 'desafio', 'criterio_tipo': 'desafios_concluidos', 'criterio_valor': 5,
             'pontos_xp': 300, 'raridade': 'raro'},
            # XP achievements
            {'nome': 'Ascensão', 'descricao': 'Alcance 500 pontos XP', 'icone': '📈',
             'categoria': 'geral', 'criterio_tipo': 'pontos_xp', 'criterio_valor': 500,
             'pontos_xp': 100, 'raridade': 'comum'},
            {'nome': 'Elite', 'descricao': 'Alcance 2000 pontos XP', 'icone': '💎',
             'categoria': 'geral', 'criterio_tipo': 'pontos_xp', 'criterio_valor': 2000,
             'pontos_xp': 300, 'raridade': 'epico'},
        ]

        for d in defaults:
            exists = Achievement.query.filter_by(nome=d['nome']).first()
            if not exists:
                db.session.add(Achievement(**d))

        db.session.commit()

    @staticmethod
    def seed_challenges():
        """Seed default challenges into the database."""
        from models.challenge import Challenge

        defaults = [
            # Daily
            {'nome': 'Treino do Dia', 'descricao': 'Complete 1 treino hoje',
             'tipo': 'diario', 'categoria': 'treino', 'icone': '💪',
             'meta_valor': 1, 'meta_unidade': 'treinos', 'pontos_xp': 25, 'dificuldade': 'facil'},
            {'nome': 'Hidratação Total', 'descricao': 'Beba 2 litros de água hoje',
             'tipo': 'diario', 'categoria': 'agua', 'icone': '💧',
             'meta_valor': 2000, 'meta_unidade': 'ml', 'pontos_xp': 20, 'dificuldade': 'facil'},
            {'nome': 'Sono Reparador', 'descricao': 'Durma pelo menos 7 horas',
             'tipo': 'diario', 'categoria': 'sono', 'icone': '😴',
             'meta_valor': 7, 'meta_unidade': 'horas', 'pontos_xp': 20, 'dificuldade': 'facil'},
            # Weekly
            {'nome': 'Semana de Ferro', 'descricao': 'Complete 5 treinos nesta semana',
             'tipo': 'semanal', 'categoria': 'treino', 'icone': '🔥',
             'meta_valor': 5, 'meta_unidade': 'treinos', 'pontos_xp': 100, 'dificuldade': 'medio'},
            {'nome': 'Rios de Água', 'descricao': 'Beba 14L de água na semana',
             'tipo': 'semanal', 'categoria': 'agua', 'icone': '🌊',
             'meta_valor': 14000, 'meta_unidade': 'ml', 'pontos_xp': 75, 'dificuldade': 'medio'},
            {'nome': 'Semana Zen', 'descricao': 'Registre sono 7 dias seguidos',
             'tipo': 'semanal', 'categoria': 'sono', 'icone': '🧘',
             'meta_valor': 7, 'meta_unidade': 'registros', 'pontos_xp': 75, 'dificuldade': 'medio'},
            # Monthly
            {'nome': 'Transformação', 'descricao': 'Complete 20 treinos no mês',
             'tipo': 'mensal', 'categoria': 'treino', 'icone': '🏆',
             'meta_valor': 20, 'meta_unidade': 'treinos', 'pontos_xp': 300, 'dificuldade': 'dificil'},
            {'nome': 'Diário Completo', 'descricao': 'Escreva 30 entradas no diário',
             'tipo': 'mensal', 'categoria': 'diario', 'icone': '📓',
             'meta_valor': 30, 'meta_unidade': 'entradas', 'pontos_xp': 200, 'dificuldade': 'dificil'},
        ]

        for d in defaults:
            exists = Challenge.query.filter_by(nome=d['nome']).first()
            if not exists:
                db.session.add(Challenge(**d))

        db.session.commit()
