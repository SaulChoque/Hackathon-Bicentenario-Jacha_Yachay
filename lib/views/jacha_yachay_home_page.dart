import 'package:flutter/material.dart';
import '../models/class_card_model.dart';
import '../widgets/class_card.dart';
import '../services/class_service.dart';

class JachaYachayHomePage extends StatefulWidget {
  const JachaYachayHomePage({super.key});

  @override
  State<JachaYachayHomePage> createState() => _JachaYachayHomePageState();
}

class _JachaYachayHomePageState extends State<JachaYachayHomePage> {
  List<ClassCardModel> classes = ClassService.getDefaultClasses();

  void _removeClass(int index) {
    setState(() {
      classes.removeAt(index);
    });
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
              const Text(
                'nombre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF4285F4),
                child: const Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: classes.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí se podría agregar funcionalidad para añadir nuevas clases
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función para agregar nueva clase'),
            ),
          );
        },
        backgroundColor: const Color(0xFF4285F4),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
