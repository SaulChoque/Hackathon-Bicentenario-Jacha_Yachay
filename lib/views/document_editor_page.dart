import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/database_service.dart';

class DocumentEditorPage extends StatefulWidget {
  final int classId;
  final String className;

  const DocumentEditorPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  final DatabaseService _databaseService = DatabaseService();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController(text: 'instructor_001');
  
  List<ArticleBlockData> _articleBlocks = [];
  List<QuestionData> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addInitialBlock();
  }

  void _addInitialBlock() {
    _articleBlocks.add(ArticleBlockData(
      type: 'title',
      content: '',
      blockOrder: 1,
    ));
    _articleBlocks.add(ArticleBlockData(
      type: 'paragraph',
      content: '',
      blockOrder: 2,
    ));
  }

  void _addArticleBlock(String type) {
    setState(() {
      _articleBlocks.add(ArticleBlockData(
        type: type,
        content: '',
        blockOrder: _articleBlocks.length + 1,
      ));
    });
  }

  void _removeArticleBlock(int index) {
    setState(() {
      _articleBlocks.removeAt(index);
      // Reordenar los bloques
      for (int i = 0; i < _articleBlocks.length; i++) {
        _articleBlocks[i] = _articleBlocks[i].copyWith(blockOrder: i + 1);
      }
    });
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionData(
        type: 'multiple_choice',
        text: '',
        correctAnswer: null,
        options: [
          QuestionOptionData(text: '', isCorrect: false),
          QuestionOptionData(text: '', isCorrect: false),
          QuestionOptionData(text: '', isCorrect: true),
          QuestionOptionData(text: '', isCorrect: false),
        ],
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(
        QuestionOptionData(text: '', isCorrect: false),
      );
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      if (_questions[questionIndex].options.length > 2) {
        _questions[questionIndex].options.removeAt(optionIndex);
      }
    });
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título del documento es obligatorio')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear el documento
      final document = Document(
        authorId: _authorController.text.trim(),
        createdAt: DateTime.now(),
        title: _titleController.text.trim(),
        classId: widget.classId,
      );

      // Insertar documento en la base de datos
      final documentId = await _databaseService.insertDocument(document);

      // Insertar bloques de artículo
      for (final block in _articleBlocks) {
        if (block.content.trim().isNotEmpty) {
          final articleBlock = ArticleBlock(
            documentId: documentId,
            type: block.type,
            content: block.content.trim(),
            blockOrder: block.blockOrder,
          );
          await _databaseService.insertArticleBlock(articleBlock);
        }
      }

      // Insertar preguntas y opciones
      for (final questionData in _questions) {
        if (questionData.text.trim().isNotEmpty) {
          final question = Question(
            documentId: documentId,
            type: questionData.type,
            text: questionData.text.trim(),
            correctAnswer: questionData.correctAnswer,
          );
          
          final questionId = await _databaseService.insertQuestion(question);

          // Insertar opciones de la pregunta
          for (final optionData in questionData.options) {
            if (optionData.text.trim().isNotEmpty) {
              final option = QuestionOption(
                questionId: questionId,
                text: optionData.text.trim(),
                isCorrect: optionData.isCorrect,
              );
              await _databaseService.insertQuestionOption(option);
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento guardado exitosamente')),
        );
        Navigator.pop(context, true); // Retorna true para indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el documento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editor de Documento', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              widget.className,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDocument,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar', style: TextStyle(color: Color(0xFF4285F4))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica del documento
            Card(
              color: const Color(0xFF2D2D2D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Documento',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Título del documento',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4285F4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Autor',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4285F4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bloques de artículo
            Card(
              color: const Color(0xFF2D2D2D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y botón en columnas separadas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contenido del Documento',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        PopupMenuButton<String>(
                          onSelected: _addArticleBlock,
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'title', child: Text('Título')),
                            const PopupMenuItem(value: 'paragraph', child: Text('Párrafo')),
                            const PopupMenuItem(value: 'subtitle', child: Text('Subtítulo')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Agregar bloque', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._articleBlocks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final block = entry.value;
                      return _buildArticleBlockEditor(block, index);
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preguntas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Card(
                    color: const Color(0xFF2D2D2D),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Título y botón en columnas separadas (igual que en bloques)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Preguntas del Documento',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _addQuestion,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar pregunta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._questions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final question = entry.value;
                            return _buildQuestionEditor(question, index);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleBlockEditor(ArticleBlockData block, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF4D4D4D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  block.type == 'title' ? Icons.title :
                  block.type == 'subtitle' ? Icons.subtitles :
                  Icons.subject,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  block.type == 'title' ? 'Título' :
                  block.type == 'subtitle' ? 'Subtítulo' :
                  'Párrafo',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeArticleBlock(index),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _articleBlocks[index] = block.copyWith(content: value);
                });
              },
              maxLines: block.type == 'paragraph' ? 5 : 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: block.type == 'title' ? 20 : 
                         block.type == 'subtitle' ? 18 : 16,
                fontWeight: block.type == 'title' ? FontWeight.bold :
                           block.type == 'subtitle' ? FontWeight.w600 :
                           FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: block.type == 'title' ? 'Ingrese el título...' :
                         block.type == 'subtitle' ? 'Ingrese el subtítulo...' :
                         'Ingrese el contenido del párrafo...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4285F4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(QuestionData question, int questionIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF4D4D4D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Pregunta ${questionIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: question.type,
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'multiple_choice', child: Text('Opción múltiple')),
                    DropdownMenuItem(value: 'true_false', child: Text('Verdadero/Falso')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _questions[questionIndex] = question.copyWith(type: value!);
                    });
                  },
                ),
                IconButton(
                  onPressed: () => _removeQuestion(questionIndex),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _questions[questionIndex] = question.copyWith(text: value);
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Texto de la pregunta',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4285F4)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (question.type == 'multiple_choice') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Opciones de respuesta:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addOption(questionIndex),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agregar opción'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...question.options.asMap().entries.map((entry) {
                    final optionIndex = entry.key;
                    final option = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: option.isCorrect,
                            onChanged: (value) {
                              setState(() {
                                // Solo una opción puede ser correcta
                                for (int i = 0; i < question.options.length; i++) {
                                  question.options[i] = question.options[i].copyWith(
                                    isCorrect: i == optionIndex ? value! : false,
                                  );
                                }
                              });
                            },
                            activeColor: const Color(0xFF4285F4),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  question.options[optionIndex] = option.copyWith(text: value);
                                });
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Opción ${optionIndex + 1}',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: const OutlineInputBorder(),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF4285F4)),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeOption(questionIndex, optionIndex),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                if (question.type == 'true_false') ...[
                  const Text(
                    'Respuesta correcta:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Verdadero', style: TextStyle(color: Colors.white)),
                          value: 'true',
                          groupValue: question.correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _questions[questionIndex] = question.copyWith(correctAnswer: value);
                            });
                          },
                          activeColor: const Color(0xFF4285F4),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Falso', style: TextStyle(color: Colors.white)),
                          value: 'false',
                          groupValue: question.correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _questions[questionIndex] = question.copyWith(correctAnswer: value);
                            });
                          },
                          activeColor: const Color(0xFF4285F4),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}

// Clases auxiliares para manejar los datos del editor
class ArticleBlockData {
  final String type;
  final String content;
  final int blockOrder;

  ArticleBlockData({
    required this.type,
    required this.content,
    required this.blockOrder,
  });

  ArticleBlockData copyWith({
    String? type,
    String? content,
    int? blockOrder,
  }) {
    return ArticleBlockData(
      type: type ?? this.type,
      content: content ?? this.content,
      blockOrder: blockOrder ?? this.blockOrder,
    );
  }
}

class QuestionData {
  final String type;
  final String text;
  final String? correctAnswer;
  final List<QuestionOptionData> options;

  QuestionData({
    required this.type,
    required this.text,
    this.correctAnswer,
    required this.options,
  });

  QuestionData copyWith({
    String? type,
    String? text,
    String? correctAnswer,
    List<QuestionOptionData>? options,
  }) {
    return QuestionData(
      type: type ?? this.type,
      text: text ?? this.text,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
    );
  }
}

class QuestionOptionData {
  final String text;
  final bool isCorrect;

  QuestionOptionData({
    required this.text,
    required this.isCorrect,
  });

  QuestionOptionData copyWith({
    String? text,
    bool? isCorrect,
  }) {
    return QuestionOptionData(
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
