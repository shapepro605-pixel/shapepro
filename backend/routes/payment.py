from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.user import User
from models.payment import SubscriptionPlan, PromoCode
from database import db
from services.i18n import t

payment_bp = Blueprint('payment', __name__)

@payment_bp.route('/api/payment/plans', methods=['GET'])
def get_public_plans():
    # TEST ENVIRONMENT: Hardcode plans to always show options
    plans = [
        {'code': 'mensal', 'name': 'ShapePro Mensal', 'duration_months': 1, 'price': 29.90},
        {'code': 'anual', 'name': 'ShapePro Anual', 'duration_months': 12, 'price': 199.90}
    ]
    return jsonify({'success': True, 'plans': plans}), 200

@payment_bp.route('/api/payment/checkout', methods=['POST'])
@jwt_required()
def checkout():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    data = request.get_json()
    plan_code = data.get('plan_code', 'premium')

    # TEST ENVIRONMENT: Always simulate successful payment
    user.plano_assinatura = plan_code
    user.assinatura_ativa = True
    
    db.session.commit()
    return jsonify({
        'success': True, 
        'message': t('subscription_activated') if 'subscription_activated' in dir(t) else 'Assinatura Ativada!',
        'user': user.to_dict()
    }), 200

@payment_bp.route('/api/payment/verify', methods=['POST'])
@jwt_required()
def verify_purchase():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    data = request.get_json()
    product_id = data.get('product_id')
    is_test = data.get('is_test', False)

    # ── MOCK/TEST LOGIC ──
    # If is_test is True, we skip external verification and grant access immediately.
    # This is useful for internal testing or manual GIFTS.
    if is_test:
        if product_id == 'shapepro_anual':
            user.plano_assinatura = 'anual'
        else:
            user.plano_assinatura = 'mensal'
            
        user.assinatura_ativa = True
        db.session.commit()
        return jsonify({
            'success': True,
            'message': 'Simulação de compra bem-sucedida!',
            'user': user.to_dict()
        }), 200

    # ── REAL GOOGLE PLAY LOGIC (FUTURE) ──
    # server_verification_data = data.get('server_verification_data')
    # ... verification logic here ...

    # Fallback status for non-test requests during dev
    user.assinatura_ativa = True
    user.plano_assinatura = 'mensal'
    db.session.commit()

    return jsonify({
        'success': True,
        'user': user.to_dict()
    }), 200

@payment_bp.route('/api/payment/register-card', methods=['POST'])
@jwt_required()
def register_card():
    """Simulates registering a card to unlock full 3-day trial."""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    user.cartao_cadastrado = True
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Cartão cadastrado! Agora você tem 3 dias de acesso total grátis.',
        'user': user.to_dict()
    }), 200

@payment_bp.route('/api/payment/apply-coupon', methods=['POST'])
@jwt_required()
def apply_coupon():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    data = request.get_json()
    code = data.get('code', '').upper()
    
    promo = PromoCode.query.filter_by(code=code).first()
    if not promo or not promo.is_valid():
        return jsonify({'success': False, 'error': 'Cupom inválido ou expirado.'}), 400

    # Apply benefit
    if promo.is_free:
        user.assinatura_ativa = True
        user.plano_assinatura = 'anual' # Or special VIP plan
    
    promo.current_uses += 1
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Cupom aplicado com sucesso!',
        'user': user.to_dict()
    }), 200
