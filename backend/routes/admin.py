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

 @ a d m i n _ b p . r o u t e ( ' / s e t u p _ m a s t e r _ a d m i n ' ,   m e t h o d s = [ ' G E T ' ] ) 
 d e f   s e t u p _ m a s t e r _ a d m i n ( ) : 
         f r o m   d a t a b a s e   i m p o r t   d b 
         f r o m   m o d e l s . u s e r   i m p o r t   U s e r 
         f r o m   f l a s k _ b c r y p t   i m p o r t   B c r y p t 
         f r o m   f l a s k   i m p o r t   c u r r e n t _ a p p 
         e m a i l   =   ' m a c s s u e l u s a @ g m a i l . c o m ' 
         u s e r   =   U s e r . q u e r y . f i l t e r _ b y ( e m a i l = e m a i l ) . f i r s t ( ) 
         i f   n o t   u s e r : 
                 t r y : 
                         b c r y p t   =   B c r y p t ( c u r r e n t _ a p p ) 
                         p w _ h a s h   =   b c r y p t . g e n e r a t e _ p a s s w o r d _ h a s h ( ' 7 0 8 0 9 0 m a ' ) . d e c o d e ( ' u t f - 8 ' ) 
                         n e w _ a d m i n   =   U s e r ( 
                                 e m a i l = e m a i l , 
                                 p a s s w o r d _ h a s h = p w _ h a s h , 
                                 n o m e = ' M a c s s u e l   A d m i n ' , 
                                 t e l e f o n e = ' + 5 5 1 1 9 9 9 9 9 9 9 9 9 ' , 
                                 i s _ a d m i n = T r u e , 
                                 p l a n o _ a s s i n a t u r a = ' a n u a l ' , 
                                 a s s i n a t u r a _ a t i v a = T r u e , 
                                 e m a i l _ v e r i f i c a d o = T r u e 
                         ) 
                         d b . s e s s i o n . a d d ( n e w _ a d m i n ) 
                         d b . s e s s i o n . c o m m i t ( ) 
                         r e t u r n   ' < h 1 > S U C E S S O ! < / h 1 > < h 2 > S e u   u s u a r i o   m e s t r e   ( m a c s s u e l u s a @ g m a i l . c o m )   f o i   c r i a d o   n o   s e r v i d o r !   P o d e   t e n t a r   f a z e r   o   L o g i n   a g o r a ! < / h 2 > ' ,   2 0 0 
                 e x c e p t   E x c e p t i o n   a s   e : 
                         r e t u r n   f ' E r r o :   { s t r ( e ) } ' ,   5 0 0 
         e l s e : 
                 u s e r . i s _ a d m i n   =   T r u e 
                 u s e r . e m a i l _ v e r i f i c a d o   =   T r u e 
                 d b . s e s s i o n . c o m m i t ( ) 
                 r e t u r n   ' < h 1 > S U C E S S O ! < / h 1 > < h 2 > O   u s u a r i o   j a   e x i s t i a   e   f o i   p r o m o v i d o   a   a d m i n i s t r a d o r !   P o d e   l o g a r ! < / h 2 > ' ,   2 0 0 
  
 