import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/reception_model.dart';
import '../models/database_models.dart';
import 'database_service.dart';
import 'export_service.dart';
import 'wifi_transfer_service.dart';
import 'nfc_transfer_service.dart';

class TransferService {
  final DatabaseService _dbService = DatabaseService();
  final ExportService _exportService = ExportService();
  final WiFiTransferService _wifiService = WiFiTransferService();
  final NFCTransferService _nfcService = NFCTransferService();

  // Simulación de dispositivos disponibles para cada método
  static const Map<TransferMethod, List<Map<String, dynamic>>> _availableDevices = {
    TransferMethod.wifiDirect: [
      {'id': 'device_1', 'name': 'Samsung Galaxy A54', 'isOnline': true},
      {'id': 'device_2', 'name': 'iPhone 14', 'isOnline': true},
      {'id': 'device_3', 'name': 'Xiaomi Redmi Note 12', 'isOnline': false},
    ],
    TransferMethod.wifi: [
      {'id': 'wifi_1', 'name': 'Laptop-Ana', 'isOnline': true},
      {'id': 'wifi_2', 'name': 'PC-Carlos', 'isOnline': true},
      {'id': 'wifi_3', 'name': 'Tablet-Maria', 'isOnline': false},
      {'id': 'wifi_4', 'name': 'Phone-Pedro', 'isOnline': true},
    ],
    TransferMethod.bluetooth: [
      {'id': 'bt_1', 'name': 'Auriculares Sony', 'isOnline': true},
      {'id': 'bt_2', 'name': 'Smartphone-Luis', 'isOnline': true},
      {'id': 'bt_3', 'name': 'Laptop-Admin', 'isOnline': false},
    ],
    TransferMethod.nfc: [], // NFC es solo P2P directo
  };

  /// Obtiene la lista de dispositivos disponibles para un método específico
  List<Map<String, dynamic>> getAvailableDevices(TransferMethod method) {
    return _availableDevices[method] ?? [];
  }

  /// Simula el envío a múltiples dispositivos
  Future<Map<String, bool>> sendToMultipleDevices({
    required int documentId,
    required TransferMethod method,
    required List<String> deviceIds,
  }) async {
    try {
      print('Iniciando envío a múltiples dispositivos...');
      
      // 1. Crear archivo .jacha
      final jachaFile = await _exportService.exportDocumentAsJachaAlternative(documentId);
      print('Archivo .jacha creado: ${jachaFile.path}');
      
      // 2. Simular envío a cada dispositivo
      Map<String, bool> results = {};
      
      for (String deviceId in deviceIds) {
        print('Enviando a dispositivo: $deviceId');
        
        // Simular tiempo de transferencia
        await Future.delayed(Duration(milliseconds: 500 + (deviceId.hashCode % 1000)));
        
        // Simular éxito/fallo (90% éxito)
        final success = (deviceId.hashCode % 10) != 0;
        results[deviceId] = success;
        
        print('Resultado para $deviceId: ${success ? "Éxito" : "Fallo"}');
      }
      
      return results;
      
    } catch (e) {
      print('Error en envío múltiple: $e');
      // En caso de error, marcar todos como fallidos
      return Map.fromIterable(deviceIds, value: (device) => false);
    }
  }

  /// Simula el envío P2P directo (NFC)
  Future<bool> sendP2PDirect({
    required int documentId,
    required TransferMethod method,
  }) async {
    try {
      print('Iniciando envío P2P directo...');
      
      // 1. Crear archivo .jacha
      final jachaFile = await _exportService.exportDocumentAsJachaAlternative(documentId);
      print('Archivo .jacha creado para P2P: ${jachaFile.path}');
      
      // 2. Simular transferencia directa
      await Future.delayed(const Duration(seconds: 3));
      
      // Simular éxito (85% probabilidad)
      final success = DateTime.now().millisecond % 10 < 8;
      
      print('Resultado P2P: ${success ? "Éxito" : "Fallo"}');
      return success;
      
    } catch (e) {
      print('Error en envío P2P: $e');
      return false;
    }
  }

  /// Simula la recepción automática de un archivo
  Future<bool> simulateReceiveDocument({
    required TransferMethod method,
    String? fromDevice,
  }) async {
    try {
      print('Simulando recepción desde ${fromDevice ?? "dispositivo desconocido"}...');
      
      // Simular tiempo de recepción
      await Future.delayed(const Duration(seconds: 2));
      
      // Crear documento simulado
      final simulatedDocument = DocumentComplete(
        document: Document(
          authorId: fromDevice ?? 'unknown_sender',
          createdAt: DateTime.now(),
          title: 'Documento Recibido - ${DateTime.now().day}/${DateTime.now().month}',
          classId: 1, // Asignar a primera clase disponible
        ),
        articleBlocks: [
          ArticleBlock(
            documentId: 0, // Se asignará al guardar
            type: 'title',
            content: 'Documento Recibido via ${method.name}',
            blockOrder: 1,
          ),
          ArticleBlock(
            documentId: 0,
            type: 'paragraph',
            content: 'Este documento fue recibido desde otro dispositivo usando ${method.name}. Contenido de ejemplo para demostrar la funcionalidad de transferencia.',
            blockOrder: 2,
          ),
        ],
        questions: [
          Question(
            documentId: 0,
            type: 'multiple_choice',
            text: '¿De qué método se recibió este documento?',
            correctAnswer: method.name,
          ),
        ],
        questionOptions: {},
      );
      
      // Guardar en la base de datos local
      await _importDocumentToDatabase(simulatedDocument);
      
      print('Documento recibido e importado exitosamente');
      return true;
      
    } catch (e) {
      print('Error al simular recepción: $e');
      return false;
    }
  }

  /// Importa un archivo .jacha seleccionado por el usuario
  Future<bool> importJachaFile() async {
    try {
      print('Abriendo selector de archivos...');
      
      // Abrir selector de archivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jacha', 'json'], // Permitir tanto .jacha como .json para debug
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        print('Archivo seleccionado: ${file.path}');
        
        if (file.path.endsWith('.jacha')) {
          return await _processJachaFile(file);
        } else if (file.path.endsWith('.json')) {
          return await _processJsonFile(file);
        } else {
          throw Exception('Formato de archivo no soportado');
        }
      } else {
        print('No se seleccionó ningún archivo');
        return false;
      }
    } catch (e) {
      print('Error al importar archivo: $e');
      return false;
    }
  }

  /// Procesa un archivo .jacha y extrae su contenido
  Future<bool> _processJachaFile(File jachaFile) async {
    try {
      print('Procesando archivo .jacha...');
      
      // TODO: Implementar descompresión del archivo ZIP
      // Por ahora, simular la extracción
      await Future.delayed(const Duration(seconds: 1));
      
      // Simular documento extraído
      final extractedDocument = DocumentComplete(
        document: Document(
          authorId: 'imported_author',
          createdAt: DateTime.now(),
          title: 'Documento Importado - ${jachaFile.uri.pathSegments.last}',
          classId: 1,
        ),
        articleBlocks: [
          ArticleBlock(
            documentId: 0,
            type: 'title',
            content: 'Documento Importado desde Archivo',
            blockOrder: 1,
          ),
          ArticleBlock(
            documentId: 0,
            type: 'paragraph',
            content: 'Este documento fue importado desde un archivo .jacha. El contenido original ha sido restaurado en la base de datos local.',
            blockOrder: 2,
          ),
        ],
        questions: [],
        questionOptions: {},
      );
      
      await _importDocumentToDatabase(extractedDocument);
      return true;
      
    } catch (e) {
      print('Error al procesar archivo .jacha: $e');
      return false;
    }
  }

  /// Procesa un archivo JSON de debug
  Future<bool> _processJsonFile(File jsonFile) async {
    try {
      print('Procesando archivo JSON...');
      
      final jsonContent = await jsonFile.readAsString();
      final data = jsonDecode(jsonContent);
      
      // Verificar que es un archivo válido de Jacha Yachay
      if (data['version'] == null || data['document'] == null) {
        throw Exception('Archivo JSON no válido');
      }
      
      // Reconstruir DocumentComplete desde JSON
      final document = Document(
        authorId: data['document']['authorId'],
        createdAt: DateTime.parse(data['document']['createdAt']),
        title: data['document']['title'],
        classId: data['document']['classId'],
      );
      
      final articleBlocks = (data['articleBlocks'] as List).map((block) => 
        ArticleBlock(
          documentId: 0, // Se asignará al guardar
          type: block['type'],
          content: block['content'],
          blockOrder: block['blockOrder'],
        )
      ).toList();
      
      final questions = (data['questions'] as List).map((question) => 
        Question(
          documentId: 0,
          type: question['type'],
          text: question['text'],
          correctAnswer: question['correctAnswer'],
        )
      ).toList();
      
      final documentComplete = DocumentComplete(
        document: document,
        articleBlocks: articleBlocks,
        questions: questions,
        questionOptions: {}, // TODO: Implementar importación de opciones
      );
      
      await _importDocumentToDatabase(documentComplete);
      return true;
      
    } catch (e) {
      print('Error al procesar archivo JSON: $e');
      return false;
    }
  }

  /// Importa un documento completo a la base de datos local
  Future<void> _importDocumentToDatabase(DocumentComplete docComplete) async {
    try {
      print('Importando documento a la base de datos...');
      
      // 1. Guardar documento principal
      final documentId = await _dbService.insertDocument(docComplete.document);
      
      // 2. Guardar bloques de artículo
      for (var block in docComplete.articleBlocks) {
        final updatedBlock = ArticleBlock(
          documentId: documentId,
          type: block.type,
          content: block.content,
          blockOrder: block.blockOrder,
        );
        await _dbService.insertArticleBlock(updatedBlock);
      }
      
      // 3. Guardar preguntas
      for (var question in docComplete.questions) {
        final updatedQuestion = Question(
          documentId: documentId,
          type: question.type,
          text: question.text,
          correctAnswer: question.correctAnswer,
        );
        final questionId = await _dbService.insertQuestion(updatedQuestion);
        
        // 4. Guardar opciones de pregunta si existen
        if (docComplete.questionOptions.containsKey(question.id)) {
          for (var option in docComplete.questionOptions[question.id]!) {
            final updatedOption = QuestionOption(
              questionId: questionId,
              text: option.text,
              isCorrect: option.isCorrect,
            );
            await _dbService.insertQuestionOption(updatedOption);
          }
        }
      }
      
      print('Documento importado exitosamente con ID: $documentId');
      
    } catch (e) {
      print('Error al importar a la base de datos: $e');
      throw Exception('Error al guardar documento importado: $e');
    }
  }

  /// Simula el escaneo de dispositivos disponibles
  Stream<List<Map<String, dynamic>>> scanForDevices(TransferMethod method) async* {
    print('Escaneando dispositivos para ${method.name}...');
    
    final baseDevices = getAvailableDevices(method);
    
    // Simular escaneo en tiempo real
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      
      // Simular cambios en la disponibilidad de dispositivos
      final devices = baseDevices.map((device) {
        // Crear una copia del mapa para poder modificarlo
        final mutableDevice = Map<String, dynamic>.from(device);
        
        // Ocasionalmente cambiar el estado online/offline
        if (DateTime.now().millisecond % 30 == 0) {
          mutableDevice['isOnline'] = !mutableDevice['isOnline'];
        }
        return mutableDevice;
      }).toList();
      
      yield devices;
    }
  }

  /// Envía documento mediante terceros (compartir con otras apps)
  Future<bool> sendViaThirdParty(int documentId) async {
    try {
      print('Iniciando envío mediante terceros...');
      
      // 1. Crear archivo .jacha
      final jachaFile = await _exportService.exportDocumentAsJachaAlternative(documentId);
      print('Archivo .jacha creado para terceros: ${jachaFile.path}');
      
      // 2. Compartir archivo usando share_plus
      final result = await Share.shareXFiles(
        [XFile(jachaFile.path)],
        text: 'Documento de Jacha Yachay',
        subject: 'Compartir Tema - Jacha Yachay',
      );
      
      print('Resultado del envío mediante terceros: ${result.status}');
      return result.status == ShareResultStatus.success;
      
    } catch (e) {
      print('Error en envío mediante terceros: $e');
      return false;
    }
  }

  /// Simula que el dispositivo está visible para recepción 
  bool isVisibleForReception(TransferMethod method) {
    // En una implementación real, esto verificaría si:
    // - WiFi Direct está activo y anunciando
    // - WiFi está conectado y escuchando
    // - Bluetooth está en modo de descubrimiento  
    // - NFC está activo
    print('Dispositivo visible para recepción via ${method.name}');
    return true;
  }

  /// Simula hacer el dispositivo visible para otros
  Future<bool> makeVisibleForReception(TransferMethod method) async {
    try {
      print('Configurando visibilidad para ${method.name}...');
      
      // Simular configuración específica por método
      switch (method) {
        case TransferMethod.wifiDirect:
          await Future.delayed(const Duration(seconds: 2));
          print('WiFi Direct: Dispositivo anunciándose como grupo...');
          break;
        case TransferMethod.wifi:
          await Future.delayed(const Duration(seconds: 1));
          print('WiFi: Iniciando servidor de recepción...');
          break;
        case TransferMethod.bluetooth:
          await Future.delayed(const Duration(seconds: 3));
          print('Bluetooth: Dispositivo en modo descubrible...');
          break;
        case TransferMethod.nfc:
          await Future.delayed(const Duration(milliseconds: 500));
          print('NFC: Listo para recepción por proximidad...');
          break;
      }
      
      return true;
    } catch (e) {
      print('Error configurando visibilidad: $e');
      return false;
    }
  }

  /// Detiene la visibilidad para recepción
  Future<void> stopVisibility(TransferMethod method) async {
    print('Deteniendo visibilidad para ${method.name}...');
    
    // En implementación real detendría servicios específicos
    switch (method) {
      case TransferMethod.wifiDirect:
        print('WiFi Direct: Deteniendo anuncio de grupo...');
        break;
      case TransferMethod.wifi:
        print('WiFi: Cerrando servidor de recepción...');
        break;
      case TransferMethod.bluetooth:
        print('Bluetooth: Saliendo de modo descubrible...');
        break;
      case TransferMethod.nfc:
        print('NFC: Deteniendo escucha...');
        break;
    }
  }

  /// Inicializa los servicios de transferencia real
  Future<void> initializeRealServices() async {
    try {
      // Inicializar NFC
      await _nfcService.initialize();
      print('Servicios de transferencia real inicializados');
    } catch (e) {
      print('Error inicializando servicios reales: $e');
    }
  }

  /// Inicia el receptor WiFi real
  Future<bool> startWiFiReceiver() async {
    try {
      return await _wifiService.startReceiver();
    } catch (e) {
      print('Error iniciando receptor WiFi: $e');
      return false;
    }
  }

  /// Detiene el receptor WiFi real
  Future<void> stopWiFiReceiver() async {
    try {
      await _wifiService.stopReceiver();
    } catch (e) {
      print('Error deteniendo receptor WiFi: $e');
    }
  }

  /// Inicia el receptor NFC real
  Future<bool> startNFCReceiver() async {
    try {
      return await _nfcService.startReceiver();
    } catch (e) {
      print('Error iniciando receptor NFC: $e');
      return false;
    }
  }

  /// Detiene el receptor NFC real
  Future<void> stopNFCReceiver() async {
    try {
      await _nfcService.stopReceiver();
    } catch (e) {
      print('Error deteniendo receptor NFC: $e');
    }
  }

  /// Escanea dispositivos WiFi reales
  Future<List<Map<String, dynamic>>> scanWiFiDevices() async {
    try {
      return await _wifiService.scanForDevices();
    } catch (e) {
      print('Error escaneando dispositivos WiFi: $e');
      return [];
    }
  }

  /// Envía documento usando WiFi real
  Future<bool> sendViaWiFi({
    required int documentId,
    required String targetIP,
  }) async {
    try {
      // Exportar documento
      final exportedFile = await _exportService.exportDocumentAsJacha(documentId);
      
      // Enviar archivo
      return await _wifiService.sendFileToDevice(targetIP, exportedFile);
    } catch (e) {
      print('Error enviando via WiFi: $e');
      return false;
    }
  }

  /// Envía documento usando NFC real
  Future<bool> sendViaNFC({required int documentId}) async {
    try {
      // Exportar documento
      final exportedFile = await _exportService.exportDocumentAsJacha(documentId);
      
      // Enviar archivo
      return await _nfcService.sendFile(exportedFile);
    } catch (e) {
      print('Error enviando via NFC: $e');
      return false;
    }
  }

  /// Método unificado para el envío real basado en el método de transferencia
  Future<bool> sendDocumentReal({
    required int documentId,
    required TransferMethod method,
    String? targetDevice,
  }) async {
    switch (method) {
      case TransferMethod.wifi:
        if (targetDevice != null) {
          return await sendViaWiFi(
            documentId: documentId,
            targetIP: targetDevice,
          );
        }
        return false;
        
      case TransferMethod.nfc:
        return await sendViaNFC(documentId: documentId);
        
      case TransferMethod.wifiDirect:
      case TransferMethod.bluetooth:
        // Usar lógica simulada por ahora
        return await sendP2PDirect(
          documentId: documentId,
          method: method,
        );
    }
  }

  /// Método de debugging para WiFi
  Future<void> debugWiFiStatus() async {
    try {
      print('=== DEBUG TRANSFER SERVICE: WiFi ===');
      await _wifiService.debugNetworkInfo();
      
      // Probar obtener IP
      final ip = await _wifiService.getLocalIPAddress();
      print('IP desde TransferService: $ip');
      
      print('=== FIN DEBUG TRANSFER SERVICE ===');
    } catch (e) {
      print('Error en debug WiFi: $e');
    }
  }

  /// Realiza un diagnóstico completo del WiFi
  Future<Map<String, dynamic>> performWiFiDiagnostic() async {
    try {
      return await _wifiService.performDiagnostic();
    } catch (e) {
      print('Error en diagnóstico WiFi: $e');
      return {'error': e.toString()};
    }
  }

  /// Solicita todos los permisos necesarios para WiFi
  Future<bool> requestWiFiPermissions() async {
    try {
      return await _wifiService.requestAllPermissions();
    } catch (e) {
      print('Error solicitando permisos WiFi: $e');
      return false;
    }
  }
}
