import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Callback para obtener medicamento por ID
  Medication? Function(String)? onGetMedication;

  // Callback para manejar acciones de notificación
  void Function(String medicationId, String action)? onNotificationAction;

  // Rastrear cuántas veces se ha aplazado cada medicamento (para incremento progresivo)
  final Map<String, int> _snoozeCount = {};

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar zonas horarias
    tz.initializeTimeZones();

    // Configurar zona horaria local (ajusta según tu región)
    // Para Colombia: 'America/Bogota'
    tz.setLocalLocation(tz.getLocation('America/Bogota'));

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();

    _initialized = true;
  }

  /// Crea el canal de notificaciones para Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'medication_reminders', // ID del canal
      'Recordatorios de Medicamentos', // Nombre
      description: 'Notificaciones para recordar tomar tus medicamentos',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Solicita permisos de notificación
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ requiere permiso explícito
      final status = await Permission.notification.request();

      // Solicitar permiso para alarmas exactas (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  /// Programa notificaciones para un medicamento
  Future<void> scheduleMedicationReminders(Medication medication) async {
    if (!_initialized) await initialize();

    // Cancelar notificaciones previas de este medicamento
    await cancelMedicationReminders(medication.id);

    // Resetear contador de aplazamiento al programar nuevas notificaciones
    resetSnoozeCount(medication.id);

    // Programar notificación para cada horario
    for (int i = 0; i < medication.times.length; i++) {
      final time = medication.times[i];
      final notificationId = _generateNotificationId(medication.id, i);

      await _scheduleNotification(
        id: notificationId,
        title: 'Hora de tu medicamento',
        body: '${medication.name} - ${medication.dosage}',
        scheduledTime: time,
        payload: medication.id,
        medicationName: medication.name,
        medicationDosage: medication.dosage,
        medicationImage: medication.imagePath,
      );
    }
  }

  /// Programa una notificación individual
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    String? payload,
    String? medicationName,
    String? medicationDosage,
    String? medicationImage,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de Medicamentos',
          channelDescription:
              'Notificaciones para recordar tomar tus medicamentos',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: medicationImage != null
              ? FilePathAndroidBitmap(medicationImage)
              : null,
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'take',
              'TOMAR',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'snooze',
              'Posponer',
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'skip',
              'Omitir',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: medicationDosage,
          attachments: medicationImage != null
              ? [DarwinNotificationAttachment(medicationImage)]
              : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      payload: payload,
    );
  }

  /// Cancela todas las notificaciones de un medicamento
  Future<void> cancelMedicationReminders(String medicationId) async {
    // Cancelar hasta 10 posibles horarios (ajustar según necesidad)
    for (int i = 0; i < 10; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      await _notifications.cancel(notificationId);
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Pospone una notificación incrementando progresivamente de 5 en 5 hasta 15 minutos
  Future<void> snoozeNotification(String medicationId, int index, {int? postponeMinutes}) async {
    final notificationId = _generateNotificationId(medicationId, index);

    // Obtener el medicamento para saber los minutos configurables
    final medication = onGetMedication?.call(medicationId);
    final basePostponeMinutes = postponeMinutes ?? medication?.postponeMinutes ?? 5;

    // Incrementar contador de aplazamiento para este medicamento
    _snoozeCount[medicationId] = (_snoozeCount[medicationId] ?? 0) + 1;
    final snoozeCount = _snoozeCount[medicationId]!;

    // Calcular minutos: comenzar con 5, luego 10, luego 15 (máximo)
    int snoozeMinutes;
    if (snoozeCount == 1) {
      snoozeMinutes = 5; // Primer aplazamiento: 5 minutos
    } else if (snoozeCount == 2) {
      snoozeMinutes = 10; // Segundo aplazamiento: 10 minutos
    } else {
      snoozeMinutes = 15; // Tercer aplazamiento y siguientes: 15 minutos (máximo)
    }

    // Asegurar que no exceda el máximo configurado
    if (snoozeMinutes > basePostponeMinutes) {
      snoozeMinutes = basePostponeMinutes;
    }

    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: snoozeMinutes));

    // Obtener información del medicamento para la notificación
    final medicationName = medication?.name ?? 'Medicamento';
    final medicationDosage = medication?.dosage ?? '';

    await _notifications.zonedSchedule(
      notificationId,
      'Recordatorio pospuesto',
      '$medicationName - $medicationDosage',
      snoozeTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de Medicamentos',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: medicationId,
    );
  }

  /// Resetea el contador de aplazamiento para un medicamento
  void resetSnoozeCount(String medicationId) {
    _snoozeCount.remove(medicationId);
  }

  /// Genera un ID único para cada notificación
  int _generateNotificationId(String medicationId, int index) {
    // Combinar hash del ID con el índice para crear un ID único
    return medicationId.hashCode + index;
  }

  /// Maneja el tap en una notificación
  void _onNotificationTapped(NotificationResponse response) {
    final medicationId = response.payload;
    final actionId = response.actionId;

    if (medicationId == null) return;

    if (actionId == 'take') {
      // Usuario tomó el medicamento
      debugPrint('Usuario tomó el medicamento: $medicationId');
      // Resetear contador de aplazamiento cuando se toma el medicamento
      resetSnoozeCount(medicationId);
      onNotificationAction?.call(medicationId, 'take');
    } else if (actionId == 'snooze') {
      // Posponer notificación
      debugPrint('Usuario pospuso el medicamento: $medicationId');
      onNotificationAction?.call(medicationId, 'snooze');
      // Posponer incrementando progresivamente (5→10→15 minutos)
      final medication = onGetMedication?.call(medicationId);
      snoozeNotification(medicationId, 0, postponeMinutes: medication?.postponeMinutes);
    } else if (actionId == 'skip') {
      // Omitir esta dosis
      debugPrint('Usuario omitió el medicamento: $medicationId');
      onNotificationAction?.call(medicationId, 'skip');
    } else {
      // Tap normal en la notificación - mostrar pantalla de recordatorio
      debugPrint('Notificación tocada: $medicationId');
      onNotificationAction?.call(medicationId, 'open');
    }
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
