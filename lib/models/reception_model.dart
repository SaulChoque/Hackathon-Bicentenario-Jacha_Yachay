import 'package:flutter/material.dart';

enum ReceptionMethod {
  wifiDirect,
  nfc,
  wifi,
  bluetooth,
}

class ReceptionMethodModel {
  final ReceptionMethod method;
  final String name;
  final IconData icon;
  final String instruction;
  final Color color;

  ReceptionMethodModel({
    required this.method,
    required this.name,
    required this.icon,
    required this.instruction,
    required this.color,
  });

  static List<ReceptionMethodModel> getAllMethods() {
    return [
      ReceptionMethodModel(
        method: ReceptionMethod.wifiDirect,
        name: 'Recibir por WiFi Directo',
        icon: Icons.wifi,
        instruction: 'Active WiFi Directo en ambos dispositivos y busque la conexión.',
        color: const Color(0xFF4CAF50),
      ),
      ReceptionMethodModel(
        method: ReceptionMethod.nfc,
        name: 'Recibir por NFC',
        icon: Icons.nfc,
        instruction: 'Acerque su teléfono al dispositivo emisor.',
        color: const Color(0xFF2196F3),
      ),
      ReceptionMethodModel(
        method: ReceptionMethod.wifi,
        name: 'Recibir por WiFi',
        icon: Icons.wifi_tethering,
        instruction: 'Asegúrese de estar conectado a la misma red WiFi.',
        color: const Color(0xFF9C27B0),
      ),
      ReceptionMethodModel(
        method: ReceptionMethod.bluetooth,
        name: 'Recibir por Bluetooth',
        icon: Icons.bluetooth,
        instruction: 'Active Bluetooth y haga visible su dispositivo.',
        color: const Color(0xFF3F51B5),
      ),
    ];
  }
}
