# Funcionalidad de Exportación y Envío de Documentos (.jacha)

## Descripción
La aplicación ahora incluye una funcionalidad completa para exportar documentos de la base de datos SQLite a archivos `.jacha` (archivos comprimidos similares a `.docx`) y compartirlos usando diferentes métodos de transferencia.

## Archivos Creados/Modificados

### 1. `lib/services/export_service.dart`
**Nuevo servicio** que maneja la exportación de documentos:
- `exportDocumentAsJacha(int documentId)`: Exporta un documento completo con sus datos relacionados
- `shareJachaFile(File jachaFile)`: Comparte el archivo usando el sistema nativo
- `exportAndShareDocument(int documentId)`: Proceso completo de exportar y compartir
- `cleanupOldExports()`: Limpia archivos temporales antiguos

### 2. `lib/views/send_page.dart`
**Nueva página** para el proceso de envío:
- Interfaz similar a `reception_page.dart` pero orientada al envío
- Contador de tiempo activo
- Simulación del proceso de exportación
- Botón para compartir usando el sistema nativo
- Indicadores visuales del progreso

### 3. `lib/models/reception_model.dart`
**Modificado** para soportar tanto recepción como envío:
- Agregado `TransferMode` (receive/send)
- Renombrado a `TransferMethodModel` (mantiene compatibilidad)
- Instrucciones específicas para cada modo

### 4. `lib/views/class_detail_page.dart`
**Modificado** para implementar el flujo de envío:
- Método `_sendTask()` ahora abre un modal con métodos de envío
- Modal `_showSendMethodModal()` muestra opciones de transferencia
- Navegación a `SendPage` con el método seleccionado

### 5. `lib/models/database_models.dart`
**Modificado** para soportar serialización:
- Agregado método `toMap()` a la clase `DocumentComplete`

### 6. `pubspec.yaml`
**Agregadas nuevas dependencias**:
- `path_provider: ^2.1.1` - Para directorios temporales
- `archive: ^3.4.9` - Para crear archivos ZIP
- `share_plus: ^7.2.1` - Para compartir archivos nativamente

## Estructura del Archivo .jacha

El archivo `.jacha` es un archivo ZIP que contiene:
```
documento_nombre_id.jacha
├── document.json          # Datos del documento en JSON
└── media/                 # Carpeta para archivos multimedia
    ├── imagen1.jpg
    ├── video1.mp4
    └── audio1.mp3
```

### Contenido de `document.json`:
```json
{
  "version": "1.0",
  "exportDate": "2025-07-05T10:30:00.000Z",
  "document": {
    "id": 1,
    "title": "Título del documento",
    "authorId": "autor123",
    "createdAt": "2025-07-01T08:00:00.000Z",
    "classId": 1
  },
  "articleBlocks": [
    {
      "id": 1,
      "documentId": 1,
      "type": "paragraph",
      "content": "Contenido del bloque",
      "blockOrder": 1
    }
  ],
  "questions": [
    {
      "id": 1,
      "documentId": 1,
      "type": "multiple_choice",
      "text": "¿Pregunta?",
      "correctAnswer": "A"
    }
  ],
  "questionOptions": {
    "1": [
      {
        "id": 1,
        "questionId": 1,
        "text": "Opción A",
        "isCorrect": true
      }
    ]
  }
}
```

## Flujo de Usuario

1. **Seleccionar envío**: El usuario toca el botón "Enviar" en una tarea
2. **Elegir método**: Se abre un modal con métodos de transferencia disponibles
3. **Preparación**: La app exporta el documento y crea el archivo `.jacha`
4. **Compartir**: Se abre el selector nativo del sistema para compartir el archivo

## Métodos de Transferencia Disponibles

- **WiFi Directo**: Para transferencias directas entre dispositivos
- **NFC**: Para transferencias de proximidad
- **WiFi**: Para transferencias a través de red WiFi
- **Bluetooth**: Para transferencias Bluetooth tradicionales

## Próximas Mejoras

- Implementar lógica real para cada método de transferencia
- Agregar soporte para archivos multimedia embebidos
- Implementar importación de archivos `.jacha`
- Agregar cifrado para documentos sensibles
- Implementar historial de envíos/recepciones
