import 'package:flutter/material.dart';
import '../services/class_service.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _instructorController = TextEditingController();
  
  Color _selectedStartColor = const Color(0xFF4285F4);
  Color _selectedEndColor = const Color(0xFF1A73E8);
  IconData _selectedIcon = Icons.school;
  bool _isLoading = false;

  // Lista de colores predefinidos
  final List<List<Color>> _colorPairs = [
    [const Color(0xFF4285F4), const Color(0xFF1A73E8)], // Azul
    [const Color(0xFFD93D8B), const Color(0xFFB91C7C)], // Rosa
    [const Color(0xFF0D7377), const Color(0xFF14A085)], // Verde azulado
    [const Color(0xFFFF6B35), const Color(0xFFE55100)], // Naranja
    [const Color(0xFF1565C0), const Color(0xFF0D47A1)], // Azul oscuro
    [const Color(0xFF9C27B0), const Color(0xFF673AB7)], // Púrpura
    [const Color(0xFF388E3C), const Color(0xFF1B5E20)], // Verde
    [const Color(0xFFD32F2F), const Color(0xFFB71C1C)], // Rojo
  ];

  // Lista de iconos disponibles
  final List<IconData> _availableIcons = [
    Icons.school,
    Icons.storage,
    Icons.bar_chart,
    Icons.smart_toy,
    Icons.analytics,
    Icons.calculate,
    Icons.science,
    Icons.computer,
    Icons.brush,
    Icons.music_note,
    Icons.language,
    Icons.psychology,
  ];

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ClassService.createClass(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        instructor: _instructorController.text.trim(),
        gradientStartColor: _selectedStartColor,
        gradientEndColor: _selectedEndColor,
        icon: _selectedIcon,
      );

      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar que se creó una clase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clase creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la clase: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text(
          'Crear Nueva Clase',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createClass,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Crear',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview de la tarjeta
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_selectedStartColor, _selectedEndColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Icon(
                        _selectedIcon,
                        size: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.isEmpty ? 'Título de la clase' : _titleController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitleController.text.isEmpty ? 'Subtítulo' : _subtitleController.text,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _instructorController.text.isEmpty ? 'Instructor' : _instructorController.text,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Campos del formulario
              const Text(
                'Información de la Clase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título de la clase *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ej: Base de Datos III',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4285F4)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Subtítulo
              TextFormField(
                controller: _subtitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subtítulo',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ej: INF261 - DAT251',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4285F4)),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Instructor
              TextFormField(
                controller: _instructorController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Instructor *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ej: María García',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4285F4)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El instructor es obligatorio';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // Selección de colores
              const Text(
                'Esquema de Colores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorPairs.map((colorPair) {
                  final isSelected = _selectedStartColor == colorPair[0] && _selectedEndColor == colorPair[1];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStartColor = colorPair[0];
                        _selectedEndColor = colorPair[1];
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colorPair,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Selección de icono
              const Text(
                'Icono de la Clase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableIcons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4285F4) : const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 28,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _instructorController.dispose();
    super.dispose();
  }
}
