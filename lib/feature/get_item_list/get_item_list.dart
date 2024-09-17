import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';

class GetItemListPage extends StatefulWidget {
  final int eventId;

  const GetItemListPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _GetItemListPageState createState() => _GetItemListPageState();
}

class _GetItemListPageState extends State<GetItemListPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('GetItemListPage が初期化されました。eventId: ${widget.eventId}'); // デバッグ出力を追加
    _loadItems(); // initState()でアイテムを読み込む
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final items = await _eventItemsApi.getItemsForEvent(widget.eventId, userId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('アイテムの読み込み中にエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アイテムリスト'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('アイテムがありません'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item['name'] ?? '名称なし'),
                      subtitle: Text(item['description'] ?? '説明なし'),
                    );
                  },
                ),
    );
  }
}