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

    scan = BodyScan(
        user_id=user_id,
        type=scan_type,
        image_url=data['image_url']
    )

    db.session.add(scan)
    db.session.commit()

    return jsonify({'message': 'Foto registrada!', 'scan': scan.to_dict()}), 201

@body_scan_bp.route('', methods=['GET'])
@jwt_required()
def get_body_scans():
    """Get history of body scans for the current user."""
    user_id = get_jwt_identity()
    scans = BodyScan.query.filter_by(user_id=user_id).order_by(BodyScan.created_at.desc()).all()
    
    return jsonify({
        'scans': [s.to_dict() for s in scans]
    }), 200
