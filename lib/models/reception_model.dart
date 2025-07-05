import 'package:flutter/material.dart';

enum TransferMethod {
  wifiDirect,
  nfc,
  wifi,
  bluetooth,
}

enum TransferMode {
  receive,
  send,
}

class TransferMethodModel {
  final TransferMethod method;
  final String name;
  final IconData icon;
  final String instruction;
  final Color color;

  TransferMethodModel({
    required this.method,
    required this.name,
    required this.icon,
    required this.instruction,
    required this.color,
  });

  static List<TransferMethodModel> getAllMethods({TransferMode mode = TransferMode.receive}) {
    final isReceive = mode == TransferMode.receive;
    
    return [
      TransferMethodModel(
        method: TransferMethod.wifiDirect,
        name: isReceive ? 'Recibir por WiFi Directo' : 'Enviar por WiFi Directo',
        icon: Icons.wifi,
        instruction: isReceive 
          ? 'Active WiFi Directo en ambos dispositivos y busque la conexión.'
          : 'Active WiFi Directo y espere conexiones de otros dispositivos.',
        color: const Color(0xFF4CAF50),
      ),
      TransferMethodModel(
        method: TransferMethod.nfc,
        name: isReceive ? 'Recibir por NFC' : 'Enviar por NFC',
        icon: Icons.nfc,
        instruction: isReceive 
          ? 'Acerque su teléfono al dispositivo emisor.'
          : 'Acerque el dispositivo receptor a su teléfono.',
        color: const Color(0xFF2196F3),
      ),
      TransferMethodModel(
        method: TransferMethod.wifi,
        name: isReceive ? 'Recibir por WiFi' : 'Enviar por WiFi',
        icon: Icons.wifi_tethering,
        instruction: isReceive 
          ? 'Asegúrese de estar conectado a la misma red WiFi.'
          : 'Comparta el archivo a través de la red WiFi.',
        color: const Color(0xFF9C27B0),
      ),
      TransferMethodModel(
        method: TransferMethod.bluetooth,
        name: isReceive ? 'Recibir por Bluetooth' : 'Enviar por Bluetooth',
        icon: Icons.bluetooth,
        instruction: isReceive 
          ? 'Active Bluetooth en ambos dispositivos y empareje los dispositivos.'
          : 'Active Bluetooth y espere la conexión del dispositivo receptor.',
        color: const Color(0xFFFF9800),
      ),
    ];
  }
}

// Mantener compatibilidad con el código existente
typedef ReceptionMethodModel = TransferMethodModel;
typedef ReceptionMethod = TransferMethod;
