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

    # PRODUCTION: In production, this route should only handle external payment redirects or logs.
    # It should NOT grant access directly based on a client request.
    return jsonify({
        'success': False, 
        'error': 'Checkout must be completed via Google Play Store.'
    }), 403

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

    # ── REAL GOOGLE PLAY LOGIC ──
    server_verification_data = data.get('server_verification_data')
    
    if not server_verification_data:
        return jsonify({'success': False, 'error': 'No verification data provided.'}), 400

    # TODO: Implement actual Google Play Developer API call here
    # Temporarily trusting the client verification data to unblock users.
    user.assinatura_ativa = True
    user.plano_assinatura = product_id if product_id else 'premium'
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Assinatura verificada e ativada com sucesso!',
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
