"""
ShapePro - Journal Routes
Wellness journaling endpoints inspired by BetFit.
"""

from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import db
from models.challenge import JournalEntry

journal_bp = Blueprint('journal', __name__, url_prefix='/api/journal')


@journal_bp.route('', methods=['POST'])
@jwt_required()
def create_entry():
    """Create a new journal entry."""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400

    entry = JournalEntry(
        user_id=user_id,
        humor=data.get('humor', 3),
        energia=data.get('energia', 3),
        estresse=data.get('estresse', 3),
        notas=data.get('notas', ''),
        tags=','.join(data.get('tags', [])) if isinstance(data.get('tags'), list) else data.get('tags', ''),
    )

    db.session.add(entry)
    db.session.commit()

    # Auto-update journal challenges
    _atualizar_desafio_diario(user_id, 'diario')

    return jsonify({
        'message': 'Entrada registrada!',
        'entry': entry.to_dict()
    }), 201


@journal_bp.route('', methods=['GET'])
@jwt_required()
def list_entries():
    """List recent journal entries."""
    user_id = int(get_jwt_identity())
    limit = request.args.get('limit', 10, type=int)

    entries = JournalEntry.query.filter_by(
        user_id=user_id
    ).order_by(JournalEntry.data.desc()).limit(limit).all()

    return jsonify({'entries': [e.to_dict() for e in entries]}), 200


@journal_bp.route('/stats', methods=['GET'])
@jwt_required()
def journal_stats():
    """Get journal statistics over the last 7 and 30 days."""
    user_id = int(get_jwt_identity())

    now = datetime.utcnow()
    week_ago = now - timedelta(days=7)
    month_ago = now - timedelta(days=30)

    # Last 7 days
    week_entries = JournalEntry.query.filter(
        JournalEntry.user_id == user_id,
        JournalEntry.data >= week_ago
    ).all()

    # Last 30 days
    month_entries = JournalEntry.query.filter(
        JournalEntry.user_id == user_id,
        JournalEntry.data >= month_ago
    ).all()

    def calc_avg(entries, field):
        if not entries:
            return 0
        return round(sum(getattr(e, field) for e in entries) / len(entries), 1)

    return jsonify({
        'stats': {
            'semana': {
                'total_entradas': len(week_entries),
                'humor_medio': calc_avg(week_entries, 'humor'),
                'energia_media': calc_avg(week_entries, 'energia'),
                'estresse_medio': calc_avg(week_entries, 'estresse'),
            },
            'mes': {
                'total_entradas': len(month_entries),
                'humor_medio': calc_avg(month_entries, 'humor'),
                'energia_media': calc_avg(month_entries, 'energia'),
                'estresse_medio': calc_avg(month_entries, 'estresse'),
            },
        }
    }), 200


@journal_bp.route('/<int:entry_id>', methods=['DELETE'])
@jwt_required()
def delete_entry(entry_id):
    """Delete a journal entry."""
    user_id = int(get_jwt_identity())
    entry = JournalEntry.query.get(entry_id)

    if not entry or entry.user_id != user_id:
        return jsonify({'error': 'Entrada não encontrada'}), 404

    db.session.delete(entry)
    db.session.commit()

    return jsonify({'message': 'Entrada removida!'}), 200


def _atualizar_desafio_diario(user_id, categoria):
    """Auto-update active challenges related to this category."""
    from models.challenge import UserChallenge, Challenge

    active = UserChallenge.query.join(Challenge).filter(
        UserChallenge.user_id == user_id,
        UserChallenge.status == 'ativo',
        Challenge.categoria == categoria
    ).all()

    for uc in active:
        uc.progresso = (uc.progresso or 0) + 1
        if uc.progresso >= uc.challenge.meta_valor:
            uc.status = 'concluido'
            uc.data_conclusao = datetime.utcnow()
            from models.user import User
            user = User.query.get(user_id)
            if user:
                user.pontos_xp = (user.pontos_xp or 0) + uc.challenge.pontos_xp

    db.session.commit()
