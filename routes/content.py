from flask import Blueprint, request, jsonify, send_from_directory, current_app
import os

content_bp = Blueprint('content', __name__)

@content_bp.route('/subir', methods=['POST'])
def subir_contenido():
    # Verificar que la ruta existe (para evitar 404)
    if request.path != '/api/content/subir':
        return jsonify({
            'status': 'error',
            'code': 404,
            'message': 'Ruta no encontrada. Use /api/content/subir para subir archivos'
        }), 404

    # Verificar que se envió un archivo
    if 'archivo' not in request.files:
        return jsonify({
            'status': 'error',
            'code': 400,
            'message': 'No se recibió ningún archivo. Asegúrese de usar el campo "archivo" en form-data'
        }), 400
    
    archivo = request.files['archivo']
    
    if archivo.filename == '':
        return jsonify({
            'status': 'error',
            'code': 400,
            'message': 'El nombre del archivo está vacío'
        }), 400
    
    try:
        # Obtener ruta de configuración
        upload_dir = current_app.config['UPLOAD_FOLDER']
        
        # Crear directorio si no existe
        os.makedirs(upload_dir, exist_ok=True)
        
        # Validar extensión del archivo (opcional)
        allowed_extensions = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif','jacha'}
        if '.' in archivo.filename:
            extension = archivo.filename.rsplit('.', 1)[1].lower()
            if extension not in allowed_extensions:
                return jsonify({
                    'status': 'error',
                    'code': 400,
                    'message': 'Tipo de archivo no permitido'
                }), 400
        
        # Guardar archivo
        filepath = os.path.join(upload_dir, archivo.filename)
        archivo.save(filepath)
        
        return jsonify({
            'status': 'success',
            'code': 200,
            'message': 'Archivo subido correctamente',
            'filename': archivo.filename,
            'path': filepath
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'code': 500,
            'message': f'Error interno al subir archivo: {str(e)}'
        }), 500

# Manejador global de errores 404 para este blueprint
@content_bp.app_errorhandler(404)
def not_found_error(error):
    return jsonify({
        'status': 'error',
        'code': 404,
        'message': 'Endpoint no encontrado. Rutas disponibles: /subir (POST), /descargar/<nombre_archivo> (GET)'
    }), 404