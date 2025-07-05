from flask import Blueprint, request, jsonify
from datetime import datetime
import hashlib
import os
from models.database import db

sincronizacion_bp = Blueprint('sincronizacion', __name__)

# Importar los modelos desde las routes
from routes.document import Documento
from routes.article_block import ArticuloBloque
from routes.preguntas import Pregunta

## Helper Functions ##

def calcular_hash_archivo(ruta):
    """Calcula hash SHA-256 de un archivo para verificar integridad"""
    hasher = hashlib.sha256()
    with open(ruta, 'rb') as f:
        for bloque in iter(lambda: f.read(4096), b''):
            hasher.update(bloque)
    return hasher.hexdigest()

def generar_paquete_sincronizacion(ultima_sincronizacion=None):
    """Genera un paquete con todos los contenidos nuevos"""
    paquete = {
        'documentos': [],
        'bloques': [],
        'preguntas': [],
        'archivos': [],
        'metadata': {
            'fecha_generacion': datetime.utcnow().isoformat(),
            'version': '1.0'
        }
    }
    
    try:
        # Obtener documentos modificados
        query = Documento.query
        if ultima_sincronizacion:
            query = query.filter(Documento.fecha_actualizacion > ultima_sincronizacion)
        
        # Convertir documentos a diccionario
        documentos = query.all()
        for doc in documentos:
            doc_dict = {
                'id_articulo': doc.id_articulo,
                'titulo': doc.titulo,
                'autor': doc.autor,
                'fecha': doc.fecha.isoformat() if doc.fecha else None,
                'fecha_actualizacion': doc.fecha_actualizacion.isoformat() if hasattr(doc, 'fecha_actualizacion') else None
            }
            paquete['documentos'].append(doc_dict)
        
        # Obtener bloques modificados
        query = ArticuloBloque.query
        if ultima_sincronizacion:
            query = query.filter(ArticuloBloque.fecha_actualizacion > ultima_sincronizacion)
        
        bloques = query.all()
        for bloque in bloques:
            bloque_dict = {
                'id_articulos_bloques': bloque.id_articulos_bloques,
                'id_documento': bloque.id_documento,
                'tipo': bloque.tipo,
                'contenido': bloque.contenido,
                'orden_bloque': bloque.orden_bloque,
                'fecha_actualizacion': bloque.fecha_actualizacion.isoformat() if hasattr(bloque, 'fecha_actualizacion') else None
            }
            paquete['bloques'].append(bloque_dict)
        
        # Obtener preguntas modificadas
        query = Pregunta.query
        if ultima_sincronizacion:
            query = query.filter(Pregunta.fecha_actualizacion > ultima_sincronizacion)
        
        preguntas = query.all()
        for pregunta in preguntas:
            pregunta_dict = {
                'id_pregunta': pregunta.id_pregunta,
                'id_articulos_bloques': pregunta.id_articulos_bloques,
                'id_documento': pregunta.id_documento,
                'tipo': pregunta.tipo,
                'contenido': pregunta.contenido,
                'respuesta_correcta': pregunta.respuesta_correcta,
                'fecha_actualizacion': pregunta.fecha_actualizacion.isoformat() if hasattr(pregunta, 'fecha_actualizacion') else None
            }
            paquete['preguntas'].append(pregunta_dict)
        
        return paquete
    
    except Exception as e:
        print(f"Error generando paquete: {str(e)}")
        raise

## Endpoints ##

@sincronizacion_bp.route('/estado', methods=['GET'])
def obtener_estado_sincronizacion():
    """Devuelve metadatos sobre el estado del servidor"""
    try:
        # Obtener fechas de última actualización
        ultimo_doc = Documento.query.order_by(Documento.fecha_actualizacion.desc()).first() \
            if hasattr(Documento, 'fecha_actualizacion') else None
        ultimo_bloque = ArticuloBloque.query.order_by(ArticuloBloque.fecha_actualizacion.desc()).first() \
            if hasattr(ArticuloBloque, 'fecha_actualizacion') else None
        ultima_preg = Pregunta.query.order_by(Pregunta.fecha_actualizacion.desc()).first() \
            if hasattr(Pregunta, 'fecha_actualizacion') else None
        
        # Determinar la fecha más reciente
        fechas = []
        if ultimo_doc and hasattr(ultimo_doc, 'fecha_actualizacion'):
            fechas.append(ultimo_doc.fecha_actualizacion)
        if ultimo_bloque and hasattr(ultimo_bloque, 'fecha_actualizacion'):
            fechas.append(ultimo_bloque.fecha_actualizacion)
        if ultima_preg and hasattr(ultima_preg, 'fecha_actualizacion'):
            fechas.append(ultima_preg.fecha_actualizacion)
        
        ultima_actualizacion = max(fechas) if fechas else datetime.min
        
        return jsonify({
            'ultima_actualizacion': ultima_actualizacion.isoformat(),
            'total_documentos': Documento.query.count(),
            'total_bloques': ArticuloBloque.query.count(),
            'total_preguntas': Pregunta.query.count(),
            'status': 'success'
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@sincronizacion_bp.route('/descargar', methods=['POST'])
def descargar_contenido():
    """Endpoint principal para sincronización"""
    try:
        datos_cliente = request.json
        ultima_sinc = datetime.fromisoformat(datos_cliente.get('ultima_sincronizacion')) \
            if datos_cliente.get('ultima_sincronizacion') else None
        
        # Generar paquete de sincronización
        paquete = generar_paquete_sincronizacion(ultima_sinc)
        
        # Opcional: incluir archivos estáticos
        if datos_cliente.get('incluir_archivos', False):
            from app import app
            contenido_dir = os.path.join(app.static_folder, 'contenidos')
            if os.path.exists(contenido_dir):
                paquete['archivos'] = [{
                    'nombre': f,
                    'hash': calcular_hash_archivo(os.path.join(contenido_dir, f)),
                    'tamanio': os.path.getsize(os.path.join(contenido_dir, f))
                } for f in os.listdir(contenido_dir) if os.path.isfile(os.path.join(contenido_dir, f))]
        
        return jsonify({
            'status': 'success',
            'data': paquete,
            'server_time': datetime.utcnow().isoformat()
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@sincronizacion_bp.route('/subir-actividad', methods=['POST'])
def subir_actividad():
    """Recibe actividad generada offline"""
    try:
        datos_actividad = request.json
        
        # Validar datos mínimos
        if not datos_actividad or not isinstance(datos_actividad, list):
            return jsonify({
                'status': 'error',
                'message': 'Datos de actividad inválidos'
            }), 400
        
        # Procesar cada registro de actividad
        for registro in datos_actividad:
            # Aquí implementarías la lógica para guardar cada actividad
            # Ejemplo: progreso, respuestas a preguntas, etc.
            pass
        
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': f'{len(datos_actividad)} registros procesados'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@sincronizacion_bp.route('/descargar-archivo/<nombre_archivo>', methods=['GET'])
def descargar_archivo(nombre_archivo):
    """Descarga un archivo estático individual"""
    from flask import send_from_directory
    from app import app
    
    try:
        # Validar nombre de archivo por seguridad
        if not nombre_archivo or '/' in nombre_archivo or '\\' in nombre_archivo:
            raise ValueError("Nombre de archivo inválido")
        
        return send_from_directory(
            os.path.join(app.static_folder, 'contenidos'),
            nombre_archivo,
            as_attachment=True
        )
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 404