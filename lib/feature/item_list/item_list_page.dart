// lib/feature/item_list/item_list_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wasure_mobaile_futter/feature/reminder/reminder.dart';
import 'package:wasure_mobaile_futter/feature/item_list/add_event_item_list_page.dart';
import '../../apis/event_items_api.dart';
import 'package:intl/intl.dart';
import 'package:wasure_mobaile_futter/feature/get_item_list/get_item_list.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({Key? key}) : super(key: key);

  @override
  _ItemListPageState createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final loadedEvents = await _eventItemsApi.getEvents(userId);
      setState(() {
        events = loadedEvents;
        _isLoading = false;
      });
    } catch (e) {
      print('イベントの読み込み中にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベントの読み込み中にエラーが発生しました')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEventDate(int eventId, DateTime? newDate) async {
    try {
      await _eventItemsApi.updateEventDate(eventId, newDate);
      _loadEvents(); // イベントリストを更新
    } catch (e) {
      print('イベントの日付更新中にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベントの日付更新中にエラーが発生しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントリスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm), // Flutterの標準アラームアイコン
            onPressed: () {
              // ReminderPageへの遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderPage()),
              );
            },
            tooltip: 'リマインダー',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        title: Text(event['name']),
                        subtitle: Text(
                          '日付: ${event['reminder_date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(event['reminder_date'])) : '未設定'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: event['reminder_date'] != null
                                      ? DateTime.parse(event['reminder_date'])
                                      : DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (pickedDate != null) {
                                  _updateEventDate(event['event_id'], pickedDate);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GetItemListPage(eventId: int.parse(event['event_id'].toString())),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEventItemPage()),
                      );
                      _loadEvents(); // 新しいイベントを追加した後、リストを更新
                    },
                    child: const Text('イベントと持ち物を追加'),
                  ),
                ),
              ],
            ),
    );
  }
}
