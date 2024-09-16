import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';

class GetItemListPage extends StatefulWidget {
  final Map<String, dynamic> addedEventItem;

  const GetItemListPage({Key? key, required this.addedEventItem}) : super(key: key);

  @override
  _GetItemListPageState createState() => _GetItemListPageState();
}

class _GetItemListPageState extends State<GetItemListPage> {
  final _eventItemsApi = EventItemsApi();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final eventId = widget.addedEventItem['event']['event_id'];
      print('Loading items for event: $eventId and user: $userId'); // デバッグ情報
      final items = await _eventItemsApi.getItemsForEvent(eventId, userId);
      print('Loaded items: $items'); // デバッグ情報
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e'); // デバッグ情報
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('イベントの持ち物リスト'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text('イベント名: ${widget.addedEventItem['event']['name']}'),
                  subtitle: Text('イベントID: ${widget.addedEventItem['event']['event_id']}'),
                ),
                Divider(),
                ListTile(
                  title: Text('追加したアイテム: ${widget.addedEventItem['item']['name']}'),
                  subtitle: Text('アイテムID: ${widget.addedEventItem['item']['item_id']}'),
                ),
                Divider(),
                Text('その他のアイテム:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._items.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text('アイテムID: ${item['item_id']}'),
                    )),
              ],
            ),
    );
  }
}