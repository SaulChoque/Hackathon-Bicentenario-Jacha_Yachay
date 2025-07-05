from flask import Blueprint, request, jsonify, send_from_directory, current_app
import os
import zipfile
import json
import tempfile
import shutil
from datetime import datetime
from models.database import db  # Si db está definido en models/database.py# Asegúrate de que la ruta sea correcta según tu proyecto

content_bp = Blueprint('content', __name__)

# Importación diferida para evitar circularidad
def get_document_model():
    from routes.document import Documento
    return Documento

@content_bp.route('/subir', methods=['POST'])
def subir_contenido():
    Documento = get_document_model()  # Obtiene el modelo cuando se necesita

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
        
        # Validar extensión del archivo
        allowed_extensions = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'jacha'}
        if '.' in archivo.filename:
            extension = archivo.filename.rsplit('.', 1)[1].lower()
            if extension not in allowed_extensions:
                return jsonify({
                    'status': 'error',
                    'code': 400,
                    'message': 'Tipo de archivo no permitido'
                }), 400
        
        # Procesamiento de archivos .jacha
        if archivo.filename.lower().endswith('.jacha'):
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = os.path.join(temp_dir, archivo.filename)
                archivo.save(temp_path)
                
                try:
                    with zipfile.ZipFile(temp_path, 'r') as zip_ref:
                        # Buscar archivo JSON
                        json_files = [f for f in zip_ref.namelist() 
                                    if f.lower().endswith('.json') and not f.startswith('__MACOSX/')]
                        
                        if not json_files:
                            return jsonify({
                                'status': 'error',
                                'code': 400,
                                'message': 'No se encontró archivo JSON en el .jacha'
                            }), 400
                        
                        json_file_path = next(f for f in json_files if not f.startswith('__MACOSX/'))
                        
                        with zip_ref.open(json_file_path) as json_file:
                            try:
                                datos = json.load(json_file)
                            except json.JSONDecodeError:
                                return jsonify({
                                    'status': 'error',
                                    'code': 400,
                                    'message': 'El archivo JSON está mal formado'
                                }), 400
                            
                            # Validar estructura del JSON
                            if 'document' not in datos:
                                return jsonify({
                                    'status': 'error',
                                    'code': 400,
                                    'message': 'El JSON no contiene la estructura esperada (falta "document")'
                                }), 400
                            
                            doc_data = datos['document']
                            try:
                                # Crear nuevo documento
                                nuevo_documento = Documento(
                                    titulo=doc_data.get('title', 'Sin título'),
                                    autor=doc_data.get('authorId', 'Anónimo'),
                                    fecha=datetime.strptime(doc_data['createdAt'], '%Y-%m-%dT%H:%M:%S.%f') 
                                    if 'createdAt' in doc_data else None
                                )
                                
                                db.session.add(nuevo_documento)
                                db.session.commit()
                                
                                # Guardar el archivo .jacha con referencia al ID
                                final_filename = f"doc_{nuevo_documento.id_articulo}.jacha"
                                final_path = os.path.join(upload_dir, final_filename)
                                shutil.copy(temp_path, final_path)
                                
                                return jsonify({
                                    'status': 'success',
                                    'code': 201,
                                    'message': 'Documento .jacha procesado correctamente',
                                    'document_id': nuevo_documento.id_articulo,
                                    'metadata': {
                                        'title': doc_data.get('title'),
                                        'author': doc_data.get('authorId'),
                                        'created': doc_data.get('createdAt')
                                    },
                                    'file_path': final_path
                                }), 201
                                
                            except ValueError as e:
                                db.session.rollback()
                                return jsonify({
                                    'status': 'error',
                                    'code': 400,
                                    'message': f'Error de formato en fecha: {str(e)}'
                                }), 400
                            except Exception as e:
                                db.session.rollback()
                                return jsonify({
                                    'status': 'error',
                                    'code': 500,
                                    'message': f'Error al guardar documento: {str(e)}'
                                }), 500
                
                except zipfile.BadZipFile:
                    return jsonify({
                        'status': 'error',
                        'code': 400,
                        'message': 'El archivo .jacha no es un archivo ZIP válido'
                    }), 400
                except Exception as e:
                    return jsonify({
                        'status': 'error',
                        'code': 500,
                        'message': f'Error al procesar archivo .jacha: {str(e)}'
                    }), 500
        
        # Para otros tipos de archivo
        else:
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

@content_bp.app_errorhandler(404)
def not_found_error(error):
    return jsonify({
        'status': 'error',
        'code': 404,
        'message': 'Endpoint no encontrado. Rutas disponibles: /subir (POST), /descargar/<nombre_archivo> (GET)'
    }), 404