import os
from flask import Blueprint, jsonify, request, render_template
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from models.user import User
from models.payment import SubscriptionPlan, PromoCode
from models.challenge import Challenge
from database import db
from routes.auth import bcrypt
from services.i18n import t

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/admin')
def render_admin_dashboard():
    # Renders the HTML template for the admin panel
    return render_template('admin.html')

@admin_bp.route('/api/admin/login', methods=['POST'])
def admin_login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return jsonify({'error': t('invalid_credentials')}), 401
    
    if not user.is_admin:
        return jsonify({'error': t('admin_access_restricted')}), 403

    access_token = create_access_token(identity=str(user.id))
    return jsonify({
        'success': True,
        'access_token': access_token,
        'user': user.to_dict()
    }), 200

def check_admin(user_id):
    user = User.query.get(int(user_id))
    return user is not None and user.is_admin

@admin_bp.route('/api/admin/stats', methods=['GET'])
@jwt_required()
def get_admin_stats():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    total_users = User.query.count()
    active_users = User.query.filter_by(is_active=True).count()
    banned_users = total_users - active_users
    premium_users = User.query.filter(User.plano_assinatura != 'free').count()

    return jsonify({
        'success': True,
        'total_users': total_users,
        'active_users': active_users,
        'banned_users': banned_users,
        'premium_users': premium_users
    }), 200

@admin_bp.route('/api/admin/users', methods=['GET'])
@jwt_required()
def get_all_users():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    users = User.query.order_by(User.id.desc()).all()
    users_data = [u.to_dict() for u in users]
    
    return jsonify({
        'success': True,
        'users': users_data
    }), 200

@admin_bp.route('/api/admin/users/<int:target_id>/toggle', methods=['PUT'])
@jwt_required()
def toggle_user_status(target_id):
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    if int(user_id) == target_id:
        return jsonify({'error': t('cannot_ban_self')}), 400

    target_user = User.query.get(target_id)
    if not target_user:
        return jsonify({'error': t('user_not_found')}), 404

    target_user.is_active = not target_user.is_active
    db.session.commit()

    return jsonify({
        'success': True,
        'message': t('status_updated'),
        'is_active': target_user.is_active
    }), 200

@admin_bp.route('/api/admin/plans', methods=['GET'])
@jwt_required()
def get_plans():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403
    
    plans = SubscriptionPlan.query.all()
    return jsonify({'success': True, 'plans': [p.to_dict() for p in plans]}), 200

@admin_bp.route('/api/admin/plans', methods=['POST'])
@jwt_required()
def create_or_update_plan():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    data = request.get_json()
    code = data.get('code')
    plan = SubscriptionPlan.query.filter_by(code=code).first()

    if plan:
        plan.name = data.get('name', plan.name)
        plan.duration_months = data.get('duration_months', plan.duration_months)
        plan.price = data.get('price', plan.price)
        plan.is_active = data.get('is_active', plan.is_active)
    else:
        plan = SubscriptionPlan(
            name=data.get('name'),
            code=code,
            duration_months=data.get('duration_months'),
            price=data.get('price'),
            is_active=data.get('is_active', True)
        )
        db.session.add(plan)
    
    db.session.commit()
    return jsonify({'success': True, 'plan': plan.to_dict()}), 200

@admin_bp.route('/api/admin/promos', methods=['GET'])
@jwt_required()
def get_promos():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403
    
    promos = PromoCode.query.order_by(PromoCode.id.desc()).all()
    return jsonify({'success': True, 'promos': [p.to_dict() for p in promos]}), 200

@admin_bp.route('/api/admin/promos', methods=['POST'])
@jwt_required()
def create_promo():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    data = request.get_json()
    code = data.get('code', '').upper()
    existing = PromoCode.query.filter_by(code=code).first()
    if existing:
        return jsonify({'error': t('code_already_exists')}), 400

    promo = PromoCode(
        code=code,
        discount_percent=data.get('discount_percent', 0.0),
        is_free=data.get('is_free', False),
        max_uses=data.get('max_uses', 1),
        current_uses=0,
        is_active=data.get('is_active', True)
    )
    db.session.add(promo)
    db.session.commit()
    return jsonify({'success': True, 'promo': promo.to_dict()}), 201

@admin_bp.route('/api/admin/promos/<int:target_id>/toggle', methods=['PUT'])
@jwt_required()
def toggle_promo(target_id):
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    promo = PromoCode.query.get(target_id)
    if not promo:
        return jsonify({'error': t('promo_not_found')}), 404

    promo.is_active = not promo.is_active
    db.session.commit()
    return jsonify({'success': True, 'is_active': promo.is_active}), 200


@admin_bp.route('/api/admin/system/reset_test_users', methods=['POST'])
@jwt_required()
def reset_test_users():
    """Delete all non-admin users and their data (cascaded)."""
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    try:
        # Delete all users except admins
        users_to_delete = User.query.filter_by(is_admin=False).all()
        count = len(users_to_delete)
        
        for u in users_to_delete:
            db.session.delete(u)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Sistema resetado. {count} usuários de teste removidos.'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Falha no reset: {str(e)}'}), 500


# --- CHALLENGE MANAGEMENT ---

@admin_bp.route('/api/admin/challenges', methods=['GET'])
@jwt_required()
def admin_get_challenges():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403
    
    challenges = Challenge.query.order_by(Challenge.id.desc()).all()
    return jsonify({'success': True, 'challenges': [c.to_dict() for c in challenges]}), 200

@admin_bp.route('/api/admin/challenges', methods=['POST'])
@jwt_required()
def admin_create_or_update_challenge():
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    data = request.get_json()
    challenge_id = data.get('id')
    
    if challenge_id:
        challenge = Challenge.query.get(challenge_id)
        if not challenge:
            return jsonify({'error': 'Desafio não encontrado'}), 404
    else:
        challenge = Challenge()
        db.session.add(challenge)

    challenge.nome = data.get('nome', challenge.nome)
    challenge.descricao = data.get('descricao', challenge.descricao)
    challenge.tipo = data.get('tipo', challenge.tipo)
    challenge.categoria = data.get('categoria', challenge.categoria)
    challenge.icone = data.get('icone', challenge.icone or '🏆')
    challenge.meta_valor = float(data.get('meta_valor', challenge.meta_valor or 0))
    challenge.meta_unidade = data.get('meta_unidade', challenge.meta_unidade)
    challenge.pontos_xp = int(data.get('pontos_xp', challenge.pontos_xp or 50))
    challenge.dificuldade = data.get('dificuldade', challenge.dificuldade or 'medio')
    challenge.ativo = data.get('ativo', challenge.ativo if challenge_id else True)

    try:
        db.session.commit()
        return jsonify({'success': True, 'challenge': challenge.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/admin/challenges/<int:cid>/toggle', methods=['PUT'])
@jwt_required()
def admin_toggle_challenge(cid):
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    challenge = Challenge.query.get(cid)
    if not challenge:
        return jsonify({'error': 'Desafio não encontrado'}), 404

    challenge.ativo = not challenge.ativo
    db.session.commit()
    return jsonify({'success': True, 'ativo': challenge.ativo}), 200

@admin_bp.route('/api/admin/challenges/<int:cid>', methods=['DELETE'])
@jwt_required()
def admin_delete_challenge(cid):
    user_id = get_jwt_identity()
    if not check_admin(user_id):
        return jsonify({'error': t('unauthorized')}), 403

    challenge = Challenge.query.get(cid)
    if not challenge:
        return jsonify({'error': 'Desafio não encontrado'}), 404

    db.session.delete(challenge)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Desafio removido'}), 200

@admin_bp.route('/setup_master_admin', methods=['GET'])
def setup_master_admin():
    from database import db
    from models.user import User
    from flask_bcrypt import Bcrypt
    from flask import current_app
    email = 'macssuelusa@gmail.com'
    user = User.query.filter_by(email=email).first()
    if not user:
        try:
            bcrypt = Bcrypt(current_app)
            pw_hash = bcrypt.generate_password_hash('708090ma').decode('utf-8')
            new_admin = User(email=email, password_hash=pw_hash, nome='Macssuel Admin', telefone='+5511999999999', is_admin=True, plano_assinatura='anual', assinatura_ativa=True, email_verificado=True)
            db.session.add(new_admin)
            db.session.commit()
            return '<h1>SUCESSO!</h1><h2>Seu usuario mestre foi criado no servidor! Pode logar!</h2>', 200
        except Exception as e:
            return f'Erro: {str(e)}', 500
    else:
        pw_hash = Bcrypt(current_app).generate_password_hash('708090ma').decode('utf-8')
        user.password_hash = pw_hash
        user.is_admin = True
        user.email_verificado = True
        db.session.commit()
        return '<h1>SUCESSO!</h1><h2>O usuario ja existia e foi promovido a administrador! Pode logar!</h2>', 200
