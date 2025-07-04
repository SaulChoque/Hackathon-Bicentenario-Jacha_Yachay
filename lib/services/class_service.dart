import '../models/class_card_model.dart';
import 'package:flutter/material.dart';

class ClassService {
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
}
