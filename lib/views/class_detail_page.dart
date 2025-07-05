import 'package:flutter/material.dart';
import '../models/class_detail_model.dart';
import '../models/class_card_model.dart';
import '../models/reception_model.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import 'tema_detalle_view.dart';
import 'send_page.dart';
import 'document_editor_page.dart';

class ClassDetailPage extends StatefulWidget {
  final ClassCardModel classData;

  const ClassDetailPage({
    super.key,
    required this.classData,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TaskModel> tasks = [];
  bool isLoading = true;
  String errorMessage = '';
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Cargar tareas de la clase seleccionada
    _loadTasksForClass();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasksForClass() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final classId = widget.classData.id;
      if (classId != null) {
        // Obtener documentos de esta clase específica
        final documents = await _databaseService.getDocumentsByClass(classId);
        
        // Convertir documentos a TaskModel
        final loadedTasks = documents.map((document) => TaskModel(
          title: document.title,
          subtitle: '',
          publishDate: 'Publicada el ${document.createdAt.day}/${document.createdAt.month}',
          icon: Icons.assignment,
          isNew: DateTime.now().difference(document.createdAt).inDays < 7, // Nuevo si tiene menos de 7 días
          documentId: document.id,
        )).toList();

        setState(() {
          tasks = loadedTasks;
          isLoading = false;
        });
      } else {
        // Fallback a datos por defecto si no hay ID
        setState(() {
          tasks = _getDefaultTasksForClass(widget.classData.title);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar las tareas: $e';
        isLoading = false;
        // Usar datos por defecto en caso de error
        tasks = _getDefaultTasksForClass(widget.classData.title);
      });
    }
  }

  List<TaskModel> _getDefaultTasksForClass(String className) {
    // Datos simulados basados en la imagen
    if (className.contains('Base de Datos')) {
      return [
        TaskModel(
          title: 'Trabajo Final - Desarrollo de Apps Flutter',
          subtitle: '',
          publishDate: 'Publicada el 24 jun (editada el ...',
          icon: Icons.assignment,
          isNew: true,
          documentId: 1, // Referencia al documento en la base de datos
        ),
        TaskModel(
          title: 'Tarea nueva: Examen Recuperatorio',
          subtitle: '',
          publishDate: '23 jun',
          icon: Icons.assignment,
          isNew: true,
        ),
        TaskModel(
          title: 'Tarea nueva: Notas-Actas I-2025',
          subtitle: '',
          publishDate: 'Publicada el 18 jun (editada el 1...',
          icon: Icons.assignment,
          isNew: true,
        ),
      ];
    }
    
    // Datos por defecto para otras clases
    return [
      TaskModel(
        title: 'Tarea de ejemplo',
        subtitle: '',
        publishDate: 'Publicada ayer',
        icon: Icons.assignment,
        documentId: 1, // Usar el documento por defecto
      ),
    ];
  }

  void _removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea eliminada')),
    );
  }

  void _sendTask(int index) {
    final task = tasks[index];
    if (task.documentId != null) {
      _showSendMethodModal(task.documentId!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Documento no válido para enviar')),
      );
    }
  }

  void _showSendMethodModal(int documentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Enviar Documento',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona el método para enviar el documento',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Methods list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: TransferMethodModel.getAllMethods(mode: TransferMode.send).length,
                  itemBuilder: (context, index) {
                    final method = TransferMethodModel.getAllMethods(mode: TransferMode.send)[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SendPage(
                                method: method,
                                documentId: documentId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: method.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: method.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: method.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method.icon,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method.instruction,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: Column(
        children: [
          // Header con banner de la clase
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.classData.gradientStartColor,
                  widget.classData.gradientEndColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Icono decorativo
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Icon(
                      widget.classData.icon,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  // Botón de regreso
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Información de usuario y puntos de flama
                  Positioned(
                    top: 16,
                    right: 140,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20*3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '42', // Número simulado
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16*3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        /*const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                        ),*/
                      ],
                    ),
                  ),
                  // Contenido principal del banner
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.classData.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.classData.instructor,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tabs de navegación
          Container(
            color: const Color(0xFF1F1F1F),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4285F4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Temas'),
                Tab(text: 'Trabajos'),
              ],
            ),
          ),
          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Temas
                _buildTopicsTab(),
                // Tab de Trabajos
                _buildWorkTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4285F4),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasksForClass,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildDocumentEditorWidget(),
          const SizedBox(height: 40),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay temas disponibles para esta clase',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crea tu primer documento para comenzar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: tasks.length + 1, // +1 para el widget del editor
      itemBuilder: (context, index) {
        // Widget del editor de documentos como primer elemento
        if (index == 0) {
          return _buildDocumentEditorWidget();
        }
        
        // Ajustar el índice para las tareas
        final taskIndex = index - 1;
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemaDetalleView(task: tasks[taskIndex]),
                  ),
                );
              },
              child: TaskCard(
                task: tasks[taskIndex],
                onSend: () => _sendTask(taskIndex),
                onDelete: () => _removeTask(taskIndex),
              ),
            ),
            // Agregar comentario de clase después de cada tarea
            /*Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.comment,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agregar un comentario de clase',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),*/
          ],
        );
      },
    );
  }

  Widget _buildWorkTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay trabajos asignados',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentEditorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentEditorPage(
                classId: widget.classData.id ?? 1,
                className: widget.classData.title,
              ),
            ),
          );
          
          // Si se guardó un documento, recargar las tareas
          if (result == true) {
            _loadTasksForClass();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4285F4),
                Color(0xFF1A73E8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear Nuevo Documento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Agrega contenido y preguntas para tus estudiantes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
