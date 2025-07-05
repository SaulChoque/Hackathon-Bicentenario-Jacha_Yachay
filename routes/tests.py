from flask import Blueprint, request, jsonify
from models.database import db

tests_bp = Blueprint('tests', __name__)

class TestResultado(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer)
    test_id = db.Column(db.String(100))
    puntaje = db.Column(db.Integer)

@tests_bp.route('/guardar', methods=['POST'])
def guardar_resultado():
    data = request.json
    resultado = TestResultado(
        user_id=data['user_id'],
        test_id=data['test_id'],
        puntaje=data['puntaje']
    )
    db.session.add(resultado)

    # Aumentar racha
    user = db.session.get(db.Model.metadata.tables['user'], data['user_id'])
    if user:
        user.racha += 1

    db.session.commit()
    return jsonify({"message": "Resultado guardado y racha aumentada"})
