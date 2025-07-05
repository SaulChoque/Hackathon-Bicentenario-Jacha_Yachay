from flask import Blueprint, request, jsonify
from models.database import db

preguntas_bp = Blueprint('preguntas', __name__)

class Pregunta(db.Model):
    __tablename__ = 'preguntas'
    
    id_pregunta = db.Column(db.Integer, primary_key=True)
    id_articulos_bloques = db.Column(db.Integer, db.ForeignKey('articulo_bloques.id_articulos_bloques'), nullable=True)
    id_documento = db.Column(db.Integer, db.ForeignKey('documento.id_articulo'), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)  # 'opcion_multiple', 'verdadero_falso', 'texto'
    contenido = db.Column(db.Text, nullable=False)
    respuesta_correcta = db.Column(db.Text, nullable=False)
    opciones = db.Column(db.JSON, nullable=True)  # Para almacenar opciones si es múltiple choice

    # Relaciones
    bloque = db.relationship('ArticuloBloque', backref='preguntas')
    documento = db.relationship('Documento', backref='preguntas')

@preguntas_bp.route('/crear', methods=['POST'])
def crear_pregunta():
    data = request.get_json()

    # Validaciones básicas
    required_fields = ['id_documento', 'tipo', 'contenido', 'respuesta_correcta']
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"El campo {field} es obligatorio"}), 400

    # Validación específica para preguntas de opción múltiple
    if data['tipo'] == 'opcion_multiple' and not data.get('opciones'):
        return jsonify({"error": "Las preguntas de opción múltiple requieren el campo 'opciones'"}), 400

    try:
        # Crear nueva pregunta
        nueva_pregunta = Pregunta(
            id_articulos_bloques=data.get('id_articulos_bloques'),
            id_documento=data['id_documento'],
            tipo=data['tipo'],
            contenido=data['contenido'],
            respuesta_correcta=data['respuesta_correcta'],
            opciones=data.get('opciones') if data['tipo'] == 'opcion_multiple' else None
        )

        db.session.add(nueva_pregunta)
        db.session.commit()

        return jsonify({
            "id_pregunta": nueva_pregunta.id_pregunta,
            "id_articulos_bloques": nueva_pregunta.id_articulos_bloques,
            "id_documento": nueva_pregunta.id_documento,
            "tipo": nueva_pregunta.tipo,
            "contenido": nueva_pregunta.contenido,
            "respuesta_correcta": nueva_pregunta.respuesta_correcta,
            "opciones": nueva_pregunta.opciones
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al crear pregunta: {str(e)}"}), 500

@preguntas_bp.route('/documento/<int:id_documento>', methods=['GET'])
def obtener_preguntas_por_documento(id_documento):
    preguntas = Pregunta.query.filter_by(id_documento=id_documento).all()
    
    return jsonify([{
        "id_pregunta": pregunta.id_pregunta,
        "id_articulos_bloques": pregunta.id_articulos_bloques,
        "id_documento": pregunta.id_documento,
        "tipo": pregunta.tipo,
        "contenido": pregunta.contenido,
        "respuesta_correcta": pregunta.respuesta_correcta,
        "opciones": pregunta.opciones
    } for pregunta in preguntas])

@preguntas_bp.route('/bloque/<int:id_bloque>', methods=['GET'])
def obtener_preguntas_por_bloque(id_bloque):
    preguntas = Pregunta.query.filter_by(id_articulos_bloques=id_bloque).all()
    
    return jsonify([{
        "id_pregunta": pregunta.id_pregunta,
        "id_articulos_bloques": pregunta.id_articulos_bloques,
        "id_documento": pregunta.id_documento,
        "tipo": pregunta.tipo,
        "contenido": pregunta.contenido,
        "respuesta_correcta": pregunta.respuesta_correcta,
        "opciones": pregunta.opciones
    } for pregunta in preguntas])

@preguntas_bp.route('/<int:id_pregunta>', methods=['GET'])
def obtener_pregunta(id_pregunta):
    pregunta = Pregunta.query.get_or_404(id_pregunta)
    
    return jsonify({
        "id_pregunta": pregunta.id_pregunta,
        "id_articulos_bloques": pregunta.id_articulos_bloques,
        "id_documento": pregunta.id_documento,
        "tipo": pregunta.tipo,
        "contenido": pregunta.contenido,
        "respuesta_correcta": pregunta.respuesta_correcta,
        "opciones": pregunta.opciones
    })

@preguntas_bp.route('/<int:id_pregunta>', methods=['PUT'])
def actualizar_pregunta(id_pregunta):
    pregunta = Pregunta.query.get_or_404(id_pregunta)
    data = request.get_json()

    try:
        if 'contenido' in data:
            pregunta.contenido = data['contenido']
        if 'respuesta_correcta' in data:
            pregunta.respuesta_correcta = data['respuesta_correcta']
        if 'opciones' in data and pregunta.tipo == 'opcion_multiple':
            pregunta.opciones = data['opciones']

        db.session.commit()

        return jsonify({
            "id_pregunta": pregunta.id_pregunta,
            "id_articulos_bloques": pregunta.id_articulos_bloques,
            "id_documento": pregunta.id_documento,
            "tipo": pregunta.tipo,
            "contenido": pregunta.contenido,
            "respuesta_correcta": pregunta.respuesta_correcta,
            "opciones": pregunta.opciones
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al actualizar pregunta: {str(e)}"}), 500

@preguntas_bp.route('/<int:id_pregunta>', methods=['DELETE'])
def eliminar_pregunta(id_pregunta):
    pregunta = Pregunta.query.get_or_404(id_pregunta)
    
    try:
        db.session.delete(pregunta)
        db.session.commit()
        return jsonify({"mensaje": "Pregunta eliminada correctamente"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al eliminar pregunta: {str(e)}"}), 500

@preguntas_bp.route('/evaluar/<int:id_pregunta>', methods=['POST'])
def evaluar_respuesta(id_pregunta):
    pregunta = Pregunta.query.get_or_404(id_pregunta)
    data = request.get_json()

    if 'respuesta_usuario' not in data:
        return jsonify({"error": "Se requiere el campo 'respuesta_usuario'"}), 400

    es_correcta = False
    respuesta_usuario = str(data['respuesta_usuario']).strip().lower()
    respuesta_correcta = str(pregunta.respuesta_correcta).strip().lower()

    # Lógica de evaluación según tipo de pregunta
    if pregunta.tipo == 'opcion_multiple':
        es_correcta = respuesta_usuario == respuesta_correcta
    elif pregunta.tipo == 'verdadero_falso':
        es_correcta = respuesta_usuario in ['verdadero', 'true', '1'] and respuesta_correcta in ['verdadero', 'true', '1'] or \
                      respuesta_usuario in ['falso', 'false', '0'] and respuesta_correcta in ['falso', 'false', '0']
    else:  # Tipo texto (comparación exacta)
        es_correcta = respuesta_usuario == respuesta_correcta

    return jsonify({
        "es_correcta": es_correcta,
        "respuesta_correcta": pregunta.respuesta_correcta,
        "feedback": "¡Respuesta correcta!" if es_correcta else "Respuesta incorrecta"
    })