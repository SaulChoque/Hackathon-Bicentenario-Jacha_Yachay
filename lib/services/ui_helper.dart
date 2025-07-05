import 'package:flutter/material.dart';

class UiHelper {
  // Mapa de nombres de iconos a IconData
  static const Map<String, IconData> _iconMap = {
    'storage': Icons.storage,
    'bar_chart': Icons.bar_chart,
    'smart_toy': Icons.smart_toy,
    'analytics': Icons.analytics,
    'calculate': Icons.calculate,
    'class_': Icons.class_,
    'book': Icons.book,
    'school': Icons.school,
    'assignment': Icons.assignment,
    'computer': Icons.computer,
    'science': Icons.science,
    'engineering': Icons.engineering,
    'psychology': Icons.psychology,
    'language': Icons.language,
    'history_edu': Icons.history_edu,
    'music_note': Icons.music_note,
    'palette': Icons.palette,
    'sports': Icons.sports,
    'fitness_center': Icons.fitness_center,
  };

  /// Convierte un string de nombre de icono a IconData
  static IconData getIconFromString(String iconName) {
    return _iconMap[iconName] ?? Icons.class_;
  }

  /// Convierte un string hex a Color
  static Color getColorFromString(String colorString) {
    try {
      // Remueve el '0x' si está presente y convierte a int
      final colorValue = int.parse(colorString.replaceAll('0x', ''), radix: 16);
      return Color(colorValue);
    } catch (e) {
      // Color por defecto en caso de error
      return const Color(0xFF4285F4);
    }
  }

  /// Convierte Color a string hex para almacenar en base de datos
  static String getStringFromColor(Color color) {
    return '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Obtiene el nombre del icono desde IconData (para almacenar en DB)
  static String getStringFromIcon(IconData icon) {
    // Busca en el mapa el nombre que corresponde al icono
    for (String key in _iconMap.keys) {
      if (_iconMap[key] == icon) {
        return key;
      }
    }
    return 'class_'; // Valor por defecto
  }

  /// Lista de todos los iconos disponibles para selección
  static List<MapEntry<String, IconData>> get availableIcons {
    return _iconMap.entries.toList();
  }

  /// Lista de colores predefinidos para las clases
  static List<Color> get predefinedColors {
    return [
      const Color(0xFF4285F4), // Azul Google
      const Color(0xFF1A73E8), // Azul oscuro
      const Color(0xFFD93D8B), // Rosa
      const Color(0xFFB91C7C), // Rosa oscuro
      const Color(0xFF0D7377), // Verde azulado
      const Color(0xFF14A085), // Verde menta
      const Color(0xFFFF6B35), // Naranja
      const Color(0xFFE55100), // Naranja oscuro
      const Color(0xFF1565C0), // Azul índigo
      const Color(0xFF0D47A1), // Azul marino
      const Color(0xFF6A1B9A), // Púrpura
      const Color(0xFF4A148C), // Púrpura oscuro
      const Color(0xFFC62828), // Rojo
      const Color(0xFFAD1457), // Rosa intenso
      const Color(0xFF00695C), // Verde oscuro
      const Color(0xFF2E7D32), // Verde
    ];
  }
}
