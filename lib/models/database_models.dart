// Modelos para la base de datos SQLite

class Document {
  final int? id;
  final String authorId;
  final DateTime createdAt;
  final String title;
  final int? classId; // ID de la clase a la que pertenece

  Document({
    this.id,
    required this.authorId,
    required this.createdAt,
    required this.title,
    this.classId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'class_id': classId,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      authorId: map['author_id'],
      createdAt: DateTime.parse(map['created_at']),
      title: map['title'],
      classId: map['class_id'],
    );
  }
}

class Question {
  final int? id;
  final int documentId;
  final String type; // 'multiple_choice', 'true_false', 'open'
  final String text;
  final String? correctAnswer; // Para preguntas abiertas o verdadero/falso

  Question({
    this.id,
    required this.documentId,
    required this.type,
    required this.text,
    this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'type': type,
      'text': text,
      'correct_answer': correctAnswer,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      documentId: map['document_id'],
      type: map['type'],
      text: map['text'],
      correctAnswer: map['correct_answer'],
    );
  }
}

class QuestionOption {
  final int? id;
  final int questionId;
  final String text;
  final bool isCorrect;

  QuestionOption({
    this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'text': text,
      'is_correct': isCorrect ? 1 : 0,
    };
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      id: map['id'],
      questionId: map['question_id'],
      text: map['text'],
      isCorrect: map['is_correct'] == 1,
    );
  }
}

class ArticleBlock {
  final int? id;
  final int documentId;
  final String type; // 'title', 'paragraph', 'image', 'video'
  final String content; // texto o URL
  final int blockOrder;

  ArticleBlock({
    this.id,
    required this.documentId,
    required this.type,
    required this.content,
    required this.blockOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'type': type,
      'content': content,
      'block_order': blockOrder,
    };
  }

  factory ArticleBlock.fromMap(Map<String, dynamic> map) {
    return ArticleBlock(
      id: map['id'],
      documentId: map['document_id'],
      type: map['type'],
      content: map['content'],
      blockOrder: map['block_order'],
    );
  }
}

// Modelo para las clases/materias
class ClassData {
  final int? id;
  final String title;
  final String subtitle;
  final String instructor;
  final String gradientStartColor; // Almacenado como hex string
  final String gradientEndColor;   // Almacenado como hex string
  final String iconName;           // Nombre del icono
  final DateTime createdAt;
  final bool isActive;

  ClassData({
    this.id,
    required this.title,
    required this.subtitle,
    required this.instructor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.iconName,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'instructor': instructor,
      'gradient_start_color': gradientStartColor,
      'gradient_end_color': gradientEndColor,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ClassData.fromMap(Map<String, dynamic> map) {
    return ClassData(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      instructor: map['instructor'],
      gradientStartColor: map['gradient_start_color'],
      gradientEndColor: map['gradient_end_color'],
      iconName: map['icon_name'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] == 1,
    );
  }
}

// Modelo completo que incluye documento con sus bloques y preguntas
class DocumentComplete {
  final Document document;
  final List<ArticleBlock> articleBlocks;
  final List<Question> questions;
  final Map<int, List<QuestionOption>> questionOptions; // questionId -> options

  DocumentComplete({
    required this.document,
    required this.articleBlocks,
    required this.questions,
    required this.questionOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'document': document.toMap(),
      'articleBlocks': articleBlocks.map((block) => block.toMap()).toList(),
      'questions': questions.map((question) => question.toMap()).toList(),
      'questionOptions': questionOptions.map((questionId, options) => 
        MapEntry(questionId.toString(), options.map((option) => option.toMap()).toList())
      ),
    };
  }
}
