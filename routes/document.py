from flask import Blueprint, request, jsonify
from models.database import db
from datetime import datetime

document_bp = Blueprint('document', __name__)

class Documento(db.Model):
    __tablename__ = 'documento'
    
    id_articulo = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False)
    autor = db.Column(db.String(100), nullable=False)
    fecha = db.Column(db.DateTime, default=datetime.utcnow)

@document_bp.route('/crear', methods=['POST'])
def crear_documento():
    data = request.get_json()

    # Validaciones básicas
    if not data.get('titulo'):
        return jsonify({"error": "El título es obligatorio"}), 400
    if not data.get('autor'):
        return jsonify({"error": "El autor es obligatorio"}), 400

    try:
        # Crear nuevo documento
        nuevo_documento = Documento(
            titulo=data['titulo'],
            autor=data['autor'],
            fecha=datetime.strptime(data['fecha'], '%Y-%m-%d') if 'fecha' in data else None
        )

        db.session.add(nuevo_documento)
        db.session.commit()

        return jsonify({
            "id_articulo": nuevo_documento.id_articulo,
            "titulo": nuevo_documento.titulo,
            "autor": nuevo_documento.autor,
            "fecha": nuevo_documento.fecha.strftime('%Y-%m-%d') if nuevo_documento.fecha else None
        }), 201

    except ValueError as e:
        return jsonify({"error": f"Formato de fecha inválido. Use YYYY-MM-DD: {str(e)}"}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al crear documento: {str(e)}"}), 500

@document_bp.route('/', methods=['GET'])
def obtener_documentos():
    documentos = Documento.query.order_by(Documento.fecha.desc()).all()
    
    return jsonify([{
        "id_articulo": doc.id_articulo,
        "titulo": doc.titulo,
        "autor": doc.autor,
        "fecha": doc.fecha.strftime('%Y-%m-%d') if doc.fecha else None
    } for doc in documentos])

@document_bp.route('/<int:id_articulo>', methods=['GET'])
def obtener_documento(id_articulo):
    documento = Documento.query.get_or_404(id_articulo)
    
    return jsonify({
        "id_articulo": documento.id_articulo,
        "titulo": documento.titulo,
        "autor": documento.autor,
        "fecha": documento.fecha.strftime('%Y-%m-%d') if documento.fecha else None
    })

@document_bp.route('/<int:id_articulo>', methods=['PUT'])
def actualizar_documento(id_articulo):
    documento = Documento.query.get_or_404(id_articulo)
    data = request.get_json()

    try:
        if 'titulo' in data:
            documento.titulo = data['titulo']
        if 'autor' in data:
            documento.autor = data['autor']
        if 'fecha' in data:
            documento.fecha = datetime.strptime(data['fecha'], '%Y-%m-%d')

        db.session.commit()

        return jsonify({
            "id_articulo": documento.id_articulo,
            "titulo": documento.titulo,
            "autor": documento.autor,
            "fecha": documento.fecha.strftime('%Y-%m-%d') if documento.fecha else None
        })

    except ValueError as e:
        return jsonify({"error": f"Formato de fecha inválido. Use YYYY-MM-DD: {str(e)}"}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al actualizar documento: {str(e)}"}), 500

@document_bp.route('/<int:id_articulo>', methods=['DELETE'])
def eliminar_documento(id_articulo):
    documento = Documento.query.get_or_404(id_articulo)
    
    try:
        db.session.delete(documento)
        db.session.commit()
        return jsonify({"mensaje": "Documento eliminado correctamente"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al eliminar documento: {str(e)}"}), 500