import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/database_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jacha_yachay.db');
    
    return await openDatabase(
      path,
      version: 3, // Incrementamos la versión para la nueva migración
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla classes si no existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS classes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          subtitle TEXT,
          instructor TEXT NOT NULL,
          gradient_start_color TEXT NOT NULL,
          gradient_end_color TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          is_active BOOLEAN DEFAULT 1
        )
      ''');

      // Insertar datos de ejemplo de clases si la tabla está vacía
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM classes');
      if (count.first['count'] == 0) {
        await _insertClassSampleData(db);
      }
    }
    
    if (oldVersion < 3) {
      // Agregar columna class_id a la tabla documents
      await db.execute('ALTER TABLE documents ADD COLUMN class_id INTEGER');
      
      // Agregar foreign key constraint (nota: SQLite no permite ADD CONSTRAINT, 
      // pero podemos crear un índice para mejorar rendimiento)
      await db.execute('CREATE INDEX idx_documents_class_id ON documents(class_id)');
      
      // Actualizar documentos existentes para asignarlos a la primera clase
      await db.execute('UPDATE documents SET class_id = 1 WHERE class_id IS NULL');
    }
  }

  Future<void> _insertClassSampleData(Database db) async {
    // Insertar clases de ejemplo
    await db.insert('classes', {
      'title': 'Base de Datos III',
      'subtitle': 'Celia Tarquino',
      'instructor': 'Celia Tarquino',
      'gradient_start_color': '0xFF4285F4',
      'gradient_end_color': '0xFF1A73E8',
      'icon_name': 'storage',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1
    });

    await db.insert('classes', {
      'title': 'INF261 - DAT251',
      'subtitle': 'BASE DE DATOS III',
      'instructor': 'Celia Tarquino',
      'gradient_start_color': '0xFFD93D8B',
      'gradient_end_color': '0xFFB91C7C',
      'icon_name': 'bar_chart',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1
    });

    await db.insert('classes', {
      'title': 'INF-357 ROBÓTICA',
      'subtitle': 'Temporada I/2025',
      'instructor': 'Nagib Vallejos Mamani',
      'gradient_start_color': '0xFF0D7377',
      'gradient_end_color': '0xFF14A085',
      'icon_name': 'smart_toy',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1
    });

    await db.insert('classes', {
      'title': 'AUXILIATURA EST',
      'subtitle': '',
      'instructor': 'Cristian Abel',
      'gradient_start_color': '0xFFFF6B35',
      'gradient_end_color': '0xFFE55100',
      'icon_name': 'analytics',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1
    });

    await db.insert('classes', {
      'title': 'ÁLGEBRA PAR. A',
      'subtitle': 'Paralelo A',
      'instructor': 'Jonathan Orellana',
      'gradient_start_color': '0xFF1565C0',
      'gradient_end_color': '0xFF0D47A1',
      'icon_name': 'calculate',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1
    });
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Crear tabla documents
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT,  
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        title TEXT,
        class_id INTEGER,
        FOREIGN KEY(class_id) REFERENCES classes(id)
      )
    ''');

    // Crear tabla questions
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER,
        type TEXT,
        text TEXT,
        correct_answer TEXT,
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Crear tabla options
    await db.execute('''
      CREATE TABLE options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER,
        text TEXT,
        is_correct BOOLEAN,
        FOREIGN KEY(question_id) REFERENCES questions(id)
      )
    ''');

    // Crear tabla article_blocks
    await db.execute('''
      CREATE TABLE article_blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER,
        type TEXT,
        content TEXT,
        block_order INTEGER,
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Crear tabla classes
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        instructor TEXT NOT NULL,
        gradient_start_color TEXT NOT NULL,
        gradient_end_color TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT 1
      )
    ''');

    // Insertar datos de ejemplo
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insertar documento de ejemplo
    await db.insert('documents', {
      'author_id': 'instructor_001',
      'created_at': DateTime.now().toIso8601String(),
      'title': 'Trabajo Final - Desarrollo de Apps Flutter',
      'class_id': 1, // Asignar a la primera clase (Base de Datos III)
    });

    // Insertar más documentos para diferentes clases
    await db.insert('documents', {
      'author_id': 'instructor_002',
      'created_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
      'title': 'Examen Recuperatorio - Base de Datos',
      'class_id': 1, // Base de Datos III
    });

    await db.insert('documents', {
      'author_id': 'instructor_003',
      'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      'title': 'Proyecto Final - Robot Autónomo',
      'class_id': 3, // INF-357 ROBÓTICA
    });

    await db.insert('documents', {
      'author_id': 'instructor_004',
      'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      'title': 'Análisis Estadístico - Proyecto Grupal',
      'class_id': 4, // AUXILIATURA ESTADÍSTI...
    });

    await db.insert('documents', {
      'author_id': 'instructor_005',
      'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'title': 'Ejercicios de Álgebra Lineal',
      'class_id': 5, // ÁLGEBRA PARALELO A
    });

    // Insertar bloques de artículo
    await db.insert('article_blocks', {
      'document_id': 1,
      'type': 'title',
      'content': 'Trabajo Final',
      'block_order': 1
    });

    await db.insert('article_blocks', {
      'document_id': 1,
      'type': 'paragraph',
      'content': 'Cada grupo deberá desarrollar tres aplicaciones móviles usando Flutter, una para cada nivel de dificultad (básico, intermedio y avanzado), todas dentro de un mismo contexto temático.',
      'block_order': 2
    });

    await db.insert('article_blocks', {
      'document_id': 1,
      'type': 'paragraph',
      'content': 'Por ejemplo: Área TEATRO:\n• App Básico: App de Cartelera Cultural\n• App Intermedio: Organización de Evento Teatral (Grupal)\n• App Avanzado: Simulador de Reserva de Entradas',
      'block_order': 3
    });

    await db.insert('article_blocks', {
      'document_id': 1,
      'type': 'paragraph',
      'content': 'Las aplicaciones deberán funcionar sin conexión a internet y no usar bases de datos ni servicios externos. Se enfocarán en el diseño de interfaces, la navegación entre pantallas y la lógica interna del manejo de datos en memoria.',
      'block_order': 4
    });

    // Agregar bloques para documento 2 (Examen Recuperatorio)
    await db.insert('article_blocks', {
      'document_id': 2,
      'type': 'title',
      'content': 'Examen Recuperatorio - Base de Datos',
      'block_order': 1
    });

    await db.insert('article_blocks', {
      'document_id': 2,
      'type': 'paragraph',
      'content': 'El examen recuperatorio abarcará todos los temas vistos durante el semestre, incluyendo normalización, consultas SQL avanzadas, y diseño de bases de datos.',
      'block_order': 2
    });

    // Agregar bloques para documento 3 (Proyecto Robótica)
    await db.insert('article_blocks', {
      'document_id': 3,
      'type': 'title',
      'content': 'Proyecto Final - Robot Autónomo',
      'block_order': 1
    });

    await db.insert('article_blocks', {
      'document_id': 3,
      'type': 'paragraph',
      'content': 'Desarrollar un robot autónomo capaz de navegar por un laberinto y encontrar la salida utilizando sensores ultrasónicos y algoritmos de pathfinding.',
      'block_order': 2
    });

    // Agregar bloques para documento 4 (Estadística)
    await db.insert('article_blocks', {
      'document_id': 4,
      'type': 'title',
      'content': 'Análisis Estadístico - Proyecto Grupal',
      'block_order': 1
    });

    await db.insert('article_blocks', {
      'document_id': 4,
      'type': 'paragraph',
      'content': 'Realizar un análisis estadístico completo de un conjunto de datos reales, aplicando técnicas de estadística descriptiva e inferencial.',
      'block_order': 2
    });

    // Agregar bloques para documento 5 (Álgebra)
    await db.insert('article_blocks', {
      'document_id': 5,
      'type': 'title',
      'content': 'Ejercicios de Álgebra Lineal',
      'block_order': 1
    });

    await db.insert('article_blocks', {
      'document_id': 5,
      'type': 'paragraph',
      'content': 'Serie de ejercicios sobre vectores, matrices, determinantes y sistemas de ecuaciones lineales.',
      'block_order': 2
    });

    // Insertar preguntas de ejemplo
    await db.insert('questions', {
      'document_id': 1,
      'type': 'multiple_choice',
      'text': '¿Cuántas aplicaciones debe desarrollar cada grupo?',
      'correct_answer': null
    });

    await db.insert('questions', {
      'document_id': 1,
      'type': 'true_false',
      'text': '¿Las aplicaciones deben usar bases de datos externas?',
      'correct_answer': 'false'
    });

    // Insertar opciones para la pregunta de opción múltiple
    await db.insert('options', {
      'question_id': 1,
      'text': 'Una aplicación',
      'is_correct': 0
    });

    await db.insert('options', {
      'question_id': 1,
      'text': 'Dos aplicaciones',
      'is_correct': 0
    });

    await db.insert('options', {
      'question_id': 1,
      'text': 'Tres aplicaciones',
      'is_correct': 1
    });

    await db.insert('options', {
      'question_id': 1,
      'text': 'Cuatro aplicaciones',
      'is_correct': 0
    });

    // Insertar clases de ejemplo
    await _insertClassSampleData(db);
  }

  // CRUD para Documents
  Future<int> insertDocument(Document document) async {
    final db = await database;
    return await db.insert('documents', document.toMap());
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final maps = await db.query('documents');
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  Future<List<Document>> getDocumentsByClass(int classId) async {
    final db = await database;
    final maps = await db.query('documents', where: 'class_id = ?', whereArgs: [classId]);
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  Future<Document?> getDocument(int id) async {
    final db = await database;
    final maps = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Document.fromMap(maps.first);
    }
    return null;
  }

  // CRUD para ArticleBlocks
  Future<int> insertArticleBlock(ArticleBlock block) async {
    final db = await database;
    return await db.insert('article_blocks', block.toMap());
  }

  Future<List<ArticleBlock>> getArticleBlocksByDocument(int documentId) async {
    final db = await database;
    final maps = await db.query(
      'article_blocks',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'block_order ASC'
    );
    return maps.map((map) => ArticleBlock.fromMap(map)).toList();
  }

  // CRUD para Questions
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsByDocument(int documentId) async {
    final db = await database;
    final maps = await db.query('questions', where: 'document_id = ?', whereArgs: [documentId]);
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // CRUD para QuestionOptions
  Future<int> insertQuestionOption(QuestionOption option) async {
    final db = await database;
    return await db.insert('options', option.toMap());
  }

  Future<List<QuestionOption>> getOptionsByQuestion(int questionId) async {
    final db = await database;
    final maps = await db.query('options', where: 'question_id = ?', whereArgs: [questionId]);
    return maps.map((map) => QuestionOption.fromMap(map)).toList();
  }

  // CRUD para Classes
  Future<int> insertClass(ClassData classData) async {
    final db = await database;
    return await db.insert('classes', classData.toMap());
  }

  Future<List<ClassData>> getAllClasses() async {
    final db = await database;
    final maps = await db.query('classes', where: 'is_active = ?', whereArgs: [1], orderBy: 'created_at DESC');
    return maps.map((map) => ClassData.fromMap(map)).toList();
  }

  Future<ClassData?> getClass(int id) async {
    final db = await database;
    final maps = await db.query('classes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return ClassData.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClass(ClassData classData) async {
    final db = await database;
    return await db.update('classes', classData.toMap(), where: 'id = ?', whereArgs: [classData.id]);
  }

  Future<int> deleteClass(int id) async {
    final db = await database;
    return await db.update('classes', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // Método para obtener documento completo
  Future<DocumentComplete?> getCompleteDocument(int documentId) async {
    final document = await getDocument(documentId);
    if (document == null) return null;

    final articleBlocks = await getArticleBlocksByDocument(documentId);
    final questions = await getQuestionsByDocument(documentId);
    
    Map<int, List<QuestionOption>> questionOptions = {};
    for (Question question in questions) {
      if (question.id != null) {
        questionOptions[question.id!] = await getOptionsByQuestion(question.id!);
      }
    }

    return DocumentComplete(
      document: document,
      articleBlocks: articleBlocks,
      questions: questions,
      questionOptions: questionOptions,
    );
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  /// Método para limpiar completamente la base de datos (útil para desarrollo)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'jacha_yachay.db');
    await deleteDatabase(path);
    _database = null; // Forzar recreación
  }
}
