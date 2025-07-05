# Solución de Problemas - Permisos WiFi

## ❌ Error: "Permisos de red requeridos"

### 🔧 Soluciones

#### 1. **Verificar AndroidManifest.xml**
Asegúrate de que estos permisos estén en `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permisos necesarios para WiFi y red -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### 2. **Otorgar Permisos en el Dispositivo**

##### Método A: Durante la ejecución
1. La app solicitará permisos automáticamente
2. Presiona "Permitir" cuando aparezca el diálogo
3. **Importante**: Para ubicación, selecciona "Permitir siempre" o "Permitir mientras se usa la app"

##### Método B: Configuración manual
1. Ve a **Configuración** → **Aplicaciones**
2. Busca **"jacha_yachay"**
3. Selecciona **"Permisos"**
4. Activa:
   - ✅ **Ubicación**: "Permitir siempre" o "Solo mientras se usa la app"
   - ✅ **Almacenamiento** (si aparece)

#### 3. **Verificar Conexión WiFi**
- Asegúrate de estar conectado a una red WiFi
- La app requiere WiFi para funcionar, no funcionará solo con datos móviles
- Verifica que el WiFi esté activo en: **Configuración** → **WiFi**

#### 4. **Si el error persiste**

##### Opción A: Reiniciar permisos
```bash
# En terminal/cmd
flutter clean
flutter pub get
```

##### Opción B: Reinstalar la app
1. Desinstala la app del dispositivo
2. Ejecuta: `flutter run --release`
3. Otorga todos los permisos cuando se soliciten

##### Opción C: Usar modo simulado
1. En la página de envío/recepción
2. Desactiva el switch **"Usar Transferencia Real"**
3. Esto usará el modo simulado que no requiere permisos especiales

### 🐛 Debugging

#### Ver logs detallados:
```bash
flutter run --verbose
```

#### Verificar permisos en código:
En el archivo `wifi_transfer_service.dart`, el método `debugNetworkInfo()` mostrará:
- Estado de conectividad
- Información de WiFi
- Interfaces de red disponibles
- IP local

### 📱 Dispositivos Específicos

#### Samsung:
- Ve a **Configuración** → **Aplicaciones** → **jacha_yachay** → **Permisos**
- Activa **"Ubicación"** y selecciona **"Permitir siempre"**

#### Xiaomi/MIUI:
- Ve a **Configuración** → **Aplicaciones** → **Administrar aplicaciones** → **jacha_yachay** → **Permisos de aplicación**
- Activa **"Ubicación"**
- También verifica **Configuración** → **Privacidad** → **Administrador de permisos** → **Ubicación**

#### Huawei:
- Ve a **Configuración** → **Aplicaciones** → **jacha_yachay** → **Permisos**
- Activa **"Ubicación"**

### ⚠️ Notas Importantes

1. **Ubicación es necesaria**: Android requiere permisos de ubicación para acceder a información de WiFi por razones de seguridad.

2. **No se usa GPS**: La app NO usa GPS ni rastrea ubicación, solo necesita el permiso para acceder a la información de red WiFi.

3. **Solo en red local**: La transferencia WiFi solo funciona entre dispositivos en la misma red WiFi.

### ✅ Verificación Exitosa

Si todo está correcto, deberías ver en los logs:
```
I/flutter: Todos los permisos WiFi verificados correctamente
I/flutter: IP WiFi obtenida: 192.168.x.x
I/flutter: Servidor WiFi iniciado en http://192.168.x.x:8080
```

### 🔄 Alternativas

Si no puedes solucionar los permisos:

1. **Usa NFC**: No requiere permisos especiales de red
2. **Usa Modo Simulado**: Para desarrollo y pruebas
3. **Usa "Enviar mediante Terceros"**: Comparte archivos con otras apps

### 📞 Soporte

Si el problema persiste después de seguir estos pasos:
1. Anota el modelo de tu dispositivo
2. Anota la versión de Android
3. Copia los logs de error completos
4. Verifica que el WiFi funcione con otras apps
