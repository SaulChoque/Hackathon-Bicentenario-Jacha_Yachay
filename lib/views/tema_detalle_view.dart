import 'package:flutter/material.dart';
import '../models/class_detail_model.dart';
import '../models/database_models.dart';
import '../services/database_service.dart';

// Vista nueva para el detalle del tema
class TemaDetalleView extends StatefulWidget {
  final TaskModel task;
  final DocumentComplete? documentComplete; // Documento completo opcional
  const TemaDetalleView({
    super.key, 
    required this.task,
    this.documentComplete, // Si se proporciona, se usa directamente
  });

  @override
  State<TemaDetalleView> createState() => _TemaDetalleViewState();
}

class _TemaDetalleViewState extends State<TemaDetalleView> {
  final DatabaseService _databaseService = DatabaseService();
  DocumentComplete? documentComplete;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  Future<void> _loadDocumentData() async {
    try {
      // Si ya tenemos el documento completo, úsalo directamente
      if (widget.documentComplete != null) {
        setState(() {
          documentComplete = widget.documentComplete;
          isLoading = false;
        });
        return;
      }
      
      // Si no, carga desde la base de datos usando el documentId
      if (widget.task.documentId != null) {
        final data = await _databaseService.getCompleteDocument(
          widget.task.documentId!,
        );
        setState(() {
          documentComplete = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No se pudo encontrar el documento';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar el documento: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildArticleBlock(ArticleBlock block) {
    switch (block.type) {
      case 'title':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            block.content,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            block.content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text('Imagen', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      case 'video':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text('Video', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildQuestion(Question question, List<QuestionOption>? options) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  question.type == 'multiple_choice'
                      ? Icons.radio_button_checked
                      : question.type == 'true_false'
                      ? Icons.check_box
                      : Icons.edit,
                  color: const Color(0xFF4285F4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (question.type == 'multiple_choice' && options != null) ...[
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        option.isCorrect
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: option.isCorrect ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            color:
                                option.isCorrect ? Colors.green : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (question.type == 'true_false') ...[
              Row(
                children: [
                  Icon(
                    question.correctAnswer == 'true'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color:
                        question.correctAnswer == 'true'
                            ? Colors.green
                            : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Respuesta correcta: ${question.correctAnswer == 'true' ? 'Verdadero' : 'Falso'}',
                    style: TextStyle(
                      color:
                          question.correctAnswer == 'true'
                              ? Colors.green
                              : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ] else if (question.type == 'open') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: const Text(
                  'Respuesta abierta...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.description, color: Color(0xFF4285F4)),
              const SizedBox(width: 8),
              Text(documentComplete?.document.title ?? widget.task.title),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1F1F1F),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4285F4)),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDocumentData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : documentComplete == null
              ? const Center(
                child: Text(
                  'No se encontró el documento',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar bloques de artículo
                    ...documentComplete!.articleBlocks.map(_buildArticleBlock),

                    // Separador antes de las preguntas
                    if (documentComplete!.questions.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Preguntas de Evaluación',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mostrar preguntas
                      ...documentComplete!.questions.map((question) {
                        final options =
                            question.id != null
                                ? documentComplete!.questionOptions[question
                                    .id!]
                                : null;
                        return _buildQuestion(question, options);
                      }),
                    ],
                  ],
                ),
              ),
    );
  }
}
