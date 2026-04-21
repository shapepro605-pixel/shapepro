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


def _send_async_email(app, message, diagnostic_prefix="EMAIL", sync=False):
    """Internal helper to send email. If sync=True, sends blocking to catch errors."""
    if sync:
        try:
            recipient = message.recipients[0] if message.recipients else "desconhecido"
            print(f"\n[{diagnostic_prefix}] 📨 [SYNC] Enviando para {recipient}...")
            # Use real app context for synchronous sending too
            with app.app_context():
                app.mail.send(message)
            print(f"[{diagnostic_prefix}] ✅ [SYNC] ENVIADO COM SUCESSO!\n")
            return True, "Enviado"
        except Exception as e:
            error_msg = str(e)
            print(f"[{diagnostic_prefix}] ❌ [SYNC] FALHA: {error_msg}\n")
            return False, error_msg

    from threading import Thread
    
    def send_thread(app_ctx, msg):
        with app_ctx.app_context():
            try:
                recipient = msg.recipients[0] if msg.recipients else "desconhecido"
                print(f"\n[{diagnostic_prefix}] 📨 Iniciando envio para {recipient}...")
                print(f"  - Servidor: {app_ctx.config.get('MAIL_SERVER')}:{app_ctx.config.get('MAIL_PORT')}")
                print(f"  - SSL: {app_ctx.config.get('MAIL_USE_SSL')}, TLS: {app_ctx.config.get('MAIL_USE_TLS')}")
                
                app_ctx.mail.send(msg)
                print(f"[{diagnostic_prefix}] ✅ E-MAIL ENVIADO COM SUCESSO!\n")
            except Exception as e:
                print(f"[{diagnostic_prefix}] ❌ FALHA CRÍTICA NO ENVIO: {str(e)}\n")

    # Obter o objeto real do app (lidando com LocalProxy se necessário)
    try:
        app_instance = app._get_current_object()
    except AttributeError:
        app_instance = app
        
    Thread(target=send_thread, args=(app_instance, message)).start()


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
        
        # --- Trigger Verification Email ---
        # Generate a 6 digit code
        token = ''.join(secrets.choice(string.digits) for _ in range(6))
        new_user.otp_code = token
        db.session.commit()

        # Create verification link
        base_url = "https://shapepro-production.up.railway.app"
        verify_link = f"{base_url}/api/auth/verify_email?uid={new_user.id}&token={token}"
        
        from flask_mail import Message
        msg = Message(
            subject="Bem-vindo ao ShapePro - Verifique sua conta",
            recipients=[email],
            body=f"Olá {nome},\n\nSua conta foi criada com sucesso! Falta apenas um passo para você começar sua jornada fitness.\n\nSeu código de verificação é:\n\n{token}\n\nVocê também pode clicar no link abaixo para verificar seu e-mail automaticamente:\n\n{verify_link}\n\nSe você não solicitou este cadastro, pode ignorar esta mensagem.\n\nAtenciosamente,\nEquipe ShapePro"
        )
        _send_async_email(current_app, msg, "REGISTRO")
        # ---------------------------------

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




@auth_bp.route('/debug_firebase', methods=['GET'])
def debug_firebase():
    """Diagnostic route to check Firebase status."""
    import os
    creds = os.getenv('FIREBASE_CREDENTIALS_JSON')
    env_keys = list(os.environ.keys())
    return jsonify({
        'initialized': is_firebase_initialized(),
        'has_creds': creds is not None,
        'creds_len': len(creds) if creds else 0,
        'env_keys': [k for k in env_keys if 'FIREBASE' in k or 'DATABASE' in k or 'MAIL' in k]
    })

@auth_bp.route('/verify_sms', methods=['POST'])
def verify_sms():
    """Verify phone via Firebase ID token or local code.
    If Firebase token is valid, logs in the user directly.
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400

    firebase_id_token = data.get('firebase_id_token')
    
    # 1. Firebase token-based verification (Primary)
    if firebase_id_token and is_firebase_initialized():
        decoded = _verify_firebase_token(firebase_id_token)
        if decoded:
            # Token is valid — extract phone number from Firebase claims
            firebase_phone = decoded.get('phone_number', '')
            if not firebase_phone:
                return jsonify({'error': 'Número de telefone não encontrado no token Firebase.'}), 400
            
            # Find user by phone (normalized via temp User object)
            temp_user = User(telefone=firebase_phone)
            user = User.query.filter_by(telefone=temp_user.telefone).first()
            
            if user:
                user.telefone_verificado = True
                db.session.commit()
                
                # Generate Tokens for Login
                access_token = create_access_token(identity=str(user.id))
                refresh_token = create_refresh_token(identity=str(user.id))
                
                return jsonify({
                    'success': True, 
                    'message': 'Login via telefone realizado!',
                    'user': user.to_dict(),
                    'access_token': access_token,
                    'refresh_token': refresh_token
                }), 200
            else:
                # User exists in Firebase but not in our DB -> Should Register
                return jsonify({
                    'success': True,
                    'needs_registration': True,
                    'phone': firebase_phone,
                    'message': 'Usuário não encontrado. Prossiga para o cadastro.'
                }), 200
        else:
            return jsonify({'error': 'Token Firebase inválido ou expirado.'}), 400

    # 2. Fallback: local OTP code verification (Requires JWT)
    from flask_jwt_extended import verify_jwt_in_request as _verify_jwt
    try:
        _verify_jwt()
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))

        code = str(data.get('code', '')).strip()
        if user and code and user.otp_code and user.otp_code == code:
            user.telefone_verificado = True
            user.otp_code = None
            db.session.commit()
            return jsonify({'success': True, 'message': 'Telefone verificado!', 'user': user.to_dict()}), 200
    except Exception as e:
        print(f"[VERIFY ERROR] Erro na rota verify_sms: {str(e)}")
        return jsonify({'error': f'Falha técnica: {str(e)}'}), 500

    return jsonify({'error': 'Verificação falhou. Verifique o código enviado.'}), 400


@auth_bp.route('/google_login', methods=['POST'])
def google_login():
    """Authenticate user via Google Sign-In (Firebase ID token).
    Finds existing user by email or auto-registers a new account.
    Uses proper bcrypt hash for password (not a stub).
    """
    data = request.get_json()
    if not data or 'id_token' not in data:
        return jsonify({'error': 'ID Token não fornecido'}), 400

    id_token = data['id_token']
    if not is_firebase_initialized():
        return jsonify({'error': 'Firebase não configurado no servidor.'}), 500

    decoded = _verify_firebase_token(id_token)
    if not decoded:
        return jsonify({'error': 'Token inválido ou expirado.'}), 401

    # Extract info from Google/Firebase claims
    email = decoded.get('email', '').lower()
    name = decoded.get('name', 'Usuário Google')

    if not email:
        return jsonify({'error': 'E-mail não encontrado no token Google.'}), 400

    # Find or create user
    user = User.query.filter_by(email=email).first()
    if not user:
        # Auto-register Google users — generate a real random bcrypt hash
        temp_pass = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(20))
        password_hash = bcrypt.generate_password_hash(temp_pass).decode('utf-8')

        user = User(
            email=email,
            nome=name,
            telefone=decoded.get('phone_number', ''),
            password_hash=password_hash,
            telefone_verificado=True  # Google accounts are pre-verified
        )
        db.session.add(user)
        db.session.commit()

    # Generate tokens
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        'success': True,
        'message': 'Login via Google realizado!',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    }), 200


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
        # Use a temporary User instance to benefit from phone normalization logic
        temp_user = User(telefone=identifier)
        user = User.query.filter_by(telefone=temp_user.telefone).first()

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
    updatable = [
        'nome', 'idade', 'altura', 'peso', 'sexo', 'objetivo', 
        'nivel_atividade', 'ritmo_meta', 'foto_perfil',
        'pais', 'moeda', 'estado', 'cidade', 'renda_mensal', 'orcamento_dieta'
    ]
    location_changed = False
    if 'pais' in data and data['pais'] != user.pais: location_changed = True
    if 'cidade' in data and data['cidade'] != user.cidade: location_changed = True

    for field in updatable:
        if field in data:
            setattr(user, field, data[field])

    db.session.commit()

    # Trigger regional price research if location changed
    if location_changed:
        try:
            from services.food_price_service import FoodPriceService
            FoodPriceService.simulate_ai_research(user.pais, user.cidade)
        except Exception as e:
            print(f"[ShapePro AI] Price research trigger error: {e}")

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

    try:
        # User deletion will cascade via db.relationship definitions 
        # for dietas, treinos, weight_logs, water_logs, desafios, conquistas, etc.
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
    msg = Message(
        subject="Recuperacao de Senha - ShapePro",
        recipients=[email],
        body=f"Ola,\n\nRecebemos uma solicitacao de redefinicao de senha para sua conta ShapePro.\n\nSua nova senha temporaria e: {temp_password}\n\nRecomendamos que voce altere esta senha imediatamente apos entrar no aplicativo.\n\nAtenciosamente,\nEquipe ShapePro"
    )

    _send_async_email(current_app, msg, "PASSWORD_RESET")

    return jsonify({
        'success': True,
        'message': 'Se o email estiver cadastrado, voce recebera instrucoes para redefinir sua senha.'
    }), 200

@auth_bp.route('/send_verification_email', methods=['POST'])
@jwt_required()
def send_verification_email():
    """Generate and send a verification email to the logged-in user."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado.'}), 404
        
    if user.email_verificado:
        return jsonify({'success': True, 'message': 'E-mail já verificado.'}), 200
        
    # Generate a 6 digit code
    token = ''.join(secrets.choice(string.digits) for _ in range(6))
    user.otp_code = token
    db.session.commit()
    
    # Create verification link
    base_url = "https://shapepro-production.up.railway.app"
    verify_link = f"{base_url}/api/auth/verify_email?uid={user.id}&token={token}"
    
    from flask_mail import Message
    msg = Message(
        subject="Verifique sua conta ShapePro",
        recipients=[user.email],
        body=f"Olá {user.nome},\n\nFalta pouco para você começar sua transformação!\n\nSeu código de verificação é:\n\n{token}\n\nVocê também pode clicar no link abaixo para verificar seu e-mail e ativar sua conta:\n\n{verify_link}\n\nSe você não solicitou este e-mail, pode ignorar esta mensagem.\n\nAtenciosamente,\nEquipe ShapePro"
    )

    # --- ASYNC MODE: Backend thread sending ---
    _send_async_email(current_app, msg, "VERIFY_EMAIL", sync=True)
    
    return jsonify({
        'success': True,
        'message': 'Link de verificação enviado para seu e-mail!'
    }), 200


