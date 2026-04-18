from flask import Blueprint, request, jsonify
from database import db
from models.food_price import FoodPrice
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.user import User

food_prices_bp = Blueprint('food_prices', __name__)

@food_prices_bp.route('/api/food-prices/report', methods=['POST'])
@jwt_required()
def report_price():
    user_id = get_jwt_identity()
    current_user = User.query.get(user_id)
    data = request.get_json()
    alimento = data.get('alimento')
    preco = data.get('preco')
    cidade = data.get('cidade')
    pais = data.get('pais', current_user.pais or 'BR')
    moeda = data.get('moeda', current_user.moeda or 'BRL')

    if not alimento or preco is None:
        return jsonify({"success": False, "error": "Alimento e preço são obrigatórios"}), 400

    # Adiciona ou atualiza preço informado pelo usuário
    new_price = FoodPrice(
        alimento=alimento,
        preco=preco,
        cidade=cidade,
        pais=pais,
        moeda=moeda,
        origem='user'
    )
    db.session.add(new_price)
    db.session.commit()

    return jsonify({"success": True, "message": "Preço registrado com sucesso"}), 201

@food_prices_bp.route('/api/food-prices/search', methods=['GET'])
@jwt_required()
def get_prices():
    user_id = get_jwt_identity()
    current_user = User.query.get(user_id)
    alimentos = request.args.getlist('alimentos')
    cidade = request.args.get('cidade', current_user.cidade)
    pais = request.args.get('pais', current_user.pais or 'BR')

    if not alimentos:
        return jsonify({"success": False, "error": "Lista de alimentos vazia"}), 400

    results = {}
    for item in alimentos:
        # Busca o preço mais recente para o alimento naquela cidade/país
        price_record = FoodPrice.query.filter_by(alimento=item, cidade=cidade, pais=pais)\
            .order_by(FoodPrice.data_atualizacao.desc()).first()
        
        if not price_record:
            # Fallback para o país se não achar na cidade
            price_record = FoodPrice.query.filter_by(alimento=item, pais=pais)\
                .order_by(FoodPrice.data_atualizacao.desc()).first()

        if price_record:
            results[item] = {
                "preco": price_record.preco,
                "moeda": price_record.moeda,
                "data": price_record.data_atualizacao.isoformat()
            }
        else:
            # Se não achar nada, retorna um valor default baseado em heurística simples (simulada)
            results[item] = {
                "preco": 10.0, # Default genérico
                "moeda": current_user.moeda or 'BRL',
                "data": None
            }

    return jsonify({"success": True, "precos": results})
