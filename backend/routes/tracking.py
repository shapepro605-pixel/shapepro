from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import db
from models.user import User, WeightLog, BodyMetric, WaterLog

from services.streak_service import StreakService

tracking_bp = Blueprint('tracking', __name__, url_prefix='/api/tracking')

@tracking_bp.route('/weight', methods=['POST'])
@jwt_required()
def log_weight():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if 'peso' not in data:
        return jsonify({'error': 'Peso é obrigatório'}), 400
        
    log = WeightLog(user_id=user_id, peso=data['peso'])
    
    # Update user current weight
    user = User.query.get(user_id)
    user.peso = data['peso']
    
    db.session.add(log)
    db.session.commit()
    
    return jsonify({'message': 'Peso registrado!', 'peso': data['peso']}), 201

@tracking_bp.route('/metrics', methods=['POST'])
@jwt_required()
def log_metrics():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    metric = BodyMetric(
        user_id=user_id,
        cintura=data.get('cintura'),
        peito=data.get('peito'),
        braco_esq=data.get('braco_esq'),
        braco_dir=data.get('braco_dir'),
        coxa_esq=data.get('coxa_esq'),
        coxa_dir=data.get('coxa_dir'),
        percentual_gordura=data.get('percentual_gordura')
    )
    
    db.session.add(metric)
    db.session.commit()
    
    return jsonify({'message': 'Métricas registradas!', 'metrics': metric.to_dict()}), 201

@tracking_bp.route('/metrics/history', methods=['GET'])
@jwt_required()
def get_metrics_history():
    user_id = get_jwt_identity()
    metrics = BodyMetric.query.filter_by(user_id=user_id).order_by(BodyMetric.data.desc()).limit(10).all()
    return jsonify({'history': [m.to_dict() for m in metrics]}), 200

@tracking_bp.route('/water', methods=['POST'])
@jwt_required()
def log_water():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if 'ml' not in data:
        return jsonify({'error': 'Quantidade em ML é obrigatória'}), 400
        
    log = WaterLog(user_id=user_id, quantidade_ml=data['ml'])
    db.session.add(log)
    db.session.commit()
    
    # Get today total
    today = datetime.utcnow().date()
    total_today = db.session.query(db.func.sum(WaterLog.quantidade_ml)).filter(
        WaterLog.user_id == user_id,
        db.func.date(WaterLog.data) == today
    ).scalar() or 0
    
    # Auto-update water challenges
    StreakService.update_challenge_progress(user_id, 'agua', data['ml'])
    
    return jsonify({'message': 'Água registrada!', 'total_today': total_today}), 201

@tracking_bp.route('/water/today', methods=['GET'])
@jwt_required()
def get_water_today():
    user_id = get_jwt_identity()
    today = datetime.utcnow().date()
    total_today = db.session.query(db.func.sum(WaterLog.quantidade_ml)).filter(
        WaterLog.user_id == user_id,
        db.func.date(WaterLog.data) == today
    ).scalar() or 0
    
    return jsonify({'total_today': total_today}), 200


# ── SLEEP ──────────────────────────────────────────────────────────────

@tracking_bp.route('/sleep', methods=['POST'])
@jwt_required()
def log_sleep():
    """Log a sleep entry."""
    from models.challenge import SleepLog
    
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data or 'hora_dormir' not in data or 'hora_acordar' not in data:
        return jsonify({'error': 'hora_dormir e hora_acordar são obrigatórios'}), 400
    
    # Calculate duration
    duracao = data.get('duracao_horas')
    if not duracao:
        try:
            h1, m1 = map(int, data['hora_dormir'].split(':'))
            h2, m2 = map(int, data['hora_acordar'].split(':'))
            minutos_dormir = h1 * 60 + m1
            minutos_acordar = h2 * 60 + m2
            if minutos_acordar <= minutos_dormir:
                minutos_acordar += 24 * 60  # next day
            duracao = round((minutos_acordar - minutos_dormir) / 60, 1)
        except (ValueError, AttributeError):
            duracao = 0
    
    log = SleepLog(
        user_id=user_id,
        hora_dormir=data['hora_dormir'],
        hora_acordar=data['hora_acordar'],
        duracao_horas=duracao,
        qualidade=data.get('qualidade', 3),
        notas=data.get('notas', '')
    )
    
    db.session.add(log)
    db.session.commit()
    
    # Auto-update sleep challenges
    StreakService.update_challenge_progress(user_id, 'sono', duracao)
    
    return jsonify({'message': 'Sono registrado!', 'sleep': log.to_dict()}), 201