@auth_bp.route('/verify_email', methods=['GET'])
def verify_email_endpoint():
    """Endpoint for user to click and verify their email."""
    user_id = request.args.get('uid')
    token = request.args.get('token')

    if not user_id or not token:
        return "Link inválido ou expirado.", 400

    user = User.query.get(int(user_id))
    if not user or user.otp_code != token:
        return "Link inválido ou conta não existe.", 400

    user.email_verificado = True
    user.otp_code = None  # consume token
    db.session.commit()

    return f'''
    <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{ font-family: sans-serif; text-align: center; background-color: #0A0A1A; color: white; padding: 40px; }}
                h1 {{ color: #6C5CE7; }}
                p {{ font-size: 18px; color: #aaa; }}
                .btn {{ display: inline-block; padding: 12px 24px; background-color: #6C5CE7; color: white; text-decoration: none; border-radius: 8px; margin-top: 20px; font-weight: bold; }}
            </style>
        </head>
        <body>
            <h1>✔ CONTA VERIFICADA</h1>
            <p>Seu e-mail <b>{user.email}</b> foi confirmado com sucesso!</p>
            <p>Você já pode fechar esta tela e voltar para o aplicativo ShapePro.</p>
        </body>
    </html>
    '''

@auth_bp.route('/verify_email_code', methods=['POST'])
@jwt_required()
def verify_email_code():
    """Verify email via 6-digit OTP code directly in the app."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado.'}), 404
        
    data = request.get_json()
    code = str(data.get('code', '')).strip()
    
    if not code:
        return jsonify({'error': 'Código não fornecido.'}), 400
        
    if user.otp_code and user.otp_code == code:
        user.email_verificado = True
        user.otp_code = None
        db.session.commit()
        return jsonify({'success': True, 'message': 'E-mail verificado com sucesso!', 'user': user.to_dict()}), 200
        
    return jsonify({'error': 'Código inválido ou expirado.'}), 400


