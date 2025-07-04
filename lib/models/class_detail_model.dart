import 'package:flutter/material.dart';

class TaskModel {
  final String title;
  final String subtitle;
  final String publishDate;
  final IconData icon;
  final bool isNew;

  TaskModel({
    required this.title,
    required this.subtitle,
    required this.publishDate,
    required this.icon,
    this.isNew = false,
  });
}

class ClassDetailModel {
  final String className;
  final String instructor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final IconData icon;
  final int flamePoints;
  final List<TaskModel> tasks;

  ClassDetailModel({
    required this.className,
    required this.instructor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.icon,
    required this.flamePoints,
    required this.tasks,
  });
}
