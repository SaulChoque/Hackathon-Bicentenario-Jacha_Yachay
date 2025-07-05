import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';

import 'database_service.dart';
import '../models/database_models.dart';

class ExportService {
  final DatabaseService _dbService = DatabaseService();

  /// Exporta un documento completo y sus datos relacionados a un archivo .jacha (zip)
  Future<File> exportDocumentAsJacha(int documentId) async {
    try {
      // 1. Obtener datos completos del documento
      final docComplete = await _dbService.getCompleteDocument(documentId);
      if (docComplete == null) {
        throw Exception('Documento no encontrado');
      }

      // 2. Crear estructura de datos para exportar
      final exportData = _buildExportData(docComplete);
      final jsonData = jsonEncode(exportData);

      // 3. Crear carpeta temporal para el export
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(join(tempDir.path, 'export_jacha_$documentId'));
      if (exportDir.existsSync()) {
        exportDir.deleteSync(recursive: true);
      }
      exportDir.createSync();

      // 4. Guardar JSON con los datos del documento
      final jsonFile = File(join(exportDir.path, 'document.json'));
      await jsonFile.writeAsString(jsonData);

      // 5. Crear carpeta para archivos multimedia (si los hay)
      final mediaDir = Directory(join(exportDir.path, 'media'));
      mediaDir.createSync();

      // 6. Procesar archivos multimedia referenciados en el contenido
      await _processMediaFiles(docComplete, mediaDir);

      // 7. Comprimir todo en un archivo .jacha
      final jachaPath = join(tempDir.path, 'documento_${docComplete.document.title.replaceAll(' ', '_')}_$documentId.jacha');
      await _createZipFile(exportDir, jachaPath);

      // 8. Limpiar carpeta temporal
      exportDir.deleteSync(recursive: true);

      return File(jachaPath);
    } catch (e) {
      throw Exception('Error al exportar documento: $e');
    }
  }

  /// Construye la estructura de datos para exportar
  Map<String, dynamic> _buildExportData(DocumentComplete docComplete) {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'document': {
        'id': docComplete.document.id,
        'title': docComplete.document.title,
        'authorId': docComplete.document.authorId,
        'createdAt': docComplete.document.createdAt.toIso8601String(),
        'classId': docComplete.document.classId,
      },
      'articleBlocks': docComplete.articleBlocks.map((block) => {
        'id': block.id,
        'documentId': block.documentId,
        'type': block.type,
        'content': block.content,
        'blockOrder': block.blockOrder,
      }).toList(),
      'questions': docComplete.questions.map((question) => {
        'id': question.id,
        'documentId': question.documentId,
        'type': question.type,
        'text': question.text,
        'correctAnswer': question.correctAnswer,
      }).toList(),
      'questionOptions': docComplete.questionOptions.map((questionId, options) => 
        MapEntry(questionId.toString(), options.map((option) => {
          'id': option.id,
          'questionId': option.questionId,
          'text': option.text,
          'isCorrect': option.isCorrect,
        }).toList())
      ),
    };
  }

  /// Procesa y copia archivos multimedia referenciados en el contenido
  Future<void> _processMediaFiles(DocumentComplete docComplete, Directory mediaDir) async {
    // TODO: Implementar cuando se agregue soporte para multimedia
    // Por ahora, simplemente creamos archivos de ejemplo para demostrar la estructura
    
    // Buscar referencias a archivos en el contenido de los bloques
    for (var block in docComplete.articleBlocks) {
      if (block.type == 'image' || block.type == 'video' || block.type == 'audio') {
        // En el futuro, aquí se procesarían las rutas de archivos reales
        // Por ahora, crear un archivo placeholder
        final placeholderFile = File(join(mediaDir.path, 'placeholder_${block.id}.txt'));
        await placeholderFile.writeAsString('Placeholder for ${block.type}: ${block.content}');
      }
    }
  }

  /// Crea el archivo ZIP con extensión .jacha
  Future<void> _createZipFile(Directory sourceDir, String outputPath) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);
    encoder.addDirectory(sourceDir);
    encoder.close();
  }

  /// Comparte el archivo .jacha usando el sistema nativo de compartir
  Future<void> shareJachaFile(File jachaFile) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(jachaFile.path)],
        text: 'Documento Jacha Yachay: ${basename(jachaFile.path)}',
        subject: 'Compartir documento educativo',
      );

      if (result.status == ShareResultStatus.success) {
        print('Archivo compartido exitosamente');
      }
    } catch (e) {
      throw Exception('Error al compartir archivo: $e');
    }
  }

  /// Exporta y comparte un documento en un solo paso
  Future<void> exportAndShareDocument(int documentId) async {
    try {
      // 1. Exportar documento
      final jachaFile = await exportDocumentAsJacha(documentId);
      
      // 2. Compartir archivo
      await shareJachaFile(jachaFile);
      
    } catch (e) {
      throw Exception('Error en el proceso de exportación y compartir: $e');
    }
  }

  /// Limpia archivos temporales de exportación antiguos
  Future<void> cleanupOldExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (var file in files) {
        if (file.path.contains('.jacha') && file is File) {
          final stat = await file.stat();
          final daysSinceCreation = DateTime.now().difference(stat.changed).inDays;
          
          // Eliminar archivos .jacha más antiguos de 7 días
          if (daysSinceCreation > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error al limpiar archivos temporales: $e');
    }
  }
}
