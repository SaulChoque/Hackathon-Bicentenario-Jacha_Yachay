# Implementación de SQLite en Jacha Yachay

## Resumen

Se ha implementado SQLite en el proyecto Flutter de Jacha Yachay para manejar documentos educativos con artículos y preguntas de evaluación.

## Estructura de la Base de Datos

### Tablas implementadas:

1. **documents**: Almacena información básica de documentos educativos
   - `id`: Clave primaria autoincremental
   - `author_id`: ID del autor/instructor
   - `created_at`: Fecha de creación
   - `title`: Título del documento

2. **article_blocks**: Bloques de contenido de los documentos
   - `id`: Clave primaria autoincremental
   - `document_id`: Referencia al documento
   - `type`: Tipo de bloque ('title', 'paragraph', 'image', 'video')
   - `content`: Contenido del bloque
   - `block_order`: Orden de visualización

3. **questions**: Preguntas de evaluación
   - `id`: Clave primaria autoincremental
   - `document_id`: Referencia al documento
   - `type`: Tipo de pregunta ('multiple_choice', 'true_false', 'open')
   - `text`: Texto de la pregunta
   - `correct_answer`: Respuesta correcta (para preguntas abiertas/verdadero-falso)

4. **options**: Opciones para preguntas de opción múltiple
   - `id`: Clave primaria autoincremental
   - `question_id`: Referencia a la pregunta
   - `text`: Texto de la opción
   - `is_correct`: Si es la respuesta correcta

## Archivos Nuevos Creados

### 1. `lib/models/database_models.dart`
Contiene los modelos Dart para interactuar con la base de datos:
- `Document`
- `Question`
- `QuestionOption`
- `ArticleBlock`
- `DocumentComplete` (modelo compuesto)

### 2. `lib/services/database_service.dart`
Servicio principal para manejar la base de datos SQLite:
- Inicialización de la base de datos
- Métodos CRUD para todas las tablas
- Datos de ejemplo pre-cargados
- Método `getCompleteDocument()` para obtener documentos con todo su contenido

## Archivos Modificados

### 1. `pubspec.yaml`
Se agregaron las dependencias:
```yaml
dependencies:
  sqflite: ^2.4.2
  path: ^1.8.3
```

### 2. `lib/models/class_detail_model.dart`
Se agregó el campo `documentId` al modelo `TaskModel` para vincular tareas con documentos de la base de datos.

### 3. `lib/views/tema_detalle_view.dart`
Se transformó de un widget estático a uno dinámico que:
- Carga datos desde SQLite
- Muestra contenido basado en `ArticleBlock`
- Renderiza preguntas de evaluación con diferentes tipos
- Maneja estados de carga y error

### 4. `lib/views/class_detail_page.dart`
Se actualizó el método `_getTasksForClass()` para asignar `documentId` a las tareas.

## Cómo Usar

### 1. Crear Nuevo Documento
```dart
final databaseService = DatabaseService();

// Crear documento
final document = Document(
  authorId: 'instructor_001',
  createdAt: DateTime.now(),
  title: 'Mi Nuevo Documento',
);
final documentId = await databaseService.insertDocument(document);

// Agregar bloques de contenido
await databaseService.insertArticleBlock(
  ArticleBlock(
    documentId: documentId,
    type: 'title',
    content: 'Título Principal',
    blockOrder: 1,
  ),
);
```

### 2. Cargar Documento Completo
```dart
final documentComplete = await databaseService.getCompleteDocument(1);
if (documentComplete != null) {
  // Usar documentComplete.document, documentComplete.articleBlocks, etc.
}
```

### 3. Agregar Pregunta con Opciones
```dart
// Crear pregunta
final question = Question(
  documentId: 1,
  type: 'multiple_choice',
  text: '¿Cuál es la respuesta correcta?',
);
final questionId = await databaseService.insertQuestion(question);

// Agregar opciones
await databaseService.insertQuestionOption(
  QuestionOption(
    questionId: questionId,
    text: 'Opción A',
    isCorrect: true,
  ),
);
```

## Navegación a TemaDetalleView

Cuando un usuario toca una tarea en `ClassDetailPage`, se navega a `TemaDetalleView` pasando el `TaskModel` que contiene el `documentId`. La vista automáticamente:

1. Carga el documento desde SQLite
2. Muestra los bloques de artículo en orden
3. Renderiza las preguntas de evaluación
4. Maneja diferentes tipos de contenido (título, párrafo, imagen, video)

## Tipos de Preguntas Soportadas

1. **Opción Múltiple**: Se muestran todas las opciones con indicador visual de la correcta
2. **Verdadero/Falso**: Se muestra la respuesta correcta
3. **Respuesta Abierta**: Se muestra un campo de texto para la respuesta

## Datos de Ejemplo

El sistema viene pre-cargado con:
- Un documento de "Trabajo Final - Desarrollo de Apps Flutter"
- Varios bloques de contenido explicativo
- Preguntas de evaluación de ejemplo

## Consideraciones para Android

SQLite funciona perfectamente en Android a través del paquete `sqflite`. No requiere configuración adicional y los datos se almacenan localmente en el dispositivo.

## Próximos Pasos

1. Agregar más tipos de bloques de contenido (listas, citas, etc.)
2. Implementar funcionalidad para que los usuarios respondan preguntas
3. Agregar sistema de calificaciones
4. Implementar búsqueda de documentos
5. Agregar exportación/importación de datos