@tracking_bp.route('/sleep/history', methods=['GET'])
@jwt_required()
def get_sleep_history():
    """Get sleep history."""
    from models.challenge import SleepLog
    
    user_id = get_jwt_identity()
    logs = SleepLog.query.filter_by(
        user_id=user_id
    ).order_by(SleepLog.data.desc()).limit(30).all()
    
    return jsonify({'history': [log.to_dict() for log in logs]}), 200


@tracking_bp.route('/sleep/stats', methods=['GET'])
@jwt_required()
def get_sleep_stats():
    """Get sleep statistics for the last 7 and 30 days."""
    from models.challenge import SleepLog
    from datetime import timedelta
    
    user_id = get_jwt_identity()
    now = datetime.utcnow()
    
    # Last 7 days
    week_logs = SleepLog.query.filter(
        SleepLog.user_id == user_id,
        SleepLog.data >= now - timedelta(days=7)
    ).all()
    
    # Last 30 days
    month_logs = SleepLog.query.filter(
        SleepLog.user_id == user_id,
        SleepLog.data >= now - timedelta(days=30)
    ).all()
    
    def calc_stats(logs):
        if not logs:
            return {'media_horas': 0, 'media_qualidade': 0, 'total_registros': 0}
        return {
            'media_horas': round(sum(l.duracao_horas for l in logs) / len(logs), 1),
            'media_qualidade': round(sum(l.qualidade for l in logs) / len(logs), 1),
            'total_registros': len(logs),
        }
    
    return jsonify({
        'stats': {
            'semana': calc_stats(week_logs),
            'mes': calc_stats(month_logs),
        }
    }), 200


# ── WEARABLE DATA ──────────────────────────────────────────────────────

@tracking_bp.route('/wearable/sync', methods=['POST'])
@jwt_required()
def sync_wearable_data():
    """Sync daily data from wearable/smartwatch."""
    from models.wearable import WearableData
    
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400
    
    today = datetime.utcnow().date()
    
    # Try to find existing record for today
    log = WearableData.query.filter_by(user_id=user_id, data=today).first()
    
    if not log:
        log = WearableData(user_id=user_id, data=today)
        db.session.add(log)
    
    # Update fields
    log.steps = data.get('steps', log.steps)
    log.calories = data.get('calories', log.calories)
    log.distance = data.get('distance', log.distance)
    log.heart_rate = data.get('heartRate', log.heart_rate)
    log.sleep_minutes = data.get('sleep', log.sleep_minutes)
    log.fitness_score = data.get('fitnessScore', log.fitness_score)
    log.source = data.get('source', log.source)
    log.last_sync = datetime.utcnow()
    
    db.session.commit()
    
    # Auto-update challenges
    if 'steps' in data:
        StreakService.update_challenge_progress(user_id, 'passos', data['steps'])
    if 'sleep' in data:
        # Convert minutes to hours for challenge
        StreakService.update_challenge_progress(user_id, 'sono', round(data['sleep'] / 60, 1))
    
    return jsonify({'message': 'Sincronização concluída!', 'data': log.to_dict()}), 200


@tracking_bp.route('/wearable/history', methods=['GET'])
@jwt_required()
def get_wearable_history():
    """Get wearable data history."""
    from models.wearable import WearableData
    
    user_id = get_jwt_identity()
    logs = WearableData.query.filter_by(
        user_id=user_id
    ).order_by(WearableData.data.desc()).limit(30).all()
    
    return jsonify({'history': [log.to_dict() for log in logs]}), 200


# ── Helper ─────────────────────────────────────────────────────────────

