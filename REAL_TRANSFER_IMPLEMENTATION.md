# Implementación de Transferencia Real WiFi y NFC

## Resumen

Se ha implementado la lógica real para transferencias WiFi y NFC en la aplicación Jacha Yachay, permitiendo enviar y recibir documentos .jacha usando tecnologías reales en lugar de solo simulaciones.

## Características Implementadas

### 1. Servicios de Transferencia Real

#### WiFi Transfer Service (`wifi_transfer_service.dart`)
- **Servidor HTTP**: Inicia un servidor local en puerto 8080 para recibir archivos
- **Discovery**: Endpoint `/discover` para que otros dispositivos encuentren el servidor
- **Upload**: Endpoint `/upload` para recibir archivos .jacha
- **Escaneo de Dispositivos**: Busca otros dispositivos Jacha Yachay en la red local
- **Envío de Archivos**: Envía archivos .jacha a dispositivos específicos por IP

#### NFC Transfer Service (`nfc_transfer_service.dart`)
- **Inicialización**: Verifica disponibilidad de NFC en el dispositivo
- **Recepción**: Modo escucha para recibir archivos via NFC
- **Envío**: Transfiere archivos pequeños o por chunks según el tamaño
- **Manejo de Chunks**: Para archivos grandes (>8KB), los divide en fragmentos

### 2. Integración en Transfer Service

Se agregaron métodos unificados en `TransferService`:

- `initializeRealServices()`: Inicializa NFC y otros servicios
- `startWiFiReceiver()` / `stopWiFiReceiver()`: Control del servidor WiFi
- `startNFCReceiver()` / `stopNFCReceiver()`: Control del receptor NFC
- `scanWiFiDevices()`: Escanea dispositivos WiFi disponibles
- `sendViaWiFi()`: Envía documentos por WiFi a IP específica
- `sendViaNFC()`: Envía documentos por NFC
- `sendDocumentReal()`: Método unificado para envío real

### 3. UI Mejorada

#### Página de Envío (`enhanced_send_page.dart`)
- **Switch Real/Simulado**: Permite alternar entre transferencia real y simulada
- **Escaneo Real de WiFi**: Lista dispositivos reales encontrados en la red
- **Envío a Múltiples Dispositivos**: Soporte para seleccionar varios destinos WiFi
- **Progreso Visual**: Indicadores de estado para transferencias en curso

#### Página de Recepción (`enhanced_reception_page.dart`)
- **Switch Real/Simulado**: Control del modo de recepción
- **Servidor WiFi Automático**: Inicia servidor al activar modo WiFi real
- **Estado NFC**: Muestra estado de disponibilidad y espera NFC
- **Manejo de Errores**: Feedback visual para errores de conexión

## Cómo Usar

### Para WiFi

#### Envío:
1. Ir a la página de envío de documentos
2. Seleccionar "WiFi" como método
3. Activar el switch "Usar Transferencia Real"
4. Esperar que aparezcan dispositivos en la red
5. Seleccionar dispositivos destino
6. Presionar "Enviar a Dispositivos Seleccionados"

#### Recepción:
1. Ir a la página de recepción
2. Seleccionar "WiFi" como método
3. Activar el switch "Usar Transferencia Real"
4. El servidor se iniciará automáticamente
5. Esperar a que otros dispositivos envíen archivos

### Para NFC

#### Envío:
1. Ir a la página de envío de documentos
2. Seleccionar "NFC" como método
3. Activar el switch "Usar Transferencia Real"
4. Presionar "Iniciar Transferencia NFC"
5. Acercar el dispositivo receptor cuando se solicite

#### Recepción:
1. Ir a la página de recepción
2. Seleccionar "NFC" como método
3. Activar el switch "Usar Transferencia Real"
4. Mantener el dispositivo cerca del emisor
5. El archivo se recibirá automáticamente

## Requisitos y Permisos

### WiFi
- Conexión WiFi activa
- Permiso de ubicación (para obtener información de red)
- Puertos 8080-8081 disponibles

### NFC
- Dispositivo con chip NFC
- NFC habilitado en configuración del sistema
- Proximidad física entre dispositivos (< 4cm)

## Limitaciones Actuales

### WiFi
- Solo funciona en redes locales (misma subred)
- No hay cifrado de archivos (solo HTTP)
- Requiere que ambos dispositivos estén conectados a la misma red WiFi

### NFC
- Velocidad limitada (archivos pequeños < 8KB son más eficientes)
- Requiere proximidad física muy cercana
- Dependiente de la implementación NDEF del dispositivo

## Código de Ejemplo

### Envío WiFi Programático
```dart
final transferService = TransferService();
await transferService.initializeRealServices();

final devices = await transferService.scanWiFiDevices();
for (final device in devices) {
  final success = await transferService.sendViaWiFi(
    documentId: 1,
    targetIP: device['ip'],
  );
  print('Envío a ${device['name']}: $success');
}
```

### Recepción NFC Programática
```dart
final transferService = TransferService();
await transferService.initializeRealServices();

final success = await transferService.startNFCReceiver();
if (success) {
  print('Esperando documentos via NFC...');
}
```

## Próximos Pasos

1. **Seguridad**: Implementar cifrado de archivos en transferencias WiFi
2. **WiFi Direct**: Completar implementación de WiFi Direct para conexiones P2P
3. **Bluetooth**: Agregar soporte real para transferencias Bluetooth
4. **Optimización**: Mejorar velocidad de transferencia y manejo de archivos grandes
5. **UX**: Agregar más feedback visual y manejo de errores mejorado

## Testing

Para probar las funciones:

1. **WiFi**: Usar dos dispositivos en la misma red WiFi
2. **NFC**: Usar dos dispositivos con NFC habilitado
3. **Archivos**: Crear documentos de prueba de diferentes tamaños
4. **Errores**: Probar desconexión de red, NFC deshabilitado, etc.

La implementación mantiene compatibilidad con el modo simulado para desarrollo y testing sin hardware específico.
