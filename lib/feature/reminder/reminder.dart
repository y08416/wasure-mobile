// lib/feature/reminder/reminder.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../apis/event_items_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class Reminder {
  final String id;
  final String eventName;
  DateTime? date;
  final String time;
  bool isCompleted;
  final String category;

  Reminder({
    required this.id,
    required this.eventName,
    this.date,
    required this.time,
    required this.isCompleted,
    required this.category,
  });
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({Key? key}) : super(key: key);

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  Map<String, Reminder> eventReminders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void didUpdateWidget(covariant ReminderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final eventsWithItems = await _eventItemsApi.getEventsWithItems(userId);

      Map<String, Reminder> loadedEventReminders = {};
      for (var event in eventsWithItems) {
        final eventId = event['event_id'].toString();
        final eventName = event['name'];
        final eventDateStr = event['reminder_date'];
        DateTime? eventDate;
        if (eventDateStr != null) {
          eventDate = DateTime.parse(eventDateStr);
        }

        // イベントごとに1つのリマインダーを作成
        loadedEventReminders[eventId] = Reminder(
          id: eventId,
          eventName: eventName,
          date: eventDate,
          time: _formatTime(eventDate),
          isCompleted: false, // イベント全体の完了状態は別途管理する必要があります
          category: 'other', // カテゴリーはイベント全体で1つにする必要があります
        );
      }

      setState(() {
        eventReminders = loadedEventReminders;
        _isLoading = false;
      });
    } catch (e) {
      print('リマインダーの読み込み中にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リマインダーの読み込み中にエラーが発生しました: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return '${DateFormat('M月d日').format(date)} ${DateFormat('HH:mm').format(date)}';
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    setState(() {
      reminder.isCompleted = !reminder.isCompleted;
    });
    // ここでデータベースの更新処理を追加する必要があります
    // 例: await _eventItemsApi.updateReminderStatus(reminder.id, reminder.isCompleted);
  }

  Future<void> _showDateTimePicker(Reminder reminder) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: reminder.date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(reminder.date ?? DateTime.now()),
      );
      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        try {
          final updated = await _eventItemsApi.updateReminderDate(reminder.id, newDateTime);
          if (updated) {
            setState(() {
              reminder.date = newDateTime;
            });
            print('リマインダーの日時を更新しました: ${reminder.id}, $newDateTime');
            await _scheduleNotification(reminder, newDateTime);
          } else {
            throw Exception('リマインダーの更新に失敗しました');
          }
        } catch (e) {
          print('リマインダーの日時更新中にエラーが発生しました: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('リマインダーの更新に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateReminderDate(String reminderId, DateTime newDateTime) async {
    try {
      // ここでデータベースの更新処理を実装します
      // 例: await _eventItemsApi.updateReminderDate(reminderId, newDateTime);
      
      // 更新が成功したら、ローカルのリマインダーストも更新します
      setState(() {
        final reminderIndex = eventReminders.values.toList().indexWhere((r) => r.id == reminderId);
        if (reminderIndex != -1) {
          eventReminders.values.toList()[reminderIndex].date = newDateTime;
        }
      });
    } catch (e) {
      print('リマインダーの日時更新中にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リマインダーの日時更新中にエラーが発生しました: $e')),
      );
    }
  }

  Future<void> _scheduleNotification(Reminder reminder, DateTime newDateTime) async {
    try {
      final eventId = int.tryParse(reminder.id);
      if (eventId == null) {
        print('無効なリマインダーID: ${reminder.id}');
        return;
      }

      await _notificationService.scheduleNotification(
        id: eventId,
        title: 'リマインダー',
        body: '${reminder.eventName}の確認をお願いします。',
        scheduledDate: tz.TZDateTime.from(newDateTime, tz.local),
        payload: reminder.id,
      );

      print('通知のスケジューリングが完了しました');
    } catch (e) {
      print('通知のスケジューリング中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F7),  // 上部の色（ピンク）
              Color(0xFFF3E8FF),  // 下部の色（薄紫）
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'リマインダー',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: eventReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = eventReminders.values.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 88, // ここでカードの高さを指定
                                width: 100,
                                child: AnimatedReminderCard(
                                  onTap: () {
                                    print('Tapped event: ${reminder.id}');
                                  },
                                  child: ListTile(
                                    leading: GestureDetector(
                                      onTap: () => _toggleReminder(reminder),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: reminder.isCompleted ? Colors.green[100] : Colors.pink[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: reminder.isCompleted
                                              ? Icon(LucideIcons.bell, color: Colors.green, size: 30)
                                              : Icon(LucideIcons.bell, color: Colors.pink, size: 30), // カテゴリーアイコンの代わりにベルアイコンを使用
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      reminder.eventName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatDateTime(reminder.date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(LucideIcons.calendar, color: Colors.pink),
                                      onPressed: () => _showDateTimePicker(reminder),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedReminderCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedReminderCard({
    Key? key,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  @override
  _AnimatedReminderCardState createState() => _AnimatedReminderCardState();
}

class _AnimatedReminderCardState extends State<AnimatedReminderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 1.03 : 1.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}