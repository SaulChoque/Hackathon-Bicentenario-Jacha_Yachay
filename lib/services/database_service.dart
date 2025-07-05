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
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Crear tabla documents
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT,  
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        title TEXT
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

    // Insertar datos de ejemplo
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insertar documento de ejemplo
    await db.insert('documents', {
      'author_id': 'instructor_001',
      'created_at': DateTime.now().toIso8601String(),
      'title': 'Trabajo Final - Desarrollo de Apps Flutter'
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
}
