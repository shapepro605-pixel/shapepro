from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import db
from models.user import BodyScan, User

body_scan_bp = Blueprint('body_scan', __name__, url_prefix='/api/body-scan')

@body_scan_bp.route('', methods=['POST'])
@jwt_required()
def save_body_scan():
    """Save body scan metadata."""
    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'type' not in data or 'image_url' not in data:
        return jsonify({'error': 'Dados incompletos'}), 400

    scan_type = data['type']
    if scan_type not in ['front', 'side', 'back']:
        return jsonify({'error': 'Tipo de pose inválido'}), 400

    try:
        # Cast to int for DB compatibility and safety
        u_id = int(user_id)
        
        scan = BodyScan(
            user_id=u_id,
            type=scan_type,
            image_url=data['image_url'],
            metrics=data.get('metrics')
        )

        db.session.add(scan)
        
        # --- AUTO-SYNC with BodyMetric history ---
        # If we have metrics, we also save them to the official tracking table
        metrics = data.get('metrics')
        if metrics:
            from models.user import BodyMetric
            # Map common AI metric keys to BodyMetric columns
            new_metric = BodyMetric(
                user_id=u_id,
                peito=metrics.get('chest'),
                cintura=metrics.get('waist'),
                braco_esq=metrics.get('left_arm'),
                braco_dir=metrics.get('right_arm'),
                coxa_esq=metrics.get('left_thigh'),
                coxa_dir=metrics.get('right_thigh'),
            )
            db.session.add(new_metric)
            print(f">>> SYNC: Medições da IA sincronizadas com BodyMetric para usuário {u_id}")

        db.session.commit()
        print(f">>> SCORES SALVOS COM SUCESSO PARA USUÁRIO {u_id}")
        return jsonify({'message': 'Foto e medidas registradas!', 'scan': scan.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        import traceback
        error_details = traceback.format_exc()
        print(f">>> ERRO CRÍTICO AO SALVAR NO BANCO:\n{error_details}")
        return jsonify({
            'error': 'Erro ao salvar no banco de dados', 
            'details': str(e),
            'suggestion': 'Verifique se a migração de banco foi executada.'
        }), 500

@body_scan_bp.route('', methods=['GET'])
@jwt_required()
def get_body_scans():
    """Get history of body scans for the current user."""
    user_id = get_jwt_identity()
    scans = BodyScan.query.filter_by(user_id=user_id).order_by(BodyScan.created_at.desc()).all()
    
    return jsonify({
        'scans': [s.to_dict() for s in scans]
    }), 200
    
@body_scan_bp.route('/<int:scan_id>', methods=['DELETE'])
@body_scan_bp.route('/<int:scan_id>/', methods=['DELETE'])
@jwt_required()
def delete_body_scan(scan_id):
    """Delete a specific body scan."""
    user_id = get_jwt_identity()
    print(f">>> RECEBIDO PEDIDO DE EXCLUSÃO: SCAN {scan_id} PELO USUÁRIO {user_id}")
    
    scan = BodyScan.query.filter_by(id=scan_id, user_id=user_id).first()
    
    if not scan:
        print(f">>> REGISTRO {scan_id} NÃO ENCONTRADO PARA O USUÁRIO {user_id}")
        return jsonify({'error': 'Registro não encontrado'}), 404
        
    try:
        db.session.delete(scan)
        db.session.commit()
        print(f">>> REGISTRO {scan_id} EXCLUÍDO COM SUCESSO DO BANCO")
        return jsonify({'message': 'Registro excluído com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        print(f">>> ERRO AO EXCLUIR REGISTRO {scan_id}: {str(e)}")
        return jsonify({'error': 'Erro ao processar exclusão', 'details': str(e)}), 500
