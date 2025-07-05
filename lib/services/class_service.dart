import '../models/class_card_model.dart';
import '../models/database_models.dart';
import '../services/database_service.dart';
import '../services/ui_helper.dart';
import 'package:flutter/material.dart';

class ClassService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Obtiene todas las clases desde la base de datos
  static Future<List<ClassCardModel>> getClasses() async {
    try {
      final classDataList = await _databaseService.getAllClasses();
      print('============= >>>>>>>>>>>>>> DATOSSSSSS');
      return classDataList.map((classData) => _convertToClassCardModel(classData)).toList();
    } catch (e) {
      // En caso de error, devolver lista vacía o datos por defecto
      print('============= >>>>>>>>>>>>>> Error al cargar clases: $e');
      return getDefaultClasses();
    }
  }

  /// Convierte ClassData (DB) a ClassCardModel (UI)
  static ClassCardModel _convertToClassCardModel(ClassData classData) {
    return ClassCardModel(
      title: classData.title,
      subtitle: classData.subtitle,
      instructor: classData.instructor,
      gradientStartColor: UiHelper.getColorFromString(classData.gradientStartColor),
      gradientEndColor: UiHelper.getColorFromString(classData.gradientEndColor),
      icon: UiHelper.getIconFromString(classData.iconName),
    );
  }

  /// Crea una nueva clase en la base de datos
  static Future<int> createClass({
    required String title,
    required String subtitle,
    required String instructor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    IconData? icon,
  }) async {
    final classData = ClassData(
      title: title,
      subtitle: subtitle,
      instructor: instructor,
      gradientStartColor: UiHelper.getStringFromColor(gradientStartColor ?? const Color(0xFF4285F4)),
      gradientEndColor: UiHelper.getStringFromColor(gradientEndColor ?? const Color(0xFF1A73E8)),
      iconName: UiHelper.getStringFromIcon(icon ?? Icons.class_),
      createdAt: DateTime.now(),
    );

    return await _databaseService.insertClass(classData);
  }

  /// Actualiza una clase existente
  static Future<int> updateClass({
    required int id,
    required String title,
    required String subtitle,
    required String instructor,
    required Color gradientStartColor,
    required Color gradientEndColor,
    required IconData icon,
  }) async {
    final classData = ClassData(
      id: id,
      title: title,
      subtitle: subtitle,
      instructor: instructor,
      gradientStartColor: UiHelper.getStringFromColor(gradientStartColor),
      gradientEndColor: UiHelper.getStringFromColor(gradientEndColor),
      iconName: UiHelper.getStringFromIcon(icon),
      createdAt: DateTime.now(), // Se podría mantener la fecha original
    );

    return await _databaseService.updateClass(classData);
  }

  /// Elimina una clase (soft delete)
  static Future<int> deleteClass(int id) async {
    return await _databaseService.deleteClass(id);
  }

  /// Obtiene una clase específica por ID
  static Future<ClassData?> getClassById(int id) async {
    return await _databaseService.getClass(id);
  }

  /// Datos por defecto (fallback) - mantener como backup
  static List<ClassCardModel> getDefaultClasses() {
    return [
      ClassCardModel(
        title: 'Base de Datos III',
        subtitle: 'Celia Tarquino',
        instructor: 'Celia Tarquino',
        gradientStartColor: const Color(0xFF4285F4),
        gradientEndColor: const Color(0xFF1A73E8),
        icon: Icons.storage,
      ),
      ClassCardModel(
        title: 'INF261 - DAT251',
        subtitle: 'BASE DE DATOS III',
        instructor: 'Celia Tarquino',
        gradientStartColor: const Color(0xFFD93D8B),
        gradientEndColor: const Color(0xFFB91C7C),
        icon: Icons.bar_chart,
      ),
      ClassCardModel(
        title: 'INF-357 ROBÓTICA',
        subtitle: 'Temporada I/2025',
        instructor: 'Nagib Vallejos Mamani',
        gradientStartColor: const Color(0xFF0D7377),
        gradientEndColor: const Color(0xFF14A085),
        icon: Icons.smart_toy,
      ),
      ClassCardModel(
        title: 'AUXILIATURA ESTADÍSTI...',
        subtitle: '',
        instructor: 'Adriana Cardenas Soria',
        gradientStartColor: const Color(0xFFFF6B35),
        gradientEndColor: const Color(0xFFE55100),
        icon: Icons.analytics,
      ),
      ClassCardModel(
        title: 'ÁLGEBRA PARALELO A ...',
        subtitle: 'Paralelo A',
        instructor: 'Jonathan Orellana',
        gradientStartColor: const Color(0xFF1565C0),
        gradientEndColor: const Color(0xFF0D47A1),
        icon: Icons.calculate,
      ),
    ];
  }

  /// Método legacy para crear clase (mantener compatibilidad)
  static ClassCardModel createNewClass({
    required String title,
    required String subtitle,
    required String instructor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    IconData? icon,
  }) {
    return ClassCardModel(
      title: title,
      subtitle: subtitle,
      instructor: instructor,
      gradientStartColor: gradientStartColor ?? const Color(0xFF4285F4),
      gradientEndColor: gradientEndColor ?? const Color(0xFF1A73E8),
      icon: icon ?? Icons.class_,
    );
  }

  /// Inicializa los datos por defecto en la base de datos si está vacía
  static Future<void> initializeDefaultData() async {
    try {
      final existingClasses = await _databaseService.getAllClasses();
      if (existingClasses.isEmpty) {
        print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DATOS POR DEFECTO initialize or default >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n');
        // Insertar datos por defecto
        await createClass(
          title: 'Base de Datos III',
          subtitle: 'Celia Tarquino',
          instructor: 'Celia Tarquino',
          gradientStartColor: const Color(0xFF4285F4),
          gradientEndColor: const Color(0xFF1A73E8),
          icon: Icons.storage,
        );

        await createClass(
          title: 'INF261 - DAT251',
          subtitle: 'BASE DE DATOS III',
          instructor: 'Celia Tarquino',
          gradientStartColor: const Color(0xFFD93D8B),
          gradientEndColor: const Color(0xFFB91C7C),
          icon: Icons.bar_chart,
        );

        await createClass(
          title: 'INF-357 ROBÓTICA',
          subtitle: 'Temporada I/2025',
          instructor: 'Nagib Vallejos Mamani',
          gradientStartColor: const Color(0xFF0D7377),
          gradientEndColor: const Color(0xFF14A085),
          icon: Icons.smart_toy,
        );

        await createClass(
          title: 'AUXILIATURA ESTADÍSTI...',
          subtitle: '',
          instructor: 'Adriana Cardenas Soria',
          gradientStartColor: const Color(0xFFFF6B35),
          gradientEndColor: const Color(0xFFE55100),
          icon: Icons.analytics,
        );

        await createClass(
          title: 'ÁLGEBRA PARALELO A ...',
          subtitle: 'Paralelo A',
          instructor: 'Jonathan Orellana',
          gradientStartColor: const Color(0xFF1565C0),
          gradientEndColor: const Color(0xFF0D47A1),
          icon: Icons.calculate,
        );
      }
    } catch (e) {
      print('Error al inicializar datos por defecto: $e');
    }
  }
}
