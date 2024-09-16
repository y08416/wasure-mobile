import 'dart:async';
import 'package:wasure_mobaile_futter/apis/event_items_api.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';

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
        if (!reminder.isCompleted) {
          await _notificationService.showNotification(
            'リマインダー',
            '${reminder.eventName}の確認をお願いします。',
          );
        }
      }
    } catch (e) {
      print('リマインダーのチェック中にエラーが発生しました: $e');
    }
  }
}