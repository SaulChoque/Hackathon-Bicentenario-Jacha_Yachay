# Jacha Yachay

Una aplicación Flutter inspirada en Google Classroom, diseñada para el Hac### Vista de Recepción
✅ **Método personalizado** - Cada método tiene su icono y color característico
✅ **Instrucciones específicas** - Texto de ayuda personalizado para cada método
✅ **Contador de tiempo** - Cronómetro circular con límite de tiempo para la recepción
✅ **Código de identificación** - Código único para identificar la transferencia
✅ **Barra de progreso** - Indicador visual del tiempo restante
✅ **Botón de reinicio** - Permite reiniciar el proceso cuando el tiempo se agota
✅ **Interfaz simplificada** - Sin notificaciones ni navegación inferior innecesaria
✅ **Navegación mejorada** - Botón de retroceso para volver a la vista anterior
✅ **Vista scrolleable** - Permite desplazamiento vertical para pantallas pequeñasicentenario, con las siguientes características personalizadas:

## Características Implementadas

### Vista Principal (Home)
✅ **Interfaz moderna y oscura** - Tema oscuro elegante similar a Google Classroom
✅ **Sin menú hamburguesa** - Se eliminó el botón de apertura de la barra lateral izquierda
✅ **Label personalizado** - Reemplazó el botón de tres puntos por un label "nombre"
✅ **Botones de eliminación** - Cambió los tres puntos de las tarjetas por botones X
✅ **Branding personalizado** - "Google Classroom" ahora es "Jacha Yachay"
✅ **Navegación a detalle** - Al tocar una tarjeta se abre la vista de detalle de la clase
✅ **Botón de recibir** - Nuevo botón flotante verde con menú de métodos de recepción
✅ **Múltiples métodos de recepción** - WiFi Directo, NFC, WiFi, Bluetooth

### Vista de Detalle de Clase
✅ **Sin widget de nuevo anuncio** - Se eliminó como solicitado
✅ **Carga datos de la clase tocada** - Muestra información específica de la clase seleccionada
✅ **Símbolo de flama con puntos** - Esquina superior derecha del banner con número de puntos
✅ **Menú de opciones en tareas** - Botón de tres puntos despliega menú con "Enviar" y "Eliminar"
✅ **Navegación inferior con tabs** - Dos botones: "Temas" y "Trabajos"

### Vista de Recepción
✅ **Método personalizado** - Cada método tiene su icono y color característico
✅ **Instrucciones específicas** - Texto de ayuda personalizado para cada método
✅ **Contador de tiempo** - Cronómetro circular con límite de tiempo para la recepción
✅ **Código de identificación** - Código único para identificar la transferencia
✅ **Barra de progreso** - Indicador visual del tiempo restante
✅ **Botón de reinicio** - Permite reiniciar el proceso cuando el tiempo se agota

## Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada de la aplicación
├── models/
│   ├── class_card_model.dart          # Modelo de datos para las tarjetas de clase
│   ├── class_detail_model.dart        # Modelos para la vista de detalle (TaskModel, ClassDetailModel)
│   └── reception_model.dart           # Modelos para métodos de recepción (WiFi, NFC, Bluetooth)
├── services/
│   └── class_service.dart             # Servicio para gestión de clases
├── views/
│   ├── jacha_yachay_home_page.dart    # Pantalla principal con botones flotantes
│   ├── class_detail_page.dart         # Vista de detalle de clase con tabs
│   └── reception_page.dart            # Vista de recepción con contador de tiempo
└── widgets/
    ├── class_card.dart                # Widget reutilizable para tarjetas de clase
    └── task_card.dart                 # Widget para tarjetas de tareas con menú de opciones
```

## Capturas de Pantalla

La aplicación muestra:
- Header con logo e icono de Jacha Yachay
- Label "nombre" en lugar del menú de usuario
- Tarjetas de clase con gradientes coloridos
- Botones X para eliminar clases
- Botón flotante para agregar nuevas clases

## Tecnologías

- **Flutter** - Framework de desarrollo multiplataforma
- **Dart** - Lenguaje de programación
- **Material Design** - Sistema de diseño para interfaces modernas

## Instalación y Ejecución

1. Asegúrate de tener Flutter instalado
2. Clona este repositorio
3. Ejecuta `flutter pub get` para instalar dependencias
4. Ejecuta `flutter run` para iniciar la aplicación

## Funcionalidades

### Vista Principal
- **Vista de clases**: Muestra una lista de clases disponibles con información del instructor
- **Eliminación de clases**: Permite remover clases tocando el botón X
- **Navegación a detalle**: Toca cualquier tarjeta para ver los detalles de la clase
- **Botón de recibir**: Acceso rápido a métodos de recepción de clases
- **Diseño responsive**: Se adapta a diferentes tamaños de pantalla
- **Gradientes personalizados**: Cada clase tiene su propio esquema de colores
- **Iconos temáticos**: Cada materia tiene un icono representativo

### Vista de Detalle de Clase
- **Banner dinámico**: Muestra información de la clase con colores personalizados
- **Sistema de puntos**: Flama con número de puntos en la esquina superior derecha
- **Gestión de tareas**: Lista de tareas con opciones de envío y eliminación
- **Navegación por tabs**: Alternar entre "Temas" y "Trabajos"
- **Comentarios de clase**: Opción para agregar comentarios en cada tarea
- **Menú contextual**: Opciones "Enviar" y "Eliminar" para cada tarea

### Vista de Recepción
- **Selección de método**: Menú inferior con 4 opciones de conectividad
- **Interfaz personalizada**: Cada método tiene su color e icono único
- **Contador de tiempo**: Cronómetro de 42 segundos con progreso visual
- **Código de identificación**: Muestra código único "2A7COD6" para la transferencia
- **Instrucciones contextuales**: Guía específica para cada método de recepción
- **Reinicio automático**: Opción de reiniciar cuando expira el tiempo
- **Navegación inferior**: Barra de navegación con 5 opciones principales

## Próximas Funcionalidades

- Agregar nuevas clases desde la vista principal
- Editar información de clases existentes
- Crear y editar tareas desde la vista de detalle
- Sistema completo de comentarios
- Sistema de autenticación de usuarios
- Sincronización con backend
- Notificaciones push para nuevas tareas
- Sistema de calificaciones y seguimiento de progreso
