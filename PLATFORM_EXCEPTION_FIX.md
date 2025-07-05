# Solución al Error de PlatformException en ExportService

## Problema Identificado
El error `PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.path_provider_android.PathProviderApi.getTemporaryPath")` indica problemas con la configuración de `path_provider` en Android.

## Soluciones Implementadas

### 1. **Permisos de Android Agregados**
Se agregaron los permisos necesarios en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 2. **Manejo Robusto de Directorios**
Se implementó un sistema de fallback en múltiples niveles:

```dart
Future<Directory> _getTemporaryDirectory() async {
  try {
    // 1. Intentar path_provider
    return await getTemporaryDirectory();
  } catch (e) {
    // 2. Fallback: directorio de documentos de la app
    final appDocDir = await getApplicationDocumentsDirectory();
    // 3. Fallback: directorio del sistema
    final systemTempDir = Directory.systemTemp;
    // 4. Fallback final: directorio actual
    final currentDir = Directory.current;
  }
}
```

### 3. **Método Alternativo Sin path_provider**
Se creó `exportDocumentAsJachaAlternative()` que no depende de `path_provider`:

```dart
Future<File> exportDocumentAsJachaAlternative(int documentId) async {
  // Usa Directory.current directamente
  final appDir = Directory.current;
  final exportDir = Directory(join(appDir.path, 'jacha_exports', 'export_$documentId'));
  // ... resto de la lógica
}
```

### 4. **Sistema de Fallback Inteligente**
El método `exportAndShareDocument()` ahora intenta múltiples estrategias:

1. **Exportación alternativa** (sin path_provider)
2. **Exportación original** (con path_provider)
3. **Exportación debug** (solo JSON)

### 5. **Debugging Mejorado**
Se agregaron logs detallados en cada paso:
- Creación de directorios
- Escritura de archivos
- Compresión ZIP
- Estados de error

### 6. **Inicialización del Servicio**
Se agregó `initialize()` para crear directorios necesarios:

```dart
Future<void> initialize() async {
  final exportsDir = Directory(join(appDir.path, 'jacha_exports'));
  if (!exportsDir.existsSync()) {
    exportsDir.createSync(recursive: true);
  }
}
```

## Orden de Prueba Recomendado

1. **Limpiar proyecto**: `flutter clean && flutter pub get`
2. **Reconstruir**: Compile la aplicación después de los cambios
3. **Probar exportación**: Intente exportar un documento
4. **Revisar logs**: Los mensajes de debug indicarán qué método funcionó

## Archivos Modificados

- `lib/services/export_service.dart` - Lógica mejorada con fallbacks
- `android/app/src/main/AndroidManifest.xml` - Permisos agregados
- `pubspec.yaml` - Dependencias necesarias

## Próximos Pasos si Persiste el Error

Si el error continúa:

1. **Verificar versión de path_provider** en `pubspec.yaml`
2. **Usar solo el método alternativo** comentando las llamadas a path_provider
3. **Implementar permisos en tiempo de ejecución** para Android 6+
4. **Considerar usar external storage** para archivos públicos

## Logs de Debugging

El servicio ahora imprime información detallada:
```
I/flutter: Iniciando exportación alternativa para documento 1
I/flutter: Creando directorio: /current/path/jacha_exports/export_1
I/flutter: JSON guardado en: /current/path/jacha_exports/export_1/document.json
I/flutter: Creando archivo ZIP en: /current/path/jacha_exports/documento_titulo_1.jacha
I/flutter: ZIP creado exitosamente
I/flutter: Archivo .jacha creado exitosamente: /path/file.jacha
```

Esta implementación robusta debería resolver el problema de platform exception y proporcionar una funcionalidad de exportación confiable.
