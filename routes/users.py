from flask import Blueprint, request, jsonify
from models.database import db
from sqlalchemy import Column, Integer, String
from werkzeug.security import generate_password_hash  # Para hashear contraseñas

users_bp = Blueprint('users', __name__)

class User(db.Model):
    __tablename__ = 'usuario'
    
    id_usuario = db.Column(db.Integer, primary_key=True)
    carnet = db.Column(db.String(20), unique=True, nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    apellido = db.Column(db.String(100), nullable=False)
    contraseña = db.Column(db.String(200), nullable=False)  # Almacenará el hash
    username = db.Column(db.String(50), unique=True, nullable=False)
    correo = db.Column(db.String(100), unique=True, nullable=False)
    racha = db.Column(db.Integer, default=0)  # Manteniendo este campo adicional

@users_bp.route('/registrar', methods=['POST'])
def registrar_usuario():
    data = request.get_json()

    # Validaciones básicas
    required_fields = ['carnet', 'nombre', 'apellido', 'contraseña', 'username', 'correo']
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"El campo {field} es obligatorio"}), 400

    # Verificar unicidad de carnet, username y correo
    if User.query.filter_by(carnet=data['carnet']).first():
        return jsonify({"error": "El carnet ya está registrado"}), 400
    if User.query.filter_by(username=data['username']).first():
        return jsonify({"error": "El nombre de usuario ya existe"}), 400
    if User.query.filter_by(correo=data['correo']).first():
        return jsonify({"error": "El correo ya está registrado"}), 400

    # Hashear la contraseña antes de almacenarla
    hashed_password = generate_password_hash(data['contraseña'])

    user = User(
        carnet=data['carnet'],
        nombre=data['nombre'],
        apellido=data['apellido'],
        contraseña=hashed_password,
        username=data['username'],
        correo=data['correo']
    )

    db.session.add(user)
    db.session.commit()

    return jsonify({
        "id_usuario": user.id_usuario,
        "carnet": user.carnet,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "username": user.username,
        "correo": user.correo,
        "racha": user.racha
    }), 201

@users_bp.route('/', methods=['GET'])
def obtener_usuarios():
    users = User.query.all()
    return jsonify([
        {
            "id_usuario": u.id_usuario,
            "carnet": u.carnet,
            "nombre": u.nombre,
            "apellido": u.apellido,
            "username": u.username,
            "correo": u.correo,
            "racha": u.racha
        } for u in users
    ])

@users_bp.route('/<int:id_usuario>', methods=['GET'])
def obtener_usuario(id_usuario):
    user = User.query.get_or_404(id_usuario)
    return jsonify({
        "id_usuario": user.id_usuario,
        "carnet": user.carnet,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "username": user.username,
        "correo": user.correo,
        "racha": user.racha
    })