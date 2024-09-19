import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';

class GetItemListPage extends StatefulWidget {
  final int eventId;

  const GetItemListPage({Key? key, required this.eventId}) : super(key: key); // requiredを追加

  @override
  _GetItemListPageState createState() => _GetItemListPageState();
}

class _GetItemListPageState extends State<GetItemListPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  final SupabaseClient _supabase = Supabase.instance.client;
   bool _isLoading = false; // ここで_isLoadingをbool型で宣言
  List<Map<String, dynamic>> _items = [];
  Map<int, bool> _checkedItems = {}; // チェックボックスの状態を管理するためのMap


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
         _initializeCheckedItems(); // チェックボックスの初期状態を設定
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
  // チェックボックスの初期状態をfalseに設定
  void _initializeCheckedItems() {
    _checkedItems = {
      for (int i = 0; i < _items.length; i++) i: false,
    };
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテムリスト'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('アイテムがありません'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                         leading: Checkbox(
                        value: _checkedItems[index] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            _checkedItems[index] = value!;
                          });
                        },
                      ),
                      title: Text(item['name'] ?? '名称なし',
                      style: const TextStyle(fontSize: 20), // タイトルの文字サイズを20に変更
                      ),
                      subtitle: Text(item['description'] ?? '説明なし',
                      style: const TextStyle(fontSize: 16), // サブタイトルの文字サイズを16に変更
                    ),
                    );
                  },
                ),
    );
  }
}