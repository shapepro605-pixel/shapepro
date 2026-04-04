import random
import secrets
import string
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
from flask_bcrypt import Bcrypt
from database import db
from models.user import User
from services.i18n import t
from firebase_init import is_firebase_initialized

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')
bcrypt = Bcrypt() # Used as a utility for hashing/checking


def _verify_firebase_token(id_token):
    """Verify a Firebase ID token and return the decoded claims.
    Returns None if Firebase is not configured or verification fails."""
    if not is_firebase_initialized():
        return None
    try:
        from firebase_admin import auth as firebase_auth
        decoded = firebase_auth.verify_id_token(id_token)
        return decoded
    except Exception as e:
        print(f"[FIREBASE] Token verification failed: {e}")
        return None


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user."""
    data = request.get_json()

    # Validation
    if not data:
        return jsonify({'error': t('data_not_provided')}), 400

    required_fields = ['email', 'password', 'nome', 'telefone']
    for field in required_fields:
        if field not in data or not data[field]:
            return jsonify({'error': t('field_required', field=field)}), 400

    email = data['email'].strip().lower()
    password = data['password']
    nome = data['nome'].strip()
    telefone = data.get('telefone', '').strip()

    # Formatar telefone para E.164 (ex: +5511999999999) se necessário
    if telefone:
        import re
        clean_phone = re.sub(r'[^\d+]', '', telefone)
        if not clean_phone.startswith('+') and len(clean_phone) >= 10:
            clean_phone = f"+55{clean_phone}"
        telefone = clean_phone

    if len(password) < 6:
        return jsonify({'error': t('password_min_length')}), 400

    # Check if user already exists
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({'error': t('email_already_registered')}), 409

    # Check for duplicate phone
    if telefone:
        existing_phone = User.query.filter_by(telefone=telefone).first()
        if existing_phone:
            return jsonify({'error': t('phone_already_registered')}), 409

    # Create user (phone verification will be done via Firebase on the client)
    password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    new_user = User(
        email=email,
        telefone=telefone,
        otp_code=None,
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

    try:
        db.session.add(new_user)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        print(f"[ERRO] Falha ao criar usuário: {e}")
        return jsonify({'error': 'Erro ao criar conta. Verifique os dados e tente novamente.'}), 500

    # Generate tokens
    access_token = create_access_token(identity=str(new_user.id))
    refresh_token = create_refresh_token(identity=str(new_user.id))

    return jsonify({
        'success': True,
        'message': t('account_created'),
        'user': new_user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token,
    }), 201




@auth_bp.route('/verify_sms', methods=['POST'])
@jwt_required()
def verify_sms():
    """Verify phone via Firebase ID token.
    The Flutter app sends the Firebase ID token after successful phone verification.
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400

    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    # Firebase token-based verification
    firebase_id_token = data.get('firebase_id_token')
    if firebase_id_token and is_firebase_initialized():
        decoded = _verify_firebase_token(firebase_id_token)
        if decoded:
            # Token is valid — extract phone number from Firebase claims
            firebase_phone = decoded.get('phone_number', '')
            
            # Validate that the Firebase-verified phone matches the user's phone
            if firebase_phone and (firebase_phone == user.telefone or firebase_phone.endswith(user.telefone[-9:])):
                user.telefone_verificado = True
                db.session.commit()
                return jsonify({'success': True, 'message': 'Telefone verificado!', 'user': user.to_dict()}), 200
            else:
                return jsonify({'error': 'O número verificado não corresponde ao cadastrado.'}), 400
        else:
            return jsonify({'error': 'Token Firebase inválido ou expirado.'}), 400

    # Fallback: local OTP code verification (for dev/testing without Firebase)
    code = str(data.get('code', '')).strip()
    if code and user.otp_code and user.otp_code == code:
        user.telefone_verificado = True
        user.otp_code = None
        db.session.commit()
        return jsonify({'success': True, 'message': 'Telefone verificado!', 'user': user.to_dict()}), 200

    return jsonify({'error': 'Verificação falhou. Tente novamente.'}), 400


@auth_bp.route('/resend_sms', methods=['POST'])
@jwt_required()
def resend_sms():
    """Resend SMS verification.
    With Firebase, the resend is handled client-side.
    This endpoint exists for backward compatibility and fallback.
    """
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    if is_firebase_initialized():
        # Firebase handles resend on the client side
        return jsonify({'success': True, 'message': 'Use o app para reenviar o código via Firebase.'}), 200
    else:
        # Fallback: generate local OTP for testing
        user.otp_code = str(random.randint(100000, 999999))
        print(f"\n[REENVIO MOCK] PARA {user.telefone}: {user.otp_code}\n")
        db.session.commit()
    
    return jsonify({'success': True, 'message': 'Código reenviado'}), 200


@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticate user and return tokens."""
    data = request.get_json()

    if not data or 'email' not in data or 'password' not in data:
        return jsonify({'error': t('email_password_required')}), 400

    identifier = data['email'].strip().lower() # Pode vir email ou telefone
    password = data['password']

    # 1. Tentar busca por Email
    user = User.query.filter_by(email=identifier).first()
    
    # 2. Se não achou, tentar busca por Telefone
    if not user:
        phone_id = identifier
        import re
        phone_id = re.sub(r'[^\d+]', '', phone_id)
        if not phone_id.startswith('+') and len(phone_id) >= 10:
            phone_id = f"+55{phone_id}"
        
        user = User.query.filter_by(telefone=phone_id).first()

    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return jsonify({'error': t('invalid_email_password')}), 401

    if not getattr(user, 'is_active', True):
        return jsonify({'error': t('account_suspended')}), 403

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        'success': True,
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

    # Manually delete orphans in challenge tables that don't have cascade setup
    from models.challenge import UserChallenge, UserAchievement, SleepLog, JournalEntry
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


@auth_bp.route('/reset_password', methods=['POST'])
def reset_password():
    """Reset password for a user account. Generates a temporary password."""
    data = request.get_json()
    if not data or 'email' not in data:
        return jsonify({'error': 'Informe o email cadastrado.'}), 400

    email = data['email'].strip().lower()
    user = User.query.filter_by(email=email).first()

    if not user:
        # For security, don't reveal if email exists or not
        return jsonify({
            'success': True,
            'message': 'Se o email estiver cadastrado, você receberá instruções para redefinir sua senha.'
        }), 200

    # Generate a temporary password
    temp_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(10))
    user.password_hash = bcrypt.generate_password_hash(temp_password).decode('utf-8')
    db.session.commit()

    # In production, send via email service.
    from flask_mail import Message
    from flask import current_app
    
    try:
        msg = Message(
            subject="Recuperação de Senha - ShapePro",
            recipients=[email],
            body=f"Olá,\n\nRecebemos uma solicitação de redefinição de senha para sua conta ShapePro.\n\nSua nova senha temporária é: {temp_password}\n\nRecomendamos que você altere esta senha imediatamente após entrar no aplicativo.\n\nAtenciosamente,\nEquipe ShapePro"
        )
        current_app.mail.send(msg)
        print(f"\n[RESET SENHA] 📧 E-mail enviado para {email}\n")
    except Exception as e:
        print(f"\n[RESET SENHA] ❌ Erro ao enviar e-mail para {email}: {str(e)}\n")
        # Log temp password for emergency even if email fails
        print(f"[FALLBACK] Senha: {temp_password}")


    return jsonify({
        'success': True,
        'message': 'Se o email estiver cadastrado, você receberá instruções para redefinir sua senha.'
    }), 200
