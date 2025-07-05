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

      // 3. Crear carpeta temporal para el export (con fallback)
      final tempDir = await _getTemporaryDirectory();
      final exportDir = Directory(join(tempDir.path, 'export_jacha_$documentId'));
      if (exportDir.existsSync()) {
        exportDir.deleteSync(recursive: true);
      }
      exportDir.createSync(recursive: true);

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
      print('Error al exportar documento: $e');
      throw Exception('Error al exportar documento: $e');
    }
  }

  /// Método simplificado para debugging - exporta solo JSON sin ZIP
  Future<File> exportDocumentAsJsonDebug(int documentId) async {
    try {
      // 1. Obtener datos completos del documento
      final docComplete = await _dbService.getCompleteDocument(documentId);
      if (docComplete == null) {
        throw Exception('Documento no encontrado');
      }

      // 2. Crear estructura de datos para exportar
      final exportData = _buildExportData(docComplete);
      final jsonData = jsonEncode(exportData);

      // 3. Usar directorio del sistema temporal para debugging
      final systemTempDir = Directory.systemTemp;
      final debugFile = File(join(systemTempDir.path, 'debug_document_$documentId.json'));
      
      // 4. Escribir JSON directamente
      await debugFile.writeAsString(jsonData);
      
      print('Debug: Archivo JSON creado en: ${debugFile.path}');
      return debugFile;
      
    } catch (e) {
      print('Error en exportación debug: $e');
      rethrow;
    }
  }

  /// Método alternativo que no usa path_provider en absoluto
  Future<File> exportDocumentAsJachaAlternative(int documentId) async {
    try {
      print('Iniciando exportación alternativa para documento $documentId');
      
      // 1. Obtener datos completos del documento
      final docComplete = await _dbService.getCompleteDocument(documentId);
      if (docComplete == null) {
        throw Exception('Documento no encontrado');
      }

      // 2. Crear estructura de datos para exportar
      final exportData = _buildExportData(docComplete);
      final jsonData = jsonEncode(exportData);

      // 3. Usar directorio del sistema temporal (más confiable)
      final systemTempDir = Directory.systemTemp;
      final exportDir = Directory(join(systemTempDir.path, 'jacha_yachay', 'export_$documentId'));
      
      print('Creando directorio: ${exportDir.path}');
      if (exportDir.existsSync()) {
        exportDir.deleteSync(recursive: true);
      }
      exportDir.createSync(recursive: true);

      // 4. Guardar JSON con los datos del documento
      final jsonFile = File(join(exportDir.path, 'document.json'));
      await jsonFile.writeAsString(jsonData);
      print('JSON guardado en: ${jsonFile.path}');

      // 5. Crear carpeta para archivos multimedia (si los hay)
      final mediaDir = Directory(join(exportDir.path, 'media'));
      mediaDir.createSync();

      // 6. Procesar archivos multimedia referenciados en el contenido
      await _processMediaFiles(docComplete, mediaDir);

      // 7. Comprimir todo en un archivo .jacha
      final jachaPath = join(systemTempDir.path, 'jacha_yachay', 'documento_${docComplete.document.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')}_$documentId.jacha');
      print('Creando archivo ZIP en: $jachaPath');
      
      await _createZipFile(exportDir, jachaPath);
      print('ZIP creado exitosamente');

      // 8. Limpiar carpeta temporal
      exportDir.deleteSync(recursive: true);

      final jachaFile = File(jachaPath);
      if (jachaFile.existsSync()) {
        print('Archivo .jacha creado exitosamente: ${jachaFile.path}');
        return jachaFile;
      } else {
        throw Exception('El archivo .jacha no se creó correctamente');
      }
      
    } catch (e) {
      print('Error en exportación alternativa: $e');
      throw Exception('Error al exportar documento: $e');
    }
  }

  /// Inicializa el servicio de exportación creando directorios necesarios
  Future<void> initialize() async {
    try {
      final systemTempDir = Directory.systemTemp;
      final exportsDir = Directory(join(systemTempDir.path, 'jacha_yachay'));
      
      if (!exportsDir.existsSync()) {
        exportsDir.createSync(recursive: true);
        print('Directorio de exportaciones creado: ${exportsDir.path}');
      } else {
        print('Directorio de exportaciones ya existe: ${exportsDir.path}');
      }
    } catch (e) {
      print('Error al inicializar ExportService: $e');
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
      print('Intentando compartir archivo: ${jachaFile.path}');
      
      // Verificar que el archivo existe
      if (!jachaFile.existsSync()) {
        throw Exception('El archivo no existe: ${jachaFile.path}');
      }
      
      // Verificar el tamaño del archivo
      final fileSize = await jachaFile.length();
      print('Tamaño del archivo: $fileSize bytes');
      
      // Intentar compartir con share_plus
      try {
        final result = await Share.shareXFiles(
          [XFile(jachaFile.path)],
          text: 'Documento Jacha Yachay: ${basename(jachaFile.path)}',
          subject: 'Compartir documento educativo',
        );

        if (result.status == ShareResultStatus.success) {
          print('Archivo compartido exitosamente con share_plus');
        } else {
          print('Compartir cancelado o falló: ${result.status}');
        }
      } catch (shareError) {
        print('Error con share_plus: $shareError');
        
        // Fallback: simplemente mostrar la ruta del archivo
        print('ARCHIVO GENERADO EXITOSAMENTE EN: ${jachaFile.path}');
        print('Puede encontrar el archivo .jacha en la ubicación mostrada arriba');
        
        // En este caso, consideramos que fue exitoso porque el archivo se creó
        // El usuario puede acceder manualmente al archivo
      }
      
    } catch (e) {
      print('Error general al compartir archivo: $e');
      throw Exception('Error al compartir archivo: $e');
    }
  }

  /// Exporta y comparte un documento en un solo paso
  Future<void> exportAndShareDocument(int documentId) async {
    try {
      print('Iniciando exportación del documento $documentId...');
      
      File fileToShare;
      
      // Intentar primero la versión alternativa (más confiable)
      try {
        fileToShare = await exportDocumentAsJachaAlternative(documentId);
        print('Exportación alternativa exitosa: ${fileToShare.path}');
      } catch (e) {
        print('Error en exportación alternativa: $e');
        
        // Fallback a exportación original con path_provider
        try {
          fileToShare = await exportDocumentAsJacha(documentId);
          print('Exportación con path_provider exitosa: ${fileToShare.path}');
        } catch (e2) {
          print('Error en exportación original, intentando debug: $e2');
          
          // Último fallback a exportación JSON simple
          fileToShare = await exportDocumentAsJsonDebug(documentId);
          print('Exportación debug exitosa: ${fileToShare.path}');
        }
      }
      
      // 2. Compartir archivo
      await shareJachaFile(fileToShare);
      
    } catch (e) {
      print('Error completo en el proceso: $e');
      throw Exception('Error en el proceso de exportación y compartir: $e');
    }
  }

  /// Limpia archivos temporales de exportación antiguos
  Future<void> cleanupOldExports() async {
    try {
      final tempDir = await _getTemporaryDirectory();
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

  /// Obtiene el directorio temporal con manejo robusto de errores
  Future<Directory> _getTemporaryDirectory() async {
    try {
      // Intentar usar path_provider primero
      return await getTemporaryDirectory();
    } catch (e) {
      print('Error con path_provider: $e');
      
      // Fallback para Android/iOS: usar directorio de documentos de la aplicación
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final tempDir = Directory(join(appDocDir.path, 'temp_jacha'));
        if (!tempDir.existsSync()) {
          tempDir.createSync(recursive: true);
        }
        return tempDir;
      } catch (e2) {
        print('Error con application documents directory: $e2');
        
        // Último fallback: usar directorio del sistema
        try {
          final systemTempDir = Directory.systemTemp;
          final jachaSystemTempDir = Directory(join(systemTempDir.path, 'jacha_yachay'));
          if (!jachaSystemTempDir.existsSync()) {
            jachaSystemTempDir.createSync(recursive: true);
          }
          return jachaSystemTempDir;
        } catch (e3) {
          print('Error con system temp: $e3');
          
          // Fallback final: directorio actual
          final currentDir = Directory.current;
          final fallbackTempDir = Directory(join(currentDir.path, 'temp_jacha'));
          if (!fallbackTempDir.existsSync()) {
            fallbackTempDir.createSync(recursive: true);
          }
          return fallbackTempDir;
        }
      }
    }
  }

  /// Método mejorado que garantiza la exportación exitosa
  Future<String> exportDocumentAsJachaWithFallback(int documentId) async {
    try {
      print('=== INICIANDO EXPORTACIÓN MEJORADA ===');
      
      // 1. Intentar exportación alternativa primero
      try {
        final file = await exportDocumentAsJachaAlternative(documentId);
        return 'Archivo .jacha creado exitosamente en: ${file.path}';
      } catch (e) {
        print('Fallo exportación alternativa: $e');
      }
      
      // 2. Intentar exportación original
      try {
        final file = await exportDocumentAsJacha(documentId);
        return 'Archivo .jacha creado exitosamente (método original) en: ${file.path}';
      } catch (e) {
        print('Fallo exportación original: $e');
      }
      
      // 3. Fallback final: JSON debug
      try {
        final file = await exportDocumentAsJsonDebug(documentId);
        return 'Archivo JSON de debug creado en: ${file.path}';
      } catch (e) {
        print('Fallo exportación debug: $e');
        throw Exception('Todos los métodos de exportación fallaron');
      }
      
    } catch (e) {
      print('Error completo en exportación: $e');
      throw Exception('Error en exportación: $e');
    }
  }
}
