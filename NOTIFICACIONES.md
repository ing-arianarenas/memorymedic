# 🔔 Sistema de Notificaciones - MemoryMedic

## 📋 Descripción General

El sistema de notificaciones de MemoryMedic permite recordar a los usuarios tomar sus medicamentos en los horarios programados, **incluso cuando**:
- ✅ La aplicación está cerrada
- ✅ El celular está bloqueado
- ✅ La aplicación está en segundo plano

## 🏗️ Arquitectura

### Componentes Principales

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Servicio singleton que gestiona todas las notificaciones
   - Utiliza `flutter_local_notifications` para notificaciones locales
   - Utiliza `timezone` para programar alarmas en horarios específicos

2. **MedicationReminderScreen** (`lib/views/medication_reminder_screen.dart`)
   - Pantalla que se muestra cuando el usuario toca una notificación
   - Diseño basado en el mockup HTML proporcionado
   - Botones: TOMAR, Posponer, Omitir

3. **Integración con HomeViewModel**
   - Programa notificaciones al agregar/actualizar medicamentos
   - Cancela notificaciones al eliminar medicamentos
   - Maneja callbacks de acciones de notificación

## 🔧 Configuración

### Android

#### Permisos (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

#### Receivers
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
```

### iOS

#### Info.plist
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### AppDelegate.swift
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
}
```

## 📱 Uso del Sistema

### 1. Inicialización

El servicio se inicializa automáticamente en `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  
  runApp(const MemoryMedicApp());
}
```

### 2. Programar Notificaciones

Las notificaciones se programan automáticamente cuando:

```dart
// Al agregar un medicamento
viewModel.addMedication(medication);

// Al activar un medicamento
viewModel.toggleMedicationStatus(medicationId);

// Al actualizar un medicamento
viewModel.updateMedication(medication);
```

### 3. Cancelar Notificaciones

```dart
// Cancelar notificaciones de un medicamento específico
await NotificationService().cancelMedicationReminders(medicationId);

// Cancelar todas las notificaciones
await NotificationService().cancelAllNotifications();
```

### 4. Posponer Notificación

```dart
// Posponer por 10 minutos
await NotificationService().snoozeNotification(medicationId, index);
```

## 🎨 Características de las Notificaciones

### Notificación en Android
- **Título**: "Hora de tu medicamento"
- **Cuerpo**: "Nombre del medicamento - Dosis"
- **Imagen**: Foto del medicamento (si está disponible)
- **Acciones**:
  - 🟢 **TOMAR**: Marca el medicamento como tomado
  - 🟡 **Posponer**: Pospone la notificación por 10 minutos
  - 🔴 **Omitir**: Omite esta dosis

### Notificación en iOS
- **Título**: "Hora de tu medicamento"
- **Subtítulo**: Dosis del medicamento
- **Cuerpo**: Nombre del medicamento
- **Adjunto**: Imagen del medicamento (si está disponible)

## 🔄 Flujo de Trabajo

```
1. Usuario agrega medicamento con horarios
   ↓
2. HomeViewModel llama a NotificationService.scheduleMedicationReminders()
   ↓
3. NotificationService programa alarmas para cada horario
   ↓
4. En el horario programado:
   ↓
5. Sistema muestra notificación (incluso si app está cerrada)
   ↓
6. Usuario interactúa con la notificación:
   - Toca la notificación → Abre la app
   - Presiona "TOMAR" → Registra como tomado
   - Presiona "Posponer" → Reprograma en 10 minutos
   - Presiona "Omitir" → Cancela esta dosis
```

## 🌍 Zona Horaria

El sistema utiliza la zona horaria configurada en `NotificationService`:

```dart
// Para Colombia
tz.setLocalLocation(tz.getLocation('America/Bogota'));

// Para otros países, cambiar según corresponda:
// - México: 'America/Mexico_City'
// - Argentina: 'America/Argentina/Buenos_Aires'
// - España: 'Europe/Madrid'
```

## 🔍 Debugging

### Ver notificaciones pendientes

```dart
final pending = await NotificationService().getPendingNotifications();
for (var notification in pending) {
  print('ID: ${notification.id}, Title: ${notification.title}');
}
```

### Logs importantes

El servicio imprime logs cuando:
- Se programa una notificación
- Se cancela una notificación
- El usuario interactúa con una notificación

## ⚠️ Consideraciones Importantes

### Android 12+ (API 31+)
- Requiere permiso `SCHEDULE_EXACT_ALARM` para alarmas exactas
- El usuario debe otorgar el permiso manualmente en configuración

### Android 13+ (API 33+)
- Requiere permiso `POST_NOTIFICATIONS` en tiempo de ejecución
- Se solicita automáticamente al iniciar la app

### iOS
- Las notificaciones locales funcionan sin configuración adicional
- El usuario debe aceptar los permisos de notificación

### Limitaciones
- **Android**: Máximo 500 notificaciones programadas simultáneamente
- **iOS**: Sin límite conocido, pero se recomienda no exceder 64 notificaciones

## 🧪 Pruebas

### Probar notificaciones inmediatas

Para probar, puedes modificar temporalmente el horario:

```dart
// En lugar de usar el horario del medicamento
final testTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 10));
```

### Verificar permisos

```dart
final hasPermission = await NotificationService().requestPermissions();
print('Permisos otorgados: $hasPermission');
```

## 📚 Dependencias

```yaml
dependencies:
  flutter_local_notifications: ^19.5.0
  timezone: ^0.10.1
  permission_handler: ^12.0.1
```

## 🔗 Referencias

- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [timezone](https://pub.dev/packages/timezone)
- [permission_handler](https://pub.dev/packages/permission_handler)

## 🎯 Próximas Mejoras

- [ ] Persistencia de historial de medicamentos tomados
- [ ] Estadísticas de adherencia al tratamiento
- [ ] Notificaciones personalizadas por medicamento
- [ ] Sonidos personalizados
- [ ] Integración con calendario
- [ ] Recordatorios para reabastecimiento

