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

  // JSONからReminderオブジェクトを作成するファクトリメソッド
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      eventName: json['event_name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: json['time'],
      isCompleted: json['is_completed'],
      category: json['category'],
    );
  }

  // ReminderオブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_name': eventName,
      'date': date?.toIso8601String(),
      'time': time,
      'is_completed': isCompleted,
      'category': category,
    };
  }
}