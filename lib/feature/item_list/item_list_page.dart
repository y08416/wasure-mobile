// lib/feature/item_list/item_list_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wasure_mobaile_futter/feature/reminder/reminder.dart';
import 'package:wasure_mobaile_futter/feature/item_list/add_event_item_list_page.dart';
import '../../apis/event_items_api.dart';
import 'package:intl/intl.dart';
import 'package:wasure_mobaile_futter/feature/get_item_list/get_item_list.dart';
import 'package:wasure_mobaile_futter/feature/item_list/components/event_card.dart';
import 'dart:math';
import 'package:flutter/material.dart';


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


  //取得シテルノデケサナイ

  @override
  Widget build(BuildContext context) {
        // 固定の色リストを作成
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
    ];
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
                  child: GridView.builder(
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2列表示に変更
                    crossAxisSpacing: 10.0, // 列間のスペース
                    mainAxisSpacing: 10.0, // 行間のスペース
                    childAspectRatio: 1.0, // 各アイテムの縦横比
                  ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                         // 色リストからランダムに選択
                      final randomColor = colors[Random().nextInt(colors.length)];
                      return EventCard(
                        key: UniqueKey(), // ユニークなキーを追加 
                        title:  event['name'],
                        iconPath: 'assets/bell.png', // PNGアイコンのパス
                        width: 10, // 横幅を親の幅に合わせる
                        height: 200, // 高さを設定
                        color: randomColor, // ランダムな色を設定
                        onTap: () {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GetItemListPage(eventId: int.parse(event['event_id'].toString())),
                                  ),                          );
                       },
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
                   setState(() {
                      _loadEvents(); // 新しいイベントを追加した後、リストを更新
                    });
                  },
                   style: ElevatedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 70), // 幅と高さを設定
                   textStyle: const TextStyle(fontSize: 20), // テキストサイズを設定
                   backgroundColor: const Color(0xFFD6BDF0),
    ),
                    child: const Text('イベントと持ち物を追加'),
                  ),
                ),
              ],
            ),
    );
  }
}
