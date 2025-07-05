import 'package:flutter/material.dart';
import '../models/class_detail_model.dart';
import '../models/class_card_model.dart';
import '../widgets/task_card.dart';

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
  late List<TaskModel> tasks;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Simulamos datos de tareas para la clase seleccionada
    tasks = _getTasksForClass(widget.classData.title);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _getTasksForClass(String className) {
    // Datos simulados basados en la imagen
    if (className.contains('Base de Datos')) {
      return [
        TaskModel(
          title: 'Tarea nueva: Oportunidad hasta 25.6.25 medio día.',
          subtitle: '',
          publishDate: 'Publicada el 24 jun (editada el ...',
          icon: Icons.assignment,
          isNew: true,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enviando: ${tasks[index].title}')),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemaDetalleView(task: tasks[index]),
                  ),
                );
              },
              child: TaskCard(
                task: tasks[index],
                onSend: () => _sendTask(index),
                onDelete: () => _removeTask(index),
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
}

// Vista nueva para el detalle del tema
class TemaDetalleView extends StatelessWidget {
  final TaskModel task;
  const TemaDetalleView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Row(
          children: [
            Icon(Icons.description, color: Color(0xFF4285F4)),
            const SizedBox(width: 8),
            const Text('Trabajo Final'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1F1F1F),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text(
                'Cada grupo deberá desarrollar tres aplicaciones móviles usando Flutter, una para cada nivel de dificultad (básico, intermedio y avanzado), todas dentro de un mismo contexto temático...',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Por ejemplo: Área TEATRO:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Ø App Básico: App de Cartelera Cultural', style: TextStyle(fontSize: 15, color: Colors.white)),
              Text('Ø App Intermedio: Organización de Evento Teatral (Grupal)', style: TextStyle(fontSize: 15, color: Colors.white)),
              Text('Ø App Avanzado: Simulador de Reserva de Entradas', style: TextStyle(fontSize: 15, color: Colors.white)),
              const SizedBox(height: 16),
              const Text(
                'Las aplicaciones deberán funcionar sin conexión a internet y no usar bases de datos ni servicios externos. Se enfocarán en el diseño de interfaces, la navegación entre pantallas y la lógica interna del manejo de datos en memoria.',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
