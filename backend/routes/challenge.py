"""
ShapePro - Challenge Routes
Endpoints for fitness challenges inspired by BetFit.
"""

from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import db
from models.user import User
from models.challenge import Challenge, UserChallenge

challenge_bp = Blueprint('challenge', __name__, url_prefix='/api/challenges')


@challenge_bp.route('', methods=['GET'])
@jwt_required()
def list_challenges():
    """List all available active challenges."""
    tipo = request.args.get('tipo')  # diario, semanal, mensal
    query = Challenge.query.filter_by(ativo=True)
    if tipo:
        query = query.filter_by(tipo=tipo)
    challenges = query.order_by(Challenge.dificuldade).all()
    return jsonify({'challenges': [c.to_dict() for c in challenges]}), 200


@challenge_bp.route('/join/<int:challenge_id>', methods=['POST'])
@jwt_required()
def join_challenge(challenge_id):
    """Join a challenge."""
    user_id = int(get_jwt_identity())

    challenge = Challenge.query.get(challenge_id)
    if not challenge or not challenge.ativo:
        return jsonify({'error': 'Desafio não encontrado ou inativo'}), 404

    # Check subscription for championships
    user = User.query.get(user_id)
    if not user or user.plano_assinatura == 'free':
        return jsonify({
            'error': 'Assinatura necessária para participar de campeonatos. Escolha um plano Premium!'
        }), 403

    # Check if already participating
    existing = UserChallenge.query.filter_by(
        user_id=user_id,
        challenge_id=challenge_id,
        status='ativo'
    ).first()
    if existing:
        return jsonify({'error': 'Você já está participando deste desafio'}), 409

    uc = UserChallenge(
        user_id=user_id,
        challenge_id=challenge_id,
        progresso=0,
        status='ativo'
    )
    db.session.add(uc)
    db.session.commit()

    return jsonify({
        'message': f'Você entrou no desafio: {challenge.nome}!',
        'desafio': uc.to_dict()
    }), 201


@challenge_bp.route('/active', methods=['GET'])
@jwt_required()
def active_challenges():
    """Get user's active challenges."""
    user_id = int(get_jwt_identity())
    active = UserChallenge.query.filter_by(
        user_id=user_id, status='ativo'
    ).all()
    return jsonify({'challenges': [uc.to_dict() for uc in active]}), 200


@challenge_bp.route('/progress', methods=['POST'])
@jwt_required()
def update_progress():
    """
    Update progress on a specific user challenge.
    Body: { "user_challenge_id": int, "valor": float }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or 'user_challenge_id' not in data or 'valor' not in data:
        return jsonify({'error': 'user_challenge_id e valor são obrigatórios'}), 400

    uc = UserChallenge.query.get(data['user_challenge_id'])
    if not uc or uc.user_id != user_id:
        return jsonify({'error': 'Desafio não encontrado'}), 404

    if uc.status != 'ativo':
        return jsonify({'error': 'Desafio já finalizado'}), 400

    uc.progresso = (uc.progresso or 0) + data['valor']

    # Check if challenge is complete
    if uc.progresso >= uc.challenge.meta_valor:
        uc.status = 'concluido'
        uc.data_conclusao = datetime.utcnow()

        # Award XP
        user = User.query.get(user_id)
        if user:
            user.pontos_xp = (user.pontos_xp or 0) + uc.challenge.pontos_xp
            # Check for new achievements
            from services.streak_service import StreakService
            StreakService.verificar_conquistas(user)

    db.session.commit()

    return jsonify({
        'message': 'Progresso atualizado!',
        'desafio': uc.to_dict()
    }), 200


@challenge_bp.route('/history', methods=['GET'])
@jwt_required()
def challenge_history():
    """Get user's challenge history."""
    user_id = int(get_jwt_identity())
    history = UserChallenge.query.filter_by(
        user_id=user_id
    ).order_by(UserChallenge.data_inicio.desc()).limit(20).all()
    return jsonify({'history': [uc.to_dict() for uc in history]}), 200


@challenge_bp.route('/stats', methods=['GET'])
@jwt_required()
def challenge_stats():
    """Get challenge statistics for the user."""
    user_id = int(get_jwt_identity())

    total = UserChallenge.query.filter_by(user_id=user_id).count()
    concluidos = UserChallenge.query.filter_by(user_id=user_id, status='concluido').count()
    ativos = UserChallenge.query.filter_by(user_id=user_id, status='ativo').count()

    return jsonify({
        'stats': {
            'total': total,
            'concluidos': concluidos,
            'ativos': ativos,
            'taxa_sucesso': round((concluidos / total * 100), 1) if total > 0 else 0,
        }
    }), 200
