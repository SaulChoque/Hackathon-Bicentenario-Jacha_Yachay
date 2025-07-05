from flask import Blueprint, request, jsonify
from models.database import db

article_block_bp = Blueprint('article_block', __name__)

class ArticuloBloque(db.Model):
    __tablename__ = 'articulo_bloques'
    
    id_articulos_bloques = db.Column(db.Integer, primary_key=True)
    id_documento = db.Column(db.Integer, db.ForeignKey('documento.id_articulo'), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)  # 'texto', 'imagen', 'codigo', etc.
    contenido = db.Column(db.Text, nullable=False)
    orden_bloque = db.Column(db.Integer, nullable=False)

    # Relación (opcional pero útil)
    documento = db.relationship('Documento', backref='bloques')

@article_block_bp.route('/crear', methods=['POST'])
def crear_bloque():
    data = request.get_json()

    # Validaciones básicas
    required_fields = ['id_documento', 'tipo', 'contenido', 'orden_bloque']
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"El campo {field} es obligatorio"}), 400

    try:
        # Crear nuevo bloque
        nuevo_bloque = ArticuloBloque(
            id_documento=data['id_documento'],
            tipo=data['tipo'],
            contenido=data['contenido'],
            orden_bloque=data['orden_bloque']
        )

        db.session.add(nuevo_bloque)
        db.session.commit()

        return jsonify({
            "id_articulos_bloques": nuevo_bloque.id_articulos_bloques,
            "id_documento": nuevo_bloque.id_documento,
            "tipo": nuevo_bloque.tipo,
            "contenido": nuevo_bloque.contenido,
            "orden_bloque": nuevo_bloque.orden_bloque
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al crear bloque: {str(e)}"}), 500

@article_block_bp.route('/documento/<int:id_documento>', methods=['GET'])
def obtener_bloques_por_documento(id_documento):
    bloques = ArticuloBloque.query.filter_by(id_documento=id_documento)\
                                 .order_by(ArticuloBloque.orden_bloque)\
                                 .all()
    
    return jsonify([{
        "id_articulos_bloques": bloque.id_articulos_bloques,
        "id_documento": bloque.id_documento,
        "tipo": bloque.tipo,
        "contenido": bloque.contenido,
        "orden_bloque": bloque.orden_bloque
    } for bloque in bloques])

@article_block_bp.route('/<int:id_bloque>', methods=['GET'])
def obtener_bloque(id_bloque):
    bloque = ArticuloBloque.query.get_or_404(id_bloque)
    
    return jsonify({
        "id_articulos_bloques": bloque.id_articulos_bloques,
        "id_documento": bloque.id_documento,
        "tipo": bloque.tipo,
        "contenido": bloque.contenido,
        "orden_bloque": bloque.orden_bloque
    })

@article_block_bp.route('/<int:id_bloque>', methods=['PUT'])
def actualizar_bloque(id_bloque):
    bloque = ArticuloBloque.query.get_or_404(id_bloque)
    data = request.get_json()

    try:
        if 'tipo' in data:
            bloque.tipo = data['tipo']
        if 'contenido' in data:
            bloque.contenido = data['contenido']
        if 'orden_bloque' in data:
            bloque.orden_bloque = data['orden_bloque']

        db.session.commit()

        return jsonify({
            "id_articulos_bloques": bloque.id_articulos_bloques,
            "id_documento": bloque.id_documento,
            "tipo": bloque.tipo,
            "contenido": bloque.contenido,
            "orden_bloque": bloque.orden_bloque
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al actualizar bloque: {str(e)}"}), 500

@article_block_bp.route('/<int:id_bloque>', methods=['DELETE'])
def eliminar_bloque(id_bloque):
    bloque = ArticuloBloque.query.get_or_404(id_bloque)
    
    try:
        db.session.delete(bloque)
        db.session.commit()
        return jsonify({"mensaje": "Bloque eliminado correctamente"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al eliminar bloque: {str(e)}"}), 500

@article_block_bp.route('/reordenar/<int:id_documento>', methods=['POST'])
def reordenar_bloques(id_documento):
    data = request.get_json()
    
    if not isinstance(data.get('nuevo_orden'), list):
        return jsonify({"error": "Se requiere una lista de IDs en 'nuevo_orden'"}), 400

    try:
        # Obtener todos los bloques del documento
        bloques = ArticuloBloque.query.filter_by(id_documento=id_documento).all()
        
        # Crear mapeo de IDs a objetos
        bloques_por_id = {bloque.id_articulos_bloques: bloque for bloque in bloques}
        
        # Actualizar el orden
        for nuevo_orden, bloque_id in enumerate(data['nuevo_orden'], start=1):
            if bloque_id in bloques_por_id:
                bloques_por_id[bloque_id].orden_bloque = nuevo_orden

        db.session.commit()
        return jsonify({"mensaje": "Bloques reordenados correctamente"}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al reordenar bloques: {str(e)}"}), 500