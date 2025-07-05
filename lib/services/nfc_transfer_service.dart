import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/foundation.dart';

class NFCTransferService {
  static const int _maxChunkSize = 8192; // 8KB por chunk (limitación NFC)
  
  bool _isAvailable = false;
  bool _isScanning = false;
  bool _isWriting = false;
  
  /// Inicializa el servicio NFC
  Future<bool> initialize() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      
      if (!_isAvailable) {
        print('NFC no está disponible en este dispositivo');
        return false;
      }
      
      print('NFC inicializado correctamente');
      return true;
      
    } catch (e) {
      print('Error inicializando NFC: $e');
      return false;
    }
  }
  
  /// Inicia modo de recepción NFC
  Future<bool> startReceiver() async {
    if (!_isAvailable || _isScanning) return false;
    
    try {
      _isScanning = true;
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            await _handleReceivedTag(tag);
          } catch (e) {
            print('Error procesando tag NFC: $e');
          }
        },
      );
      
      print('NFC listo para recibir datos');
      return true;
      
    } catch (e) {
      print('Error iniciando recepción NFC: $e');
      _isScanning = false;
      return false;
    }
  }
  
  /// Detiene la recepción NFC
  Future<void> stopReceiver() async {
    try {
      await NfcManager.instance.stopSession();
      _isScanning = false;
      print('Recepción NFC detenida');
    } catch (e) {
      print('Error deteniendo recepción NFC: $e');
    }
  }
  
  /// Envía un archivo mediante NFC
  Future<bool> sendFile(File file) async {
    if (!_isAvailable || _isWriting) return false;
    
    try {
      _isWriting = true;
      
      // Leer archivo
      final fileBytes = await file.readAsBytes();
      final fileData = {
        'type': 'jacha_document',
        'filename': file.path.split('/').last,
        'size': fileBytes.length,
        'data': base64Encode(fileBytes),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final jsonData = jsonEncode(fileData);
      final dataBytes = utf8.encode(jsonData);
      
      // Verificar tamaño (NFC tiene limitaciones)
      if (dataBytes.length > _maxChunkSize) {
        return await _sendLargeFile(dataBytes);
      } else {
        return await _sendSmallFile(dataBytes);
      }
      
    } catch (e) {
      print('Error enviando archivo NFC: $e');
      return false;
    } finally {
      _isWriting = false;
    }
  }
  
  /// Envía archivos pequeños en una sola operación
  Future<bool> _sendSmallFile(Uint8List data) async {
    try {
      bool success = false;
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            
            if (ndef == null) {
              print('Tag NFC no soporta NDEF');
              return;
            }
            
            if (!ndef.isWritable) {
              print('Tag NFC no es escribible');
              return;
            }
            
            // Verificar capacidad
            if (data.length > ndef.maxSize) {
              print('Archivo demasiado grande para el tag NFC');
              return;
            }
            
            // Crear mensaje NDEF
            final record = NdefRecord.createMime(
              'application/jacha-yachay',
              data,
            );
            
            final message = NdefMessage([record]);
            
            // Escribir al tag
            await ndef.write(message);
            success = true;
            
            print('Archivo enviado exitosamente por NFC');
            
          } catch (e) {
            print('Error escribiendo en tag NFC: $e');
          }
        },
      );
      
      return success;
      
    } catch (e) {
      print('Error en envío NFC: $e');
      return false;
    }
  }
  
  /// Envía archivos grandes divididos en chunks
  Future<bool> _sendLargeFile(Uint8List data) async {
    try {
      // Dividir en chunks
      final chunks = <Uint8List>[];
      final chunkCount = (data.length / _maxChunkSize).ceil();
      
      for (int i = 0; i < chunkCount; i++) {
        final start = i * _maxChunkSize;
        final end = (start + _maxChunkSize < data.length) 
            ? start + _maxChunkSize 
            : data.length;
        
        final chunkData = {
          'type': 'jacha_chunk',
          'chunk_index': i,
          'total_chunks': chunkCount,
          'data': base64Encode(data.sublist(start, end)),
        };
        
        chunks.add(utf8.encode(jsonEncode(chunkData)));
      }
      
      // Enviar cada chunk
      for (int i = 0; i < chunks.length; i++) {
        print('Enviando chunk ${i + 1} de ${chunks.length}');
        
        final success = await _sendChunk(chunks[i], i + 1, chunks.length);
        if (!success) {
          print('Error enviando chunk $i');
          return false;
        }
        
        // Esperar entre chunks
        await Future.delayed(const Duration(seconds: 2));
      }
      
      return true;
      
    } catch (e) {
      print('Error enviando archivo grande por NFC: $e');
      return false;
    }
  }
  
  /// Envía un chunk individual
  Future<bool> _sendChunk(Uint8List chunkData, int current, int total) async {
    try {
      bool success = false;
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            
            if (ndef?.isWritable == true) {
              final record = NdefRecord.createMime(
                'application/jacha-chunk',
                chunkData,
              );
              
              await ndef!.write(NdefMessage([record]));
              success = true;
              
              print('Chunk $current/$total enviado');
            }
            
          } catch (e) {
            print('Error enviando chunk: $e');
          }
        },
      );
      
      return success;
      
    } catch (e) {
      print('Error en envío de chunk: $e');
      return false;
    }
  }
  
  /// Maneja un tag NFC recibido
  Future<void> _handleReceivedTag(NfcTag tag) async {
    try {
      final ndef = Ndef.from(tag);
      
      if (ndef?.cachedMessage == null) {
        print('Tag NFC sin datos NDEF');
        return;
      }
      
      final message = ndef!.cachedMessage!;
      
      for (final record in message.records) {
        if (record.typeNameFormat == NdefTypeNameFormat.media) {
          final mimeType = utf8.decode(record.type);
          
          if (mimeType == 'application/jacha-yachay') {
            await _processReceivedFile(record.payload);
          } else if (mimeType == 'application/jacha-chunk') {
            await _processReceivedChunk(record.payload);
          }
        }
      }
      
    } catch (e) {
      print('Error procesando tag NFC recibido: $e');
    }
  }
  
  /// Procesa un archivo completo recibido
  Future<void> _processReceivedFile(Uint8List payload) async {
    try {
      final jsonData = utf8.decode(payload);
      final data = jsonDecode(jsonData);
      
      if (data['type'] == 'jacha_document') {
        final fileBytes = base64Decode(data['data']);
        
        print('Archivo NFC recibido: ${data['filename']} (${fileBytes.length} bytes)');
        
        // TODO: Integrar con TransferService para procesar archivo
        // await _transferService._processJachaFile(tempFile);
      }
      
    } catch (e) {
      print('Error procesando archivo NFC: $e');
    }
  }
  
  /// Procesa un chunk de archivo recibido
  Future<void> _processReceivedChunk(Uint8List payload) async {
    try {
      final jsonData = utf8.decode(payload);
      final data = jsonDecode(jsonData);
      
      if (data['type'] == 'jacha_chunk') {
        final chunkIndex = data['chunk_index'] as int;
        final totalChunks = data['total_chunks'] as int;
        final chunkData = base64Decode(data['data']);
        
        print('Chunk NFC recibido: ${chunkIndex + 1}/$totalChunks');
        
        // TODO: Implementar reconstrucción de archivo desde chunks
        await _assembleChunk(chunkIndex, totalChunks, chunkData);
      }
      
    } catch (e) {
      print('Error procesando chunk NFC: $e');
    }
  }
  
  /// Ensambla chunks recibidos en archivo completo
  final Map<int, Uint8List> _receivedChunks = {};
  
  Future<void> _assembleChunk(int index, int total, Uint8List data) async {
    _receivedChunks[index] = data;
    
    // Verificar si tenemos todos los chunks
    if (_receivedChunks.length == total) {
      try {
        // Reconstruir archivo
        final fileBytes = <int>[];
        
        for (int i = 0; i < total; i++) {
          if (_receivedChunks.containsKey(i)) {
            fileBytes.addAll(_receivedChunks[i]!);
          } else {
            print('Chunk $i faltante, no se puede reconstruir archivo');
            return;
          }
        }
        
        print('Archivo NFC reconstruido: ${fileBytes.length} bytes');
        
        // TODO: Procesar archivo completo
        // await _transferService._processJachaFile(reconstructedFile);
        
        // Limpiar chunks
        _receivedChunks.clear();
        
      } catch (e) {
        print('Error reconstruyendo archivo desde chunks: $e');
      }
    }
  }
  
  /// Getters para estado
  bool get isAvailable => _isAvailable;
  bool get isScanning => _isScanning;
  bool get isWriting => _isWriting;
}
