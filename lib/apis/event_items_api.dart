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

  Future<List<Map<String, dynamic>>> getItemsForEvent(int eventId, String userId) async {
    final response = await _supabase
        .from('Item')
        .select('item_id, name')
        .eq('event_id', eventId);

    return (response as List<dynamic>).map((item) {
      return {
        'item_id': item['item_id'],
        'name': item['name'],
      };
    }).toList();
  }

  Future<String> getEventName(int eventId) async {
    try {
      final response = await _supabase
          .from('Event')
          .select('name')
          .eq('event_id', eventId)
          .single();
      
      return response['name'] as String;
    } catch (e) {
      print('イベント名の取得中にエラーが発生しました: $e');
      return '';
    }
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

    Future<void> updateEventName(int eventId, String newName) async {
    try {
      await _supabase
          .from('Event')
          .update({'name': newName})
          .eq('event_id', eventId);
    } catch (e) {
      print('イベント名の更新中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<void> addItemToEvent(int eventId, String itemName) async {
    try {
      await _supabase.from('Item').insert({
        'name': itemName,
        'event_id': eventId,
      });
    } catch (e) {
      print('アイテムの追加中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<void> updateItemStatus(int eventId, String itemName, bool isCompleted) async {
  try {
    await _supabase
        .from('Item')
        .update({'is_checked': isCompleted})
        .eq('event_id', eventId)
        .eq('name', itemName);
  } catch (e) {
    print('アイテムのステータス更新中にエラーが発生しました: $e');
    rethrow;
  }
}

  Future<void> removeItemFromEvent(int eventId, String itemName) async {
    try {
      await _supabase
          .from('Item')
          .delete()
          .eq('event_id', eventId)
          .eq('name', itemName);
    } catch (e) {
      print('アイテムの削除中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<bool> updateReminderDate(String eventId, DateTime newDateTime) async {
    try {
      final response = await _supabase
          .from('Event')
          .update({'reminder_date': newDateTime.toIso8601String()})
          .eq('event_id', eventId)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      print('リマインダーの日時更新中にエラーが発生しました: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUncompletedReminders() async {
    final response = await _supabase
      .from('Event')
      .select('''
        event_id,
        name,
        reminder_date,
        Item (
          item_id,
          is_checked
        )
      ''')
      .not('reminder_date', 'is', null)
      .order('reminder_date');

    return response.where((event) {
      // イベントに紐づく全てのアイテムがチェックされていない場合のみ、未完了とする
      return (event['Item'] as List).any((item) => item['is_checked'] != true);
    }).toList();
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

    Future<Map<String, dynamic>> getEventById(int eventId) async {
    try {
      final response = await _supabase
          .from('Event')
          .select()
          .eq('event_id', eventId)
          .single();
      return response;
    } catch (e) {
      print('イベントの取得中にエラーが発生しました: $e');
      rethrow;
    }
  }

  Future<void> updateEventAndItems(
    int eventId,
    String eventName,
    List<String> itemNames,
    String userId,
    DateTime? eventDate,
  ) async {
    try {
      // イベントの更新
      await _supabase.from('Event').update({
        'name': eventName,
        'reminder_date': eventDate?.toIso8601String(),
        'user_id': userId,
      }).eq('event_id', eventId);

      // 既存のアイテムを取得
      final existingItems = await _supabase
          .from('Item')
          .select('item_id, name')
          .eq('event_id', eventId);

      // 新しいアイテムを追加
      for (var itemName in itemNames) {
        if (!existingItems.any((item) => item['name'] == itemName)) {
          await _supabase.from('Item').insert({
            'name': itemName,
            'event_id': eventId,
          });
        }
      }

      // 削除されたアイテムを削除
      for (var existingItem in existingItems) {
        if (!itemNames.contains(existingItem['name'])) {
          await _supabase
              .from('Item')
              .delete()
              .eq('item_id', existingItem['item_id']);
        }
      }
    } catch (e) {
      print('イベントとアイテムの更新中にエラーが発生しました: $e');
      rethrow;
    }
  }
}