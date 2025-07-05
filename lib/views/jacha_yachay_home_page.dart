import 'package:flutter/material.dart';
import '../models/class_card_model.dart';
import '../models/reception_model.dart';
import '../widgets/class_card.dart';
import '../services/class_service.dart';
import '../services/database_service.dart';
import '../views/enhanced_reception_page.dart';
import '../views/create_class_page.dart';

class JachaYachayHomePage extends StatefulWidget {
  const JachaYachayHomePage({super.key});

  @override
  State<JachaYachayHomePage> createState() => _JachaYachayHomePageState();
}

class _JachaYachayHomePageState extends State<JachaYachayHomePage> {
  List<ClassCardModel> classes = [];
  bool isLoading = true;
  String errorMessage = '';

  // Lista de usuarios para el menú de perfiles
  final List<String> _users = ['BlankS', 'Hernan Yazid', 'María López', 'Carlos Rivera'];
  String _selectedUser = 'nombre';

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _selectedUser = _users[1]; // Por defecto Hernan Yazid
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Inicializar datos por defecto si es necesario
      await ClassService.initializeDefaultData();
      
      // Cargar clases desde la base de datos
      final loadedClasses = await ClassService.getClasses();
      
      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar las clases: $e';
        isLoading = false;
        // Usar datos por defecto en caso de error
        classes = ClassService.getDefaultClasses();
      });
    }
  }

  void _removeClass(int index) async {
    final classToRemove = classes[index];
    // Elimina de la base de datos si tiene ID
    if (classToRemove.id != null) {
      await ClassService.deleteClass(classToRemove.id!);
    }
    // Recarga la lista desde la base de datos
    _loadClasses();
  }

  void _showReceptionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona método de recepción',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ReceptionMethodModel.getAllMethods().map((method) {
              return ListTile(
                leading: Icon(
                  method.icon,
                  color: method.color,
                  size: 28,
                ),
                title: Text(
                  method.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnhancedReceptionPage(method: method),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        automaticallyImplyLeading: false, // Elimina el botón de menú hamburguesa
        title: Row(
          children: [
            // Logo/Icono de Jacha Yachay
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF1F1F1F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Título
            const Text(
              'Jacha Yachay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Avatar del usuario con label 'nombre'
          Row(
            children: [
              Text(
                _selectedUser,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF2D2D2D),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Selecciona un perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._users.map((name) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4285F4),
                              child: Text(
                                name[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedUser = name;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF4285F4),
                  child: Text(
                    _selectedUser[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4285F4),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
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
                        onPressed: _loadClasses,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : classes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay clases disponibles',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        return ClassCard(
                          classData: classes[index],
                          onRemove: () => _removeClass(index),
                        );
                      },
                    ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón temporal para resetear DB (solo para desarrollo)
          FloatingActionButton(
            onPressed: () async {
              final databaseService = DatabaseService();
              await databaseService.resetDatabase();
              _loadClasses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Base de datos reseteada'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.refresh),
            heroTag: "reset_db",
          ),
          const SizedBox(height: 16),
          // Botón de recibir
          FloatingActionButton(
            onPressed: _showReceptionMenu,
            backgroundColor: const Color(0xFF00BFA5),
            heroTag: "receive",
            child: const Icon(
              Icons.download,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Botón de agregar clase
          FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateClassPage(),
                ),
              );
              
              // Si se creó una clase, recargar la lista
              if (result == true) {
                _loadClasses();
              }
            },
            backgroundColor: const Color(0xFF4285F4),
            heroTag: "add",
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
