import 'dart:async';
import 'package:wasure_mobaile_futter/apis/event_items_api.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReminderCheckService {
  static final ReminderCheckService _instance = ReminderCheckService._internal();
  factory ReminderCheckService() => _instance;
  ReminderCheckService._internal();

  final EventItemsApi _eventItemsApi = EventItemsApi();
  final NotificationService _notificationService = NotificationService();
  Timer? _timer;

  void startReminderCheck() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _checkReminders());
  }

  void stopReminderCheck() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkReminders() async {
    try {
      final reminders = await _eventItemsApi.getUncompletedReminders();
      for (final reminder in reminders) {
        final eventDate = DateTime.parse(reminder['reminder_date']);
        if (eventDate.isBefore(DateTime.now())) {
          await _notificationService.showNotification(
            id: reminder['id'] ?? 0, // リマインダーのIDを使用
            title: '通知タイトル',
            body: '通知本文',
            eventId: reminder['event_id'] ?? 0, // イベントのIDを渡す
          );
        }
      }
    } catch (e) {
      print('リマインダーのチェック中にエラーが発生しました: $e');
    }
  }

  Future<void> _scheduleNotification(Map<String, dynamic> reminder) async {
    tz.initializeTimeZones();  // タイムゾーンを初期化
    final localTimeZone = tz.getLocation('Asia/Tokyo');  // あなたのローカルタイムゾーンに変更してください

    final eventDate = tz.TZDateTime.from(
      DateTime.parse(reminder['reminder_date']),
      localTimeZone,
    );

    final now = tz.TZDateTime.now(localTimeZone);

    if (eventDate.isAfter(now)) {
      try {
        await _notificationService.scheduleNotification(
          id: 0, // または適切なID
          title: '通知タイトル',
          body: '通知本文',
          scheduledDate: eventDate,
          payload: 'ペイロード',
        );
        print('通知がスケジュールされました: ${eventDate.toString()}');
      } catch (e) {
        print('通知のスケジューリング中にエラーが発生しまし: $e');
      }
    } else {
      print('スケジュールされた日時が過去のため、通知はスケジュールされませんでした: ${eventDate.toString()}');
    }
  }

  Future<void> checkAndNotify() async {
    try {
      final reminders = await _eventItemsApi.getUncompletedReminders();
      for (var reminder in reminders) {
        // eventIdを取得する方法を適切に修正
        int eventId = reminder['event_id'] ?? 0; // 仮の実装。実際のデータ構造に合わせて修正してください。

        await _notificationService.showNotification(
          id: reminder['id'] ?? 0,
          title: '通知タイトル',
          body: '通知本文',
          eventId: eventId,
        );
      }
    } catch (e) {
      print('リマインダーのチェック中にエラーが発生しました: $e');
    }
  }
}