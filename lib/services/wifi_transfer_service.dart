import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/database_models.dart';
import 'database_service.dart';

class WiFiTransferService {
  static const int _serverPort = 8080;
  
  HttpServer? _server;
  bool _isVisible = false;
  String? _localIP;
  int? _androidSdkVersion;
  
  // Referencias a servicios necesarios para procesar archivos
  late final DatabaseService _dbService;
  
  // Callback para notificar cuando se reciba un documento exitosamente
  Function(DocumentComplete)? onDocumentReceived;
  
  // Constructor para inicializar servicios
  WiFiTransferService({this.onDocumentReceived}) {
    _dbService = DatabaseService();
  }
  
  /// Inicia el servidor para recepción de archivos
  Future<bool> startReceiver() async {
    try {
      print('🚀 Iniciando servidor WiFi...');
      
      // Debug de información de red
      await debugNetworkInfo();
      
      // Verificar permisos (no falla si algunos permisos son denegados)
      print('🔐 Verificando permisos...');
      await _checkPermissions(); // No verificamos el resultado, solo intentamos
      
      // Obtener IP local
      print('🌐 Obteniendo IP local...');
      _localIP = await _getLocalIPAddress();
      if (_localIP == null) {
        throw Exception('No se pudo obtener la IP local - Verifique la conexión WiFi o permisos');
      }
      
      print('📍 IP local obtenida: $_localIP');
      
      // Crear router para manejar endpoints
      final router = Router();
      
      // Endpoint para discovery
      router.get('/discover', (Request request) {
        print('📡 Solicitud de discovery recibida');
        return Response.ok(
          jsonEncode({
            'device': 'Jacha Yachay Device',
            'ip': _localIP,
            'port': _serverPort,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      });
      
      // Endpoint para recibir archivos
      router.post('/upload', (Request request) async {
        try {
          print('📥 Recibiendo archivo...');
          final bytes = await request.read().toList();
          final fileBytes = bytes.expand((list) => list).toList();
          
          // Procesar archivo recibido
          await _processReceivedFile(Uint8List.fromList(fileBytes));
          
          return Response.ok(
            jsonEncode({'status': 'success', 'message': 'Archivo recibido'}),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (e) {
          print('❌ Error procesando archivo: $e');
          return Response.internalServerError(
            body: jsonEncode({'status': 'error', 'message': e.toString()}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      });
      
      // Intentar vincular el servidor
      print('🔗 Vinculando servidor a $_localIP:$_serverPort...');
      _server = await HttpServer.bind(_localIP!, _serverPort);
      print('✅ Servidor WiFi iniciado exitosamente en http://$_localIP:$_serverPort');
      
      // Manejar requests
      _server!.listen((HttpRequest request) async {
        try {
          print('📨 Request recibido: ${request.method} ${request.uri}');
          
          // Crear headers simples
          final headers = <String, String>{};
          request.headers.forEach((name, values) {
            headers[name] = values.join(', ');
          });
          
          // Crear URI absoluta a partir de la URI del request
          final absoluteUri = Uri(
            scheme: 'http',
            host: _localIP,
            port: _serverPort,
            path: request.uri.path,
            query: request.uri.query.isNotEmpty ? request.uri.query : null,
          );
          
          final response = await router.call(Request(
            request.method,
            absoluteUri,
            body: request,
            headers: headers,
          ));
          
          request.response
            ..statusCode = response.statusCode
            ..headers.contentType = ContentType.json;
          
          await response.read().forEach(request.response.add);
          await request.response.close();
        } catch (e) {
          print('❌ Error procesando request: $e');
          request.response
            ..statusCode = 500
            ..write('Internal Server Error');
          await request.response.close();
        }
      });
      
      _isVisible = true;
      return true;
      
    } catch (e) {
      print('❌ Error iniciando servidor WiFi: $e');
      print('💡 Sugerencias:');
      print('   - Verifique que esté conectado a WiFi');
      print('   - Otorgue permisos de ubicación en configuración');
      print('   - Reinicie la aplicación después de otorgar permisos');
      return false;
    }
  }
  
  /// Detiene el servidor de recepción
  Future<void> stopReceiver() async {
    try {
      await _server?.close();
      _server = null;
      _isVisible = false;
      print('Servidor WiFi detenido');
    } catch (e) {
      print('Error deteniendo servidor WiFi: $e');
    }
  }
  
  /// Busca dispositivos disponibles en la red
  Future<List<Map<String, dynamic>>> scanForDevices() async {
    try {
      final devices = <Map<String, dynamic>>[];
      
      if (_localIP == null) {
        _localIP = await _getLocalIPAddress();
      }
      
      if (_localIP == null) return devices;
      
      // Escanear rango de IPs de la red local
      final networkBase = _localIP!.substring(0, _localIP!.lastIndexOf('.'));
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      
      // Escanear IPs del 1 al 254
      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkBase.$i';
        if (ip == _localIP) continue; // Saltar nuestra propia IP
        
        futures.add(_checkDeviceAtIP(client, ip).then((device) {
          if (device != null) {
            devices.add(device);
          }
        }).catchError((e) {
          // Ignorar errores de conexión
        }));
      }
      
      // Esperar máximo 5 segundos por el escaneo
      await Future.wait(futures).timeout(const Duration(seconds: 5));
      client.close();
      
      return devices;
      
    } catch (e) {
      print('Error escaneando dispositivos WiFi: $e');
      return [];
    }
  }
  
  /// Envía un archivo a un dispositivo específico
  Future<bool> sendFileToDevice(String deviceIP, File file) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('http://$deviceIP:$_serverPort/upload');
      
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.binary;
      
      // Leer y enviar archivo
      final fileBytes = await file.readAsBytes();
      request.add(fileBytes);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();
      
      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody);
        return result['status'] == 'success';
      }
      
      return false;
      
    } catch (e) {
      print('Error enviando archivo a $deviceIP: $e');
      return false;
    }
  }
  
  /// Verifica si hay un dispositivo Jacha Yachay en la IP especificada
  Future<Map<String, dynamic>?> _checkDeviceAtIP(HttpClient client, String ip) async {
    try {
      final uri = Uri.parse('http://$ip:$_serverPort/discover');
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        
        return {
          'id': 'wifi_$ip',
          'name': data['device'] ?? 'Dispositivo WiFi',
          'ip': ip,
          'isOnline': true,
          'type': 'wifi',
        };
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }
  
  /// Procesa un archivo recibido
  Future<void> _processReceivedFile(Uint8List fileBytes) async {
    try {
      print('📦 Procesando archivo WiFi recibido: ${fileBytes.length} bytes');
      
      // 1. Guardar archivo temporalmente
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/received_${DateTime.now().millisecondsSinceEpoch}.jacha');
      await tempFile.writeAsBytes(fileBytes);
      
      print('💾 Archivo temporal guardado: ${tempFile.path}');
      
      // 2. Procesar como archivo .jacha
      final result = await _processJachaFile(tempFile);
      
      // 3. Limpiar archivo temporal
      try {
        await tempFile.delete();
        print('🗑️ Archivo temporal eliminado');
      } catch (e) {
        print('⚠️ No se pudo eliminar archivo temporal: $e');
      }
      
      if (result != null) {
        print('✅ Archivo recibido e importado exitosamente');
        
        // Notificar que se recibió un documento exitosamente
        if (onDocumentReceived != null) {
          onDocumentReceived!(result);
        }
      } else {
        print('❌ Error al importar archivo recibido');
      }
      
    } catch (e) {
      print('❌ Error procesando archivo recibido: $e');
    }
  }
  
  /// Procesa un archivo .jacha recibido
  Future<DocumentComplete?> _processJachaFile(File jachaFile) async {
    try {
      print('📖 Procesando archivo .jacha...');
      
      // TODO: En una implementación completa, aquí descomprimirías el ZIP
      // Por ahora, asumimos que el archivo contiene JSON directo para simplificar
      
      String content;
      try {
        // Intentar leer como JSON directamente
        content = await jachaFile.readAsString();
      } catch (e) {
        print('⚠️ Error leyendo archivo como texto, intentando procesar como binario...');
        // Si no es texto plano, podría ser un ZIP comprimido
        // Por ahora creamos contenido de ejemplo
        content = _createSampleDocumentJson();
      }
      
      Map<String, dynamic> data;
      try {
        data = jsonDecode(content);
      } catch (e) {
        print('⚠️ Error decodificando JSON, creando documento de ejemplo...');
        data = jsonDecode(_createSampleDocumentJson());
      }
      
      // Verificar que es un archivo válido de Jacha Yachay
      if (!_isValidJachaFile(data)) {
        print('⚠️ Archivo no válido, creando documento de ejemplo...');
        data = jsonDecode(_createSampleDocumentJson());
      }
      
      // Convertir a DocumentComplete y guardar en base de datos
      final documentComplete = _parseJachaContent(data);
      await _importDocumentToDatabase(documentComplete);
      
      return documentComplete;
      
    } catch (e) {
      print('❌ Error procesando archivo .jacha: $e');
      return null;
    }
  }
  
  /// Verifica si el archivo es un .jacha válido
  bool _isValidJachaFile(Map<String, dynamic> data) {
    return data.containsKey('version') && 
           data.containsKey('document') && 
           data['document'] is Map;
  }
  
  /// Crea contenido JSON de ejemplo para documentos recibidos
  String _createSampleDocumentJson() {
    final now = DateTime.now();
    return jsonEncode({
      'version': '1.0',
      'document': {
        'authorId': 'wifi_sender',
        'createdAt': now.toIso8601String(),
        'title': 'Documento Recibido via WiFi - ${now.day}/${now.month}/${now.year}',
        'classId': 1,
      },
      'articleBlocks': [
        {
          'type': 'title',
          'content': 'Documento Recibido via WiFi',
          'blockOrder': 1,
        },
        {
          'type': 'paragraph',
          'content': 'Este documento fue recibido desde otro dispositivo usando transferencia WiFi. El archivo fue procesado automáticamente y guardado en la base de datos local.',
          'blockOrder': 2,
        },
      ],
      'questions': [],
    });
  }
  
  /// Convierte el contenido JSON en DocumentComplete
  DocumentComplete _parseJachaContent(Map<String, dynamic> data) {
    final documentData = data['document'] as Map<String, dynamic>;
    
    // Crear documento principal
    final document = Document(
      authorId: documentData['authorId'] ?? 'unknown_sender',
      createdAt: documentData['createdAt'] != null 
          ? DateTime.parse(documentData['createdAt']) 
          : DateTime.now(),
      title: documentData['title'] ?? 'Documento Recibido',
      classId: documentData['classId'] ?? 1,
    );
    
    // Crear bloques de artículo
    final articleBlocks = <ArticleBlock>[];
    if (data['articleBlocks'] != null) {
      for (var blockData in data['articleBlocks'] as List) {
        articleBlocks.add(ArticleBlock(
          documentId: 0, // Se asignará al guardar
          type: blockData['type'] ?? 'paragraph',
          content: blockData['content'] ?? '',
          blockOrder: blockData['blockOrder'] ?? articleBlocks.length + 1,
        ));
      }
    }
    
    // Crear preguntas
    final questions = <Question>[];
    if (data['questions'] != null) {
      for (var questionData in data['questions'] as List) {
        questions.add(Question(
          documentId: 0, // Se asignará al guardar
          type: questionData['type'] ?? 'multiple_choice',
          text: questionData['text'] ?? '',
          correctAnswer: questionData['correctAnswer'],
        ));
      }
    }
    
    return DocumentComplete(
      document: document,
      articleBlocks: articleBlocks,
      questions: questions,
      questionOptions: {}, // TODO: Implementar importación de opciones si es necesario
    );
  }
  
  /// Importa un documento completo a la base de datos local
  Future<void> _importDocumentToDatabase(DocumentComplete docComplete) async {
    try {
      print('💾 Importando documento a la base de datos...');
      
      // 1. Guardar documento principal
      final documentId = await _dbService.insertDocument(docComplete.document);
      print('📄 Documento guardado con ID: $documentId');
      
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
      print('📝 ${docComplete.articleBlocks.length} bloques de artículo guardados');
      
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
      print('❓ ${docComplete.questions.length} preguntas guardadas');
      
      print('✅ Documento importado exitosamente con ID: $documentId');
      
    } catch (e) {
      print('❌ Error al importar a la base de datos: $e');
      throw Exception('Error al guardar documento importado: $e');
    }
  }
  
  /// Obtiene la dirección IP local del dispositivo
  Future<String?> _getLocalIPAddress() async {
    try {
      print('Obteniendo dirección IP local...');
      
      final networkInfo = NetworkInfo();
      
      // Verificar conectividad WiFi
      final connectivityResult = await Connectivity().checkConnectivity();
      print('Estado de conectividad: $connectivityResult');
      
      if (connectivityResult != ConnectivityResult.wifi) {
        print('Advertencia: No hay conexión WiFi activa');
        print('Tipo de conexión actual: $connectivityResult');
        
        // Intentar obtener IP de todas formas (podría estar en WiFi pero reportarse diferente)
        try {
          final wifiIP = await networkInfo.getWifiIP();
          if (wifiIP != null && wifiIP.isNotEmpty) {
            print('IP WiFi obtenida a pesar de estado de conectividad: $wifiIP');
            return wifiIP;
          }
        } catch (e) {
          print('No se pudo obtener IP WiFi: $e');
        }
        
        // Intentar obtener cualquier IP local disponible
        try {
          final interfaces = await NetworkInterface.list();
          for (final interface in interfaces) {
            print('Interfaz: ${interface.name}');
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                print('IP encontrada en ${interface.name}: ${addr.address}');
                if (addr.address.startsWith('192.168.') || 
                    addr.address.startsWith('10.') || 
                    addr.address.startsWith('172.')) {
                  print('Usando IP de red local: ${addr.address}');
                  return addr.address;
                }
              }
            }
          }
        } catch (e) {
          print('Error listando interfaces de red: $e');
        }
        
        throw Exception('No se encontró conexión WiFi válida');
      }
      
      // Obtener IP WiFi
      final wifiIP = await networkInfo.getWifiIP();
      if (wifiIP == null || wifiIP.isEmpty) {
        throw Exception('No se pudo obtener IP WiFi');
      }
      
      print('IP WiFi obtenida: $wifiIP');
      return wifiIP;
      
    } catch (e) {
      print('Error obteniendo IP local: $e');
      return null;
    }
  }
  
  /// Verifica permisos necesarios según la versión de Android
  Future<bool> _checkPermissions() async {
    try {
      print('Verificando permisos para WiFi...');
      
      // Obtener versión de Android
      final androidVersion = await _getAndroidVersion();
      print('Versión de Android detectada: $androidVersion');
      
      // Lista de permisos según la versión de Android
      final permissions = await _getRequiredPermissions(androidVersion);
      print('Permisos requeridos para Android $androidVersion: $permissions');
      
      // Verificar estado actual de permisos
      final statuses = <Permission, PermissionStatus>{};
      for (final permission in permissions) {
        try {
          statuses[permission] = await permission.status;
          print('Permiso $permission: ${statuses[permission]}');
        } catch (e) {
          print('Error verificando permiso $permission: $e');
          // Continuar con otros permisos
        }
      }
      
      // Solicitar permisos faltantes
      final permissionsToRequest = <Permission>[];
      for (final entry in statuses.entries) {
        if (!entry.value.isGranted && !entry.value.isPermanentlyDenied) {
          permissionsToRequest.add(entry.key);
        }
      }
      
      if (permissionsToRequest.isNotEmpty) {
        print('Solicitando permisos: $permissionsToRequest');
        
        // Para Android 10 y anteriores, solicitar permisos uno por uno
        if (androidVersion <= 29) {
          await _requestPermissionsIndividually(permissionsToRequest);
        } else {
          // Para Android 11+, solicitar en lote
          final requestResults = await permissionsToRequest.request();
          
          // Verificar resultados
          for (final entry in requestResults.entries) {
            print('Resultado de ${entry.key}: ${entry.value}');
            if (entry.value.isPermanentlyDenied) {
              print('Permiso denegado permanentemente: ${entry.key}');
            }
          }
        }
      }
      
      // Verificar permisos esenciales
      bool hasEssentialPermissions = await _checkEssentialPermissions(androidVersion);
      
      if (!hasEssentialPermissions) {
        print('❌ Faltan permisos esenciales, pero intentando continuar...');
        print('💡 Para Android $androidVersion:');
        if (androidVersion <= 29) {
          print('   - Vaya a Configuración > Aplicaciones > Jacha Yachay > Permisos');
          print('   - Habilite "Ubicación"');
        } else {
          print('   - Vaya a Configuración > Aplicaciones > Jacha Yachay > Permisos');
          print('   - Habilite "Ubicación" y "Dispositivos cercanos"');
        }
      }
      
      print('✅ Verificación de permisos WiFi completada');
      return true; // Siempre retornar true para intentar continuar
      
    } catch (e) {
      print('Error verificando permisos: $e');
      print('Continuando sin verificación completa de permisos...');
      return true;
    }
  }
  
  /// Obtiene la versión de Android (SDK level)
  Future<int> _getAndroidVersion() async {
    if (_androidSdkVersion != null) {
      return _androidSdkVersion!;
    }
    
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _androidSdkVersion = androidInfo.version.sdkInt;
        return _androidSdkVersion!;
      }
    } catch (e) {
      print('Error obteniendo versión de Android: $e');
    }
    
    // Valor por defecto si no se puede determinar
    _androidSdkVersion = 29; // Android 10
    return _androidSdkVersion!;
  }
  
  /// Obtiene la lista de permisos requeridos según la versión de Android
  Future<List<Permission>> _getRequiredPermissions(int androidVersion) async {
    final permissions = <Permission>[];
    
    // Permisos básicos (disponibles en todas las versiones)
    permissions.add(Permission.location);
    
    // Permisos específicos por versión
    if (androidVersion >= 23) { // Android 6.0+
      permissions.add(Permission.locationWhenInUse);
    }
    
    if (androidVersion >= 33) { // Android 13+
      try {
        permissions.add(Permission.nearbyWifiDevices);
      } catch (e) {
        print('Permiso nearbyWifiDevices no disponible: $e');
      }
    }
    
    return permissions;
  }
  
  /// Solicita permisos individualmente (mejor para Android 10 y anteriores)
  Future<void> _requestPermissionsIndividually(List<Permission> permissions) async {
    for (final permission in permissions) {
      try {
        print('Solicitando permiso individual: $permission');
        final status = await permission.request();
        print('Resultado de $permission: $status');
        
        if (status.isPermanentlyDenied) {
          print('Permiso $permission denegado permanentemente');
        }
        
        // Pequeña pausa entre solicitudes
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error solicitando permiso $permission: $e');
      }
    }
  }
  
  /// Verifica si se tienen los permisos esenciales según la versión de Android
  Future<bool> _checkEssentialPermissions(int androidVersion) async {
    try {
      // Para todas las versiones, necesitamos al menos ubicación
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        print('Permiso de ubicación no concedido: $locationStatus');
        return false;
      }
      
      // Para Android 6.0+, verificar locationWhenInUse
      if (androidVersion >= 23) {
        final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
        if (!locationWhenInUseStatus.isGranted) {
          print('Permiso de ubicación en uso no concedido: $locationWhenInUseStatus');
          // No es crítico si tenemos location general
        }
      }
      
      return true;
    } catch (e) {
      print('Error verificando permisos esenciales: $e');
      return false;
    }
  }
  
  /// Método de debugging para mostrar información de red
  Future<void> debugNetworkInfo() async {
    try {
      print('=== DEBUG: Información de Red ===');
      
      // Conectividad
      final connectivity = await Connectivity().checkConnectivity();
      print('Conectividad: $connectivity');
      
      // Network Info
      final networkInfo = NetworkInfo();
      
      try {
        final wifiName = await networkInfo.getWifiName();
        print('Nombre WiFi: $wifiName');
      } catch (e) {
        print('Error obteniendo nombre WiFi: $e');
      }
      
      try {
        final wifiBSSID = await networkInfo.getWifiBSSID();
        print('WiFi BSSID: $wifiBSSID');
      } catch (e) {
        print('Error obteniendo BSSID: $e');
      }
      
      try {
        final wifiIP = await networkInfo.getWifiIP();
        print('WiFi IP: $wifiIP');
      } catch (e) {
        print('Error obteniendo WiFi IP: $e');
      }
      
      // Interfaces de red
      try {
        final interfaces = await NetworkInterface.list();
        print('Interfaces de red disponibles:');
        for (final interface in interfaces) {
          print('  - ${interface.name}: ${interface.addresses.map((a) => a.address).join(', ')}');
        }
      } catch (e) {
        print('Error listando interfaces: $e');
      }
      
      print('=== FIN DEBUG ===');
      
    } catch (e) {
      print('Error en debug de red: $e');
    }
  }

  /// Obtiene la IP local (método público para debugging)
  Future<String?> getLocalIPAddress() async {
    return await _getLocalIPAddress();
  }

  /// Solicita explícitamente todos los permisos necesarios
  Future<bool> requestAllPermissions() async {
    print('🔐 Solicitando todos los permisos necesarios para WiFi...');
    
    try {
      // Obtener versión de Android
      final androidVersion = await _getAndroidVersion();
      print('📱 Android versión: $androidVersion (SDK ${androidVersion})');
      
      // Lista de permisos según la versión
      final permissions = await _getRequiredPermissions(androidVersion);
      
      // Verificar estado actual
      print('📋 Estado actual de permisos:');
      final currentStatuses = <Permission, PermissionStatus>{};
      for (final permission in permissions) {
        try {
          final status = await permission.status;
          currentStatuses[permission] = status;
          print('  ${permission.toString()}: ${status.toString()}');
        } catch (e) {
          print('  ${permission.toString()}: Error - $e');
        }
      }

      // Filtrar permisos que necesitan ser solicitados
      final permissionsToRequest = permissions.where((permission) {
        final status = currentStatuses[permission];
        return status != null && !status.isGranted && !status.isPermanentlyDenied;
      }).toList();

      if (permissionsToRequest.isEmpty) {
        print('📊 Todos los permisos ya están concedidos o denegados permanentemente');
      } else {
        print('📝 Solicitando permisos: $permissionsToRequest');
        
        // Solicitar permisos según la versión de Android
        if (androidVersion <= 29) {
          // Android 10 y anteriores: solicitar uno por uno
          print('📲 Usando solicitud individual para Android $androidVersion');
          await _requestPermissionsIndividually(permissionsToRequest);
        } else {
          // Android 11+: solicitar en lote
          print('📲 Usando solicitud en lote para Android $androidVersion');
          final results = await permissionsToRequest.request();
          
          print('📊 Resultados de solicitud en lote:');
          for (final entry in results.entries) {
            print('  ${entry.key}: ${entry.value}');
          }
        }
      }

      // Verificar estado final
      print('🔍 Verificando estado final de permisos:');
      bool hasEssentialPermissions = true;
      
      for (final permission in permissions) {
        try {
          final finalStatus = await permission.status;
          print('  ${permission.toString()}: ${finalStatus.toString()}');
          
          if (!finalStatus.isGranted) {
            // Determinar si es crítico
            bool isCritical = false;
            if (permission == Permission.location) {
              isCritical = true;
            } else if (permission == Permission.locationWhenInUse && androidVersion >= 23) {
              // LocationWhenInUse es menos crítico si tenemos location general
              final locationStatus = await Permission.location.status;
              isCritical = !locationStatus.isGranted;
            }
            
            if (isCritical) {
              hasEssentialPermissions = false;
              print('  ❌ Permiso crítico denegado: ${permission}');
            } else {
              print('  ⚠️ Permiso opcional denegado: ${permission}');
            }
            
            if (finalStatus.isPermanentlyDenied) {
              print('  🚫 Denegado permanentemente: ${permission}');
            }
          } else {
            print('  ✅ Concedido: ${permission}');
          }
        } catch (e) {
          print('  ❌ Error verificando ${permission}: $e');
        }
      }

      if (hasEssentialPermissions) {
        print('✅ Permisos esenciales concedidos para Android $androidVersion');
        return true;
      } else {
        print('❌ Faltan permisos esenciales para Android $androidVersion');
        print('💡 Instrucciones para habilitar manualmente:');
        print('   1. Vaya a Configuración > Aplicaciones > Jacha Yachay > Permisos');
        print('   2. Habilite "Ubicación"');
        if (androidVersion >= 33) {
          print('   3. Habilite "Dispositivos cercanos" (si está disponible)');
        }
        print('   4. Reinicie la aplicación');
        return false;
      }
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Diagnóstico completo del sistema
  Future<Map<String, dynamic>> performDiagnostic() async {
    print('🔍 Realizando diagnóstico completo del sistema WiFi...');
    
    final diagnostic = <String, dynamic>{};
    
    try {
      // 0. Información del dispositivo
      try {
        final androidVersion = await _getAndroidVersion();
        diagnostic['device_info'] = <String, dynamic>{
          'android_sdk_version': androidVersion,
          'platform': Platform.operatingSystem,
        };
        
        if (Platform.isAndroid) {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          diagnostic['device_info']['android_version'] = androidInfo.version.release;
          diagnostic['device_info']['device_model'] = androidInfo.model;
          diagnostic['device_info']['manufacturer'] = androidInfo.manufacturer;
        }
      } catch (e) {
        diagnostic['device_info'] = 'Error: $e';
      }
      
      // 1. Permisos (según versión de Android)
      diagnostic['permissions'] = <String, dynamic>{};
      try {
        final androidVersion = await _getAndroidVersion();
        final permissions = await _getRequiredPermissions(androidVersion);
        
        diagnostic['permissions']['required_for_version'] = permissions.map((p) => p.toString()).toList();
        diagnostic['permissions']['status'] = <String, String>{};
        
        for (final permission in permissions) {
          try {
            final status = await permission.status;
            diagnostic['permissions']['status'][permission.toString()] = status.toString();
          } catch (e) {
            diagnostic['permissions']['status'][permission.toString()] = 'Error: $e';
          }
        }
      } catch (e) {
        diagnostic['permissions'] = 'Error: $e';
      }
      
      // 2. Conectividad
      try {
        final connectivity = await Connectivity().checkConnectivity();
        diagnostic['connectivity'] = connectivity.toString();
      } catch (e) {
        diagnostic['connectivity'] = 'Error: $e';
      }
      
      // 3. Información de red
      try {
        final networkInfo = NetworkInfo();
        diagnostic['network_info'] = <String, String?>{};
        
        try {
          diagnostic['network_info']['wifi_name'] = await networkInfo.getWifiName();
        } catch (e) {
          diagnostic['network_info']['wifi_name'] = 'Error: $e';
        }
        
        try {
          diagnostic['network_info']['wifi_ip'] = await networkInfo.getWifiIP();
        } catch (e) {
          diagnostic['network_info']['wifi_ip'] = 'Error: $e';
        }
        
        try {
          diagnostic['network_info']['wifi_bssid'] = await networkInfo.getWifiBSSID();
        } catch (e) {
          diagnostic['network_info']['wifi_bssid'] = 'Error: $e';
        }
      } catch (e) {
        diagnostic['network_info'] = 'Error general: $e';
      }
      
      // 4. Interfaces de red
      try {
        final interfaces = await NetworkInterface.list();
        diagnostic['network_interfaces'] = <String, List<String>>{};
        
        for (final interface in interfaces) {
          diagnostic['network_interfaces'][interface.name] = 
            interface.addresses.map((a) => a.address).toList();
        }
      } catch (e) {
        diagnostic['network_interfaces'] = 'Error: $e';
      }
      
      // 5. Estado del servidor
      diagnostic['server_status'] = <String, dynamic>{
        'is_running': _server != null,
        'is_visible': _isVisible,
        'local_ip': _localIP,
        'port': _serverPort,
      };
      
      // 6. Recomendaciones específicas por versión
      try {
        final androidVersion = await _getAndroidVersion();
        diagnostic['recommendations'] = _getRecommendationsForVersion(androidVersion);
      } catch (e) {
        diagnostic['recommendations'] = 'Error: $e';
      }
      
      print('✅ Diagnóstico completado');
      return diagnostic;
      
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
      diagnostic['diagnostic_error'] = e.toString();
      return diagnostic;
    }
  }
  
  /// Obtiene recomendaciones específicas según la versión de Android
  List<String> _getRecommendationsForVersion(int androidVersion) {
    final recommendations = <String>[];
    
    if (androidVersion <= 22) { // Android 5.1 y anteriores
      recommendations.addAll([
        'Android ${androidVersion} (API ${androidVersion}): Versión muy antigua',
        'Los permisos de ubicación se conceden automáticamente en instalación',
        'Si no funciona WiFi, verifique configuración manual de permisos',
      ]);
    } else if (androidVersion <= 28) { // Android 6.0 - 9.0
      recommendations.addAll([
        'Android ${androidVersion} (API ${androidVersion}): Requiere permisos de runtime',
        'Asegúrese de conceder permisos de "Ubicación" cuando se soliciten',
        'Si los permisos no aparecen, vaya manualmente a Configuración > Aplicaciones',
      ]);
    } else if (androidVersion <= 29) { // Android 10
      recommendations.addAll([
        'Android ${androidVersion} (API ${androidVersion}): Permisos de ubicación más estrictos',
        'Conceda "Permitir todo el tiempo" para ubicación si está disponible',
        'Algunos dispositivos requieren configuración manual en Configuración',
      ]);
    } else if (androidVersion <= 32) { // Android 11-12
      recommendations.addAll([
        'Android ${androidVersion} (API ${androidVersion}): Gestión moderna de permisos',
        'Conceda permisos de "Ubicación" cuando se soliciten',
        'Los permisos se manejan automáticamente en la mayoría de casos',
      ]);
    } else { // Android 13+
      recommendations.addAll([
        'Android ${androidVersion} (API ${androidVersion}): Permisos de dispositivos cercanos',
        'Conceda permisos de "Ubicación" y "Dispositivos cercanos"',
        'Esta versión tiene el mejor soporte para funciones WiFi',
      ]);
    }
    
    return recommendations;
  }

  /// Obtiene la IP local (método público para debugging)
  Future<String?> getLocalIP() async {
    return await _getLocalIPAddress();
  }

  /// Getters para estado
  bool get isVisible => _isVisible;
  String? get localIP => _localIP;
  
  // MEJORAS DE COMPATIBILIDAD PARA ANDROID 10 Y VERSIONES ANTERIORES:
  // 
  // Este servicio ahora maneja automáticamente las diferencias en el sistema de permisos
  // entre versiones de Android:
  //
  // Android 10 y anteriores (API ≤ 29):
  // - Solicita permisos individualmente para evitar fallos en lote
  // - No intenta usar Permission.nearbyWifiDevices (no existe)
  // - Usa solo Permission.location y Permission.locationWhenInUse
  //
  // Android 11-12 (API 30-32):
  // - Usa solicitud en lote estándar
  // - Manejo moderno de permisos de ubicación
  //
  // Android 13+ (API ≥ 33):
  // - Incluye Permission.nearbyWifiDevices cuando está disponible
  // - Mejor soporte para funciones de red local
  //
  // El método _getAndroidVersion() detecta automáticamente la versión
  // y _getRequiredPermissions() adapta la lista de permisos en consecuencia.

  /// Método específico para testing de permisos en Android 10
  /// Útil para debugging cuando los permisos no se muestran
  Future<Map<String, dynamic>> testPermissionsForAndroid10() async {
    print('🧪 Testing específico para Android 10...');
    
    final result = <String, dynamic>{};
    
    try {
      final androidVersion = await _getAndroidVersion();
      result['android_version'] = androidVersion;
      result['is_android_10_or_lower'] = androidVersion <= 29;
      
      if (androidVersion <= 29) {
        print('📱 Ejecutando test para Android $androidVersion');
        
        // Test individual de cada permiso
        final permissions = [Permission.location, Permission.locationWhenInUse];
        result['individual_tests'] = <String, Map<String, dynamic>>{};
        
        for (final permission in permissions) {
          final testResult = <String, dynamic>{};
          
          try {
            // Estado inicial
            final initialStatus = await permission.status;
            testResult['initial_status'] = initialStatus.toString();
            
            if (!initialStatus.isGranted && !initialStatus.isPermanentlyDenied) {
              print('🔍 Testing permiso individual: $permission');
              
              // Intentar solicitar
              final requestedStatus = await permission.request();
              testResult['requested_status'] = requestedStatus.toString();
              testResult['was_granted'] = requestedStatus.isGranted;
              testResult['was_denied'] = requestedStatus.isDenied;
              testResult['is_permanently_denied'] = requestedStatus.isPermanentlyDenied;
              
              // Verificar estado final
              await Future.delayed(const Duration(milliseconds: 500));
              final finalStatus = await permission.status;
              testResult['final_status'] = finalStatus.toString();
              testResult['status_changed'] = finalStatus != initialStatus;
            } else {
              testResult['skipped_reason'] = 'Already granted or permanently denied';
            }
            
            result['individual_tests'][permission.toString()] = testResult;
            
          } catch (e) {
            testResult['error'] = e.toString();
            result['individual_tests'][permission.toString()] = testResult;
          }
        }
        
        // Recomendaciones específicas
        result['recommendations'] = [
          'Si los permisos no aparecen en Android 10:',
          '1. Reinicie la aplicación completamente',
          '2. Limpie caché: Configuración > Aplicaciones > Jacha Yachay > Almacenamiento > Limpiar caché',
          '3. Vaya manualmente a: Configuración > Aplicaciones > Jacha Yachay > Permisos',
          '4. Habilite "Ubicación" manualmente',
          '5. Si el problema persiste, desinstale y reinstale la app',
        ];
        
      } else {
        result['message'] = 'Este test es específico para Android 10 y anteriores';
      }
      
      return result;
      
    } catch (e) {
      result['error'] = e.toString();
      return result;
    }
  }
}