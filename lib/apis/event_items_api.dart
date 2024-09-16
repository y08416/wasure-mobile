import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/apis/supabase_client.dart';
import '../feature/reminder/reminder.dart';

class EventItemsApi {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> addEventAndItems(
    String eventName,
    List<String> itemNames,
    String userId,
    DateTime? eventDate,
  ) async {
    try {
      final eventData = {
        'name': eventName,
        'reminder_date': eventDate?.toIso8601String(), // dateをreminder_dateに変更
        'user_id': userId,
      };

      final eventResponse = await _supabase.from('Event').insert(eventData).select().single();

      final itemResponses = await Future.wait(
        itemNames.map((itemName) => _supabase.from('Item').insert({
          'name': itemName,
          'event_id': eventResponse['event_id'],
        }).select().single()),
      );

      return {
        'event': eventResponse,
        'items': itemResponses,
      };
    } catch (e) {
      print('イベントとアイテムの追加中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getItemsForEvent(dynamic eventId, String userId) async {
    final response = await _supabase
        .from('event_items')
        .select('item_id, items(name)')
        .eq('event_id', eventId)
        .eq('user_id', userId);

    return (response as List<dynamic>).map((item) {
      return {
        'item_id': item['item_id'],
        'name': item['items']['name'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getEventsWithItems(String userId) async {
    try {
      final response = await _supabase
          .from('Event')
          .select('event_id, name, reminder_date, Item(*)')
          .eq('user_id', userId)
          .order('reminder_date', ascending: true);

      // レスポンスを適切な形式に変換
      return (response as List<dynamic>).map((event) {
        return {
          'event_id': event['event_id'],
          'name': event['name'],
          'reminder_date': event['reminder_date'],
          'Item': event['Item'] as List<dynamic>,
        };
      }).toList();
    } catch (e) {
      print('イベントとアイテムの取得中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEvents(String userId) async {
    final response = await _supabase
        .from('Event')
        .select('event_id, name, reminder_date')
        .eq('user_id', userId);

    return (response as List<dynamic>).map((event) {
      return {
        'event_id': event['event_id'],
        'name': event['name'],
        'reminder_date': event['reminder_date'],
      };
    }).toList();
  }

  Future<void> updateEventDate(int eventId, DateTime? newDate) async {
    await _supabase
        .from('Event')
        .update({'reminder_date': newDate?.toIso8601String()})
        .eq('event_id', eventId);
  }

  Future<void> updateReminderDate(String reminderId, DateTime newDate) async {
    try {
      // reminderId（item_id）から対応するevent_idを取得
      final item = await _supabase
          .from('Item')
          .select('event_id')
          .eq('item_id', reminderId)
          .single();
      
      final eventId = item['event_id'];

      // Eventテーブルの日付を更新
      await _supabase
          .from('Event')
          .update({'reminder_date': newDate.toIso8601String()}) // dateをreminder_dateに変更
          .eq('event_id', eventId);

      print('リマインダーの日時を更新しました: $reminderId, $newDate');
    } catch (e) {
      print('リマインダーの日時更新中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<List<Reminder>> getUncompletedReminders() async {
    try {
      final response = await _supabase
          .from('Event')
          .select('*, Item(*)')
          .eq('Item.is_checked', false)
          .order('date', ascending: true);

      return response.map((event) {
        final items = event['Item'] as List;
        return items.map((item) => Reminder(
          id: item['item_id'].toString(),
          eventName: event['name'],
          date: DateTime.parse(event['date']),
          time: _formatTime(DateTime.parse(event['date'])),
          isCompleted: item['is_checked'] ?? false,
          category: item['category'] ?? 'other',
        )).toList();
      }).expand((i) => i).toList();
    } catch (e) {
      print('未完了のリマインダーの取得中にエラーが発生しました: $e');
      rethrow;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}