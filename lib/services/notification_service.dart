import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

final NotificationService notificationService = NotificationService();

class NotificationService {
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',
      [
        NotificationChannel(
          channelGroupKey: 'alerts',
          channelKey: 'alerts',
          channelName: 'Alerts',
          channelDescription: 'Notification channel for basic alerts',
          defaultColor: Colors.red,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          locked: true,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
          fullScreenIntent: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'alerts',
          channelGroupName: 'Alerts',
        ),
      ],
      debug: true,
    );
  }

  static Future<void> requestPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> showMedicationNotification({
    required String title,
    required String body,
    required String imageUrl,
    required Map<String, String> payload,
    NotificationSchedule? schedule,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'alerts',
        title: title,
        body: body,
        bigPicture: imageUrl,
        notificationLayout: NotificationLayout.BigPicture,
        payload: payload,
        fullScreenIntent: true,
        autoDismissible: false,
        timeoutAfter: 60000, // 1 minute
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Snooze (5 min)',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          isDangerousOption: true,
        ),
      ],
      schedule: schedule,
    );
  }

  late Future<void> Function(String medicationId, String action) onNotificationAction;
  late Medication? Function(String id) onGetMedication;

  Future<void> scheduleMedicationReminders(Medication medication) async {
    // Implementar la lógica para programar los recordatorios de medicación
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    // Implementar la lógica para cancelar los recordatorios de medicación
  }
}
