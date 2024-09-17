import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  Future<void> scheduleNotification(
    String title,
    String body,
    int eventId,
    tz.TZDateTime scheduledDate,
  ) async {
    final now = tz.TZDateTime.now(scheduledDate.location);
    if (scheduledDate.isBefore(now)) {
      print('指定された日時が過去のため、通知をスケジュールできません: ${scheduledDate.toString()}');
      return;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      eventId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: eventId.toString(),
    );
    print('通知がスケジュールされました: ${scheduledDate.toString()}');
  }

  Future<void> showNotification(String title, String body, int eventId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: eventId.toString(),
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    print('通知がタップされました。ペイロード: $payload'); // デバッグ出力を追加
    if (payload != null) {
      _handleNotificationTap(int.parse(payload));
    }
  }

  void _handleNotificationTap(int eventId) {
    print('_handleNotificationTap が呼び出されました。eventId: $eventId'); // デバッグ出力を追加
    NavigationService.navigateToGetItemListPage(eventId);
  }
}