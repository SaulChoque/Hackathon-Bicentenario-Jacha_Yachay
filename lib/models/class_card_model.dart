import 'package:flutter/material.dart';

class ClassCardModel {
  final int? id; // ID de la clase en la base de datos
  final String title;
  final String subtitle;
  final String instructor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final IconData icon;

  ClassCardModel({
    this.id,
    required this.title,
    required this.subtitle,
    required this.instructor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.icon,
  });
}
