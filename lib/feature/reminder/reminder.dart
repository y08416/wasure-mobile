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

  List<Reminder> reminders = [];
  bool _isLoading = true;

  final Map<String, String> categoryEmoji = {
    'work': '💼',
    'personal': '🌸',
    'health': '🏥',
    'other': '🎵',
  };

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

      List<Reminder> loadedReminders = [];
      for (var event in eventsWithItems) {
        final eventId = event['event_id'];
        final eventName = event['name'];
        final eventDateStr = event['reminder_date'];
        DateTime? eventDate;
        if (eventDateStr != null) {
          eventDate = DateTime.parse(eventDateStr);
        }
        for (var item in event['Item']) {
          loadedReminders.add(Reminder(
            id: item['item_id'].toString(),
            eventName: eventName,
            date: eventDate,
            time: _formatTime(eventDate),
            isCompleted: item['is_checked'] ?? false,
            category: item['category'] ?? 'other',
          ));
        }
      }

      setState(() {
        reminders = loadedReminders;
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

  Future<void> showAddReminderDialog() async {
    final TextEditingController eventNameController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String selectedCategory = 'work';
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいリマインダーを追加'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: eventNameController,
                  decoration: const InputDecoration(
                    labelText: 'イベント名',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: '日付 (例: 2024-09-20)',
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                      dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: '時間 (例: 15:30)',
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      timeController.text = pickedTime.format(context);
                    }
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                  ),
                  items: categoryEmoji.keys.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text('${categoryEmoji[category]} $category'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              child: const Text('追加'),
              onPressed: () async {
                if (eventNameController.text.isNotEmpty &&
                    dateController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  try {
                    final userId = _supabase.auth.currentUser?.id;
                    if (userId == null) {
                      throw Exception('ユーザーが認証されていません');
                    }

                    final newEventName = eventNameController.text;
                    final newItemNames = [eventNameController.text];
                    final newEventDate = selectedDate;

                    await _eventItemsApi.addEventAndItems(
                      newEventName,
                      newItemNames,
                      userId,
                      newEventDate,
                    );

                    _loadReminders();
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('リマインダーの追加中にエラーが発生しました: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('リマインダーの追加中にエラーが発生しました: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getCategoryIcon(String category) {
    return categoryEmoji[category] ?? '🎵';
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
        setState(() {
          reminder.date = newDateTime;
        });
        try {
          await _eventItemsApi.updateReminderDate(reminder.id, newDateTime);
          print('リマインダーの日時を更新しました: ${reminder.id}, $newDateTime');
          
          // 通知をスケジュール
          await _scheduleNotification(reminder, newDateTime);
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
        final reminderIndex = reminders.indexWhere((r) => r.id == reminderId);
        if (reminderIndex != -1) {
          reminders[reminderIndex].date = newDateTime;
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

      final scheduledDate = tz.TZDateTime.from(newDateTime, tz.local);

      await _notificationService.scheduleNotification(
        'リマインダー',
        '${reminder.eventName}の確認をお願いします。',
        eventId,
        scheduledDate,
      );

      print('通知がスケジュールされました: $scheduledDate');
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'リマインダー',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.plus, color: Colors.pink),
                      onPressed: showAddReminderDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: AnimatedReminderCard(
                                onTap: () {
                                  // ここにカードをタップしたときの処理を追加
                                  print('Tapped');
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
                                            : Text(
                                                _getCategoryIcon(reminder.category),
                                                style: const TextStyle(fontSize: 30),
                                              ),
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