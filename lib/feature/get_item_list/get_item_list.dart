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
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];
  Map<int, bool> _checkedItems = {};
  TextEditingController _newTaskController = TextEditingController();
  List<String> _suggestedItems = ['充電器', 'パソコン', '名刺', '書類'];
  String _eventName = ''; // イベント名を保持する変数を追加

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadEventName(); // イベント名を読み込むメソッドを呼び出す
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final items = await _eventItemsApi.getItemsForEvent(widget.eventId, userId);
      setState(() {
        _items = items;
        _isLoading = false;
        _initializeCheckedItems();
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

  // イベント名を取得するメソッドを追加
  Future<void> _loadEventName() async {
    try {
      final eventName = await _eventItemsApi.getEventName(widget.eventId);
      setState(() {
        _eventName = eventName;
      });
    } catch (e) {
      print('イベント名の読み込み中にエラーが発生しました: $e');
    }
  }

  void _initializeCheckedItems() {
    _checkedItems = {
      for (int i = 0; i < _items.length; i++) i: false,
    };
  }

  void _addItem(String itemName) {
    if (itemName.isNotEmpty) {
      setState(() {
        _items.add({'name': itemName, 'description': ''});
        _checkedItems[_items.length - 1] = false;
      });
      _newTaskController.clear();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _checkedItems.remove(index);
    });
  }

  void _completeAllTasks() {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _checkedItems[i] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _eventName.isNotEmpty ? _eventName : 'イベントTodoリスト',
                style: TextStyle(fontSize: 24, color: Color(0xFF8B4513)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'サジェストされたアイテム:',
                style: TextStyle(color: Color(0xFF8B4513)),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestedItems.map((item) => ElevatedButton(
                  child: Text(item),
                  onPressed: () => _addItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFE4B5),
                    foregroundColor: Color(0xFF8B4513),
                  ),
                )).toList(),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTaskController,
                      decoration: InputDecoration(
                        hintText: '新しいタスクを入力...',
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF8B4513)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    child: Text('+'),
                    onPressed: () => _addItem(_newTaskController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            color: Color(0xFFFFE4B5),
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Checkbox(
                                value: _checkedItems[index] ?? false,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _checkedItems[index] = value!;
                                  });
                                },
                                activeColor: Color(0xFF8B4513),
                              ),
                              title: Text(item['name'] ?? '名称なし',
                                style: TextStyle(fontSize: 20, color: Color(0xFF8B4513)),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, color: Color(0xFF8B4513)),
                                onPressed: () => _removeItem(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.star),
                label: Text('全タスク完了'),
                onPressed: _completeAllTasks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFE4B5),
                  foregroundColor: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}