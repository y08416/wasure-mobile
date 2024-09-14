import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/apis/supabase_client.dart';

class EventItemsApi {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> addEventAndItem(String eventName, String itemName, String userId) async {
    Map<String, dynamic>? eventResponse;
    try {
      // イベントの追加
      eventResponse = await _supabase
          .from('Event')
          .insert({
            'name': eventName,
            'user_id': userId,
          })
          .select()
          .single();

      if (eventResponse == null) {
        throw Exception('Failed to create event');
      }

      final eventId = eventResponse['event_id'];

      if (eventId == null) {
        throw Exception('Failed to generate event_id');
      }

      // 持ち物の追加
      final itemResponse = await _supabase
          .from('Item')
          .insert({
            'name': itemName,
            'event_id': eventId,
            'is_checked': false,
          })
          .select()
          .single();

      return {
        'event': {
          'event_id': eventResponse['event_id'],
          'name': eventResponse['name'],
          'user_id': eventResponse['user_id'],
          // 他のイベント関連のフィールドがあれば追加
        },
        'item': {
          'item_id': itemResponse['item_id'],
          'name': itemResponse['name'],
          'event_id': itemResponse['event_id'],
          'is_checked': itemResponse['is_checked'],
          // 他の持ち物関連のフィールドがあれば追加
        },
      };
    } catch (e) {
      print('Error adding event and item: $e');
      // エラーが発生した場合、イベントを削除する（ロールバックの代替）
      if (eventResponse != null && eventResponse['event_id'] != null) {
        await _supabase
            .from('Event')
            .delete()
            .eq('event_id', eventResponse['event_id']);
      }
      rethrow;
    }
  }
}