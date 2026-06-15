import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/logger.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.info('Notification clicked: ${response.payload}', tag: 'NotificationService');
        },
      );

      AppLogger.success('NotificationService initialized successfully', tag: 'NotificationService');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize NotificationService', error: e, stackTrace: stack, tag: 'NotificationService');
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final approved = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return approved ?? false;
      } else if (Platform.isAndroid) {
        final approved = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return approved ?? false;
      }
      return true;
    } catch (e) {
      AppLogger.error('Failed to request notification permission', error: e, tag: 'NotificationService');
      return false;
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'app_channel_id',
        'App Notifications',
        channelDescription: 'Main notification channel for app updates',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      AppLogger.error('Failed to show notification', error: e, tag: 'NotificationService');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'scheduled_channel_id',
        'Scheduled Notifications',
        channelDescription: 'Channel for timed notification alerts',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      AppLogger.success('Notification scheduled successfully at $scheduledDate', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to schedule notification', error: e, tag: 'NotificationService');
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
