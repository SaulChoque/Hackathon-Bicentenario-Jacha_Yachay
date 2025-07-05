from flask import Flask, jsonify
from flask_cors import CORS
from models.database import db
from routes.users import users_bp
from routes.content import content_bp
from routes.tests import tests_bp
from routes.document import document_bp
from routes.article_block import article_block_bp
from routes.preguntas import preguntas_bp
from routes.sincronizacion import sincronizacion_bp
app = Flask(__name__)
app.config.from_pyfile('config.py')
CORS(app)

# Registrar blueprints
app.register_blueprint(users_bp, url_prefix='/api/users')
app.register_blueprint(content_bp, url_prefix='/api/content')
app.register_blueprint(tests_bp, url_prefix='/api/tests')
app.register_blueprint(document_bp, url_prefix='/api/documentos')
app.register_blueprint(article_block_bp, url_prefix='/api/bloques')
app.register_blueprint(preguntas_bp, url_prefix='/api/preguntas')
app.register_blueprint(sincronizacion_bp, url_prefix='/api/sincronizacion')
db.init_app(app)

# Manejador global de errores 404
@app.errorhandler(404)
def not_found_error(error):
    return jsonify({
        'status': 'error',
        'code': 404,
        'message': 'Ruta no encontrada',
        'available_routes': {
            'users': '/api/users',
            'content': '/api/content',
            'tests': '/api/tests'
        }
    }), 404

# Manejador global de errores 500
@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'status': 'error',
        'code': 500,
        'message': 'Error interno del servidor',
        'details': str(error) if app.debug else None
    }), 500

# Manejador global para otros errores comunes
@app.errorhandler(400)
def bad_request_error(error):
    return jsonify({
        'status': 'error',
        'code': 400,
        'message': 'Solicitud incorrecta',
        'details': str(error.description) if error.description else None
    }), 400

if __name__ == '__main__':
    with app.app_context():
        # Crear directorio de uploads si no existe
        upload_dir = app.config['UPLOAD_FOLDER']
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Crear tablas de la base de datos
        db.create_all()
    
    app.run(host='0.0.0.0', port=5000, debug=True)