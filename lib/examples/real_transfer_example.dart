// Ejemplo de uso de transferencias reales WiFi y NFC
// Este archivo muestra cómo integrar las funciones de transferencia real

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/transfer_service.dart';
import '../services/wifi_transfer_service.dart';
import '../services/nfc_transfer_service.dart';

class RealTransferExample {
  final TransferService _transferService = TransferService();
  final WiFiTransferService _wifiService = WiFiTransferService();
  final NFCTransferService _nfcService = NFCTransferService();

  /// Ejemplo completo de envío WiFi
  Future<bool> sendDocumentViaWiFi(int documentId) async {
    try {
      print('=== EJEMPLO: Envío WiFi Real ===');
      
      // 1. Inicializar servicios
      await _transferService.initializeRealServices();
      print('✓ Servicios inicializados');
      
      // 2. Escanear dispositivos en la red
      print('Escaneando dispositivos WiFi...');
      final devices = await _transferService.scanWiFiDevices();
      print('Dispositivos encontrados: ${devices.length}');
      
      if (devices.isEmpty) {
        print('❌ No se encontraron dispositivos');
        return false;
      }
      
      // 3. Mostrar dispositivos disponibles
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        print('  $i: ${device['name']} (${device['ip']})');
      }
      
      // 4. Enviar a todos los dispositivos (o uno específico)
      bool allSuccess = true;
      for (final device in devices) {
        print('Enviando a ${device['name']}...');
        
        final success = await _transferService.sendViaWiFi(
          documentId: documentId,
          targetIP: device['ip'],
        );
        
        if (success) {
          print('✓ Enviado exitosamente a ${device['name']}');
        } else {
          print('❌ Error enviando a ${device['name']}');
          allSuccess = false;
        }
      }
      
      return allSuccess;
      
    } catch (e) {
      print('❌ Error en envío WiFi: $e');
      return false;
    }
  }

  /// Ejemplo completo de recepción WiFi
  Future<bool> startWiFiReception() async {
    try {
      print('=== EJEMPLO: Recepción WiFi Real ===');
      
      // 1. Inicializar servicios
      await _transferService.initializeRealServices();
      print('✓ Servicios inicializados');
      
      // 2. Iniciar servidor WiFi
      print('Iniciando servidor WiFi...');
      final success = await _transferService.startWiFiReceiver();
      
      if (success) {
        print('✓ Servidor WiFi activo');
        print('  - Otros dispositivos pueden conectarse');
        print('  - IP local: ${_wifiService.localIP}');
        print('  - Esperando archivos...');
        
        // El servidor seguirá funcionando en segundo plano
        // Los archivos recibidos se procesarán automáticamente
        
        return true;
      } else {
        print('❌ Error iniciando servidor WiFi');
        return false;
      }
      
    } catch (e) {
      print('❌ Error en recepción WiFi: $e');
      return false;
    }
  }

  /// Ejemplo completo de envío NFC
  Future<bool> sendDocumentViaNFC(int documentId) async {
    try {
      print('=== EJEMPLO: Envío NFC Real ===');
      
      // 1. Inicializar servicios
      await _transferService.initializeRealServices();
      print('✓ Servicios inicializados');
      
      // 2. Verificar disponibilidad NFC
      final nfcAvailable = await _nfcService.initialize();
      if (!nfcAvailable) {
        print('❌ NFC no disponible en este dispositivo');
        return false;
      }
      print('✓ NFC disponible');
      
      // 3. Iniciar envío
      print('Preparando envío NFC...');
      print('👆 Acerque el dispositivo receptor cuando esté listo');
      
      final success = await _transferService.sendViaNFC(
        documentId: documentId,
      );
      
      if (success) {
        print('✓ Documento enviado exitosamente por NFC');
      } else {
        print('❌ Error en envío NFC');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Error en envío NFC: $e');
      return false;
    }
  }

  /// Ejemplo completo de recepción NFC
  Future<bool> startNFCReception() async {
    try {
      print('=== EJEMPLO: Recepción NFC Real ===');
      
      // 1. Inicializar servicios
      await _transferService.initializeRealServices();
      print('✓ Servicios inicializados');
      
      // 2. Verificar disponibilidad NFC
      final nfcAvailable = await _nfcService.initialize();
      if (!nfcAvailable) {
        print('❌ NFC no disponible en este dispositivo');
        return false;
      }
      print('✓ NFC disponible');
      
      // 3. Iniciar recepción
      print('Iniciando modo recepción NFC...');
      final success = await _transferService.startNFCReceiver();
      
      if (success) {
        print('✓ Modo recepción NFC activo');
        print('👆 Acerque el dispositivo emisor para recibir archivos');
        
        // El receptor seguirá funcionando hasta que se detenga manualmente
        // Los archivos recibidos se procesarán automáticamente
        
        return true;
      } else {
        print('❌ Error iniciando recepción NFC');
        return false;
      }
      
    } catch (e) {
      print('❌ Error en recepción NFC: $e');
      return false;
    }
  }

  /// Ejemplo de envío automático a todos los métodos disponibles
  Future<Map<String, bool>> sendToAllAvailableMethods(int documentId) async {
    final results = <String, bool>{};
    
    print('=== EJEMPLO: Envío Múltiple ===');
    
    // WiFi
    print('\n--- Probando WiFi ---');
    results['wifi'] = await sendDocumentViaWiFi(documentId);
    
    // NFC
    print('\n--- Probando NFC ---');
    results['nfc'] = await sendDocumentViaNFC(documentId);
    
    // Resumen
    print('\n=== RESUMEN ===');
    results.forEach((method, success) {
      final status = success ? '✓' : '❌';
      print('$status $method: ${success ? "Éxito" : "Error"}');
    });
    
    return results;
  }

  /// Detener todos los servicios
  Future<void> stopAllServices() async {
    print('Deteniendo servicios...');
    
    await _transferService.stopWiFiReceiver();
    await _transferService.stopNFCReceiver();
    
    print('✓ Servicios detenidos');
  }
}

// Ejemplo de uso en una aplicación Flutter
class RealTransferDemo extends StatefulWidget {
  @override
  _RealTransferDemoState createState() => _RealTransferDemoState();
}

class _RealTransferDemoState extends State<RealTransferDemo> {
  final RealTransferExample _example = RealTransferExample();
  String _status = 'Listo para transferir';
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Demo Transferencia Real')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Botones de acción
            ElevatedButton(
              onPressed: _isWorking ? null : () => _runExample('wifi_send'),
              child: Text('Enviar por WiFi'),
            ),
            
            ElevatedButton(
              onPressed: _isWorking ? null : () => _runExample('wifi_receive'),
              child: Text('Recibir por WiFi'),
            ),
            
            ElevatedButton(
              onPressed: _isWorking ? null : () => _runExample('nfc_send'),
              child: Text('Enviar por NFC'),
            ),
            
            ElevatedButton(
              onPressed: _isWorking ? null : () => _runExample('nfc_receive'),
              child: Text('Recibir por NFC'),
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isWorking ? null : () => _runExample('send_all'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Enviar por Todos los Métodos'),
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () => _example.stopAllServices(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Detener Servicios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runExample(String type) async {
    setState(() {
      _isWorking = true;
      _status = 'Ejecutando...';
    });

    try {
      bool success = false;
      const documentId = 1; // ID de documento de ejemplo

      switch (type) {
        case 'wifi_send':
          success = await _example.sendDocumentViaWiFi(documentId);
          break;
        case 'wifi_receive':
          success = await _example.startWiFiReception();
          break;
        case 'nfc_send':
          success = await _example.sendDocumentViaNFC(documentId);
          break;
        case 'nfc_receive':
          success = await _example.startNFCReception();
          break;
        case 'send_all':
          final results = await _example.sendToAllAvailableMethods(documentId);
          success = results.values.any((result) => result);
          break;
      }

      setState(() {
        _status = success ? 'Operación completada exitosamente' : 'Error en la operación';
      });

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isWorking = false;
      });
    }
  }

  @override
  void dispose() {
    _example.stopAllServices();
    super.dispose();
  }
}
