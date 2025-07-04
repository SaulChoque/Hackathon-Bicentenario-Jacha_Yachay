import 'package:flutter/material.dart';
import '../models/class_card_model.dart';
import '../views/class_detail_page.dart';

class ClassCard extends StatelessWidget {
  final ClassCardModel classData;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.classData,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailPage(classData: classData),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                classData.gradientStartColor,
                classData.gradientEndColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Icono decorativo en la esquina superior derecha
              Positioned(
                top: 16,
                right: 16,
                child: Icon(
                  classData.icon,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              // Botón X en la esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.2),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ),
              // Contenido de la tarjeta
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título principal
                    Text(
                      classData.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtítulo
                    Text(
                      classData.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Nombre del instructor
                    Text(
                      classData.instructor,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
