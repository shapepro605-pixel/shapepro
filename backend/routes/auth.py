from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
from flask_bcrypt import Bcrypt
from database import db
from models.user import User
from services.i18n import t

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')
bcrypt = Bcrypt()


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user."""
    data = request.get_json()

    # Validation
    if not data:
        return jsonify({'error': t('data_not_provided')}), 400

    required_fields = ['email', 'password', 'nome']
    for field in required_fields:
        if field not in data or not data[field]:
            return jsonify({'error': t('field_required', field=field)}), 400

    email = data['email'].strip().lower()
    password = data['password']
    nome = data['nome'].strip()

    if len(password) < 6:
        return jsonify({'error': t('password_min_length')}), 400

    # Check if user already exists
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({'error': t('email_already_registered')}), 409

    # Create user
    password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    new_user = User(
        email=email,
        password_hash=password_hash,
        nome=nome,
        idade=data.get('idade'),
        altura=data.get('altura'),
        peso=data.get('peso'),
        sexo=data.get('sexo'),
        objetivo=data.get('objetivo'),
        nivel_atividade=data.get('nivel_atividade'),
        ritmo_meta=data.get('ritmo_meta', 'padrao'),
    )

    db.session.add(new_user)
    db.session.commit()

    # Generate tokens
    access_token = create_access_token(identity=str(new_user.id))
    refresh_token = create_refresh_token(identity=str(new_user.id))

    return jsonify({
        'message': t('account_created'),
        'user': new_user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token,
    }), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticate user and return tokens."""
    data = request.get_json()

    if not data or 'email' not in data or 'password' not in data:
        return jsonify({'error': t('email_password_required')}), 400

    email = data['email'].strip().lower()
    password = data['password']

    user = User.query.filter_by(email=email).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return jsonify({'error': t('invalid_email_password')}), 401

    if not getattr(user, 'is_active', True):
        return jsonify({'error': t('account_suspended')}), 403

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        'message': t('login_success'),
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token,
    }), 200


@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Get current user profile."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    return jsonify({'user': user.to_dict()}), 200


@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update user profile."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    data = request.get_json()
    if not data:
        return jsonify({'error': t('data_not_provided')}), 400

    # Updatable fields
    updatable = ['nome', 'idade', 'altura', 'peso', 'sexo', 'objetivo', 'nivel_atividade', 'ritmo_meta']
    for field in updatable:
        if field in data:
            setattr(user, field, data[field])

    db.session.commit()

    return jsonify({
        'success': True,
        'message': t('profile_updated'),
        'user': user.to_dict(),
    }), 200


@auth_bp.route('/profile', methods=['DELETE'])
@jwt_required()
def delete_profile():
    """Hard delete user account and all personal data."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    # Manually delete orphans in gamification tables that don't have cascade setup
    from models.gamification import UserChallenge, UserAchievement, SleepLog, JournalEntry
    try:
        UserChallenge.query.filter_by(user_id=user.id).delete()
        UserAchievement.query.filter_by(user_id=user.id).delete()
        SleepLog.query.filter_by(user_id=user.id).delete()
        JournalEntry.query.filter_by(user_id=user.id).delete()
        
        # User deletion will cascade via db.relationship definitions 
        # for dietas, treinos, weight_logs, water_logs, etc.
        db.session.delete(user)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete account data: ' + str(e)}), 500

    return jsonify({'success': True, 'message': t('account_deleted')}), 200


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token."""
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify({'access_token': access_token}), 200


@auth_bp.route('/weight', methods=['POST'])
@jwt_required()
def log_weight():
    """Log a weight entry."""
    from models.user import WeightLog

    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'peso' not in data:
        return jsonify({'error': t('weight_required')}), 400

    log = WeightLog(user_id=int(user_id), peso=data['peso'])
    db.session.add(log)

    # Also update user's current weight
    user = User.query.get(int(user_id))
    if user:
        user.peso = data['peso']

    db.session.commit()

    return jsonify({'message': t('weight_logged'), 'log': log.to_dict()}), 201


@auth_bp.route('/weight', methods=['GET'])
@jwt_required()
def get_weight_history():
    """Get weight history."""
    from models.user import WeightLog

    user_id = get_jwt_identity()
    logs = WeightLog.query.filter_by(user_id=int(user_id)).order_by(WeightLog.data.desc()).limit(30).all()

    return jsonify({'logs': [log.to_dict() for log in logs]}), 200
