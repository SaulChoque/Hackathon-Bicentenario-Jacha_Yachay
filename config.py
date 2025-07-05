import os
from pathlib import Path

# Directorio base
BASE_DIR = Path(__file__).parent.resolve()

# Configuración de la base de datos
SQLALCHEMY_DATABASE_URI = f'sqlite:///{BASE_DIR / "educa.db"}'
SQLALCHEMY_TRACK_MODIFICATIONS = False

# Configuración para subida de archivos
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB máximo
UPLOAD_FOLDER = BASE_DIR / 'static' / 'contenidos'