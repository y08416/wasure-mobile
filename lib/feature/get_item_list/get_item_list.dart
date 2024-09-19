import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class GetItemListPage extends StatefulWidget {
  final int eventId;

  const GetItemListPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _GetItemListPageState createState() => _GetItemListPageState();
}

class _GetItemListPageState extends State<GetItemListPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _newTaskController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];
  Map<int, bool> _checkedItems = {};
  List<String> _suggestedItems = [];
  DateTime? _selectedDate;
  Timer? _debounce;

  // フラグを追加
  bool _isProgrammaticallySettingText = false;

  @override
  void initState() {
    super.initState();
    _loadEventAndItems();
    _eventNameController.addListener(_onEventNameChanged);
  }

  void _onEventNameChanged() {
    if (_isProgrammaticallySettingText) return; // フラグが立っている場合は無視

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_eventNameController.text.isNotEmpty) {
        _updateEventName(_eventNameController.text);
        _generateSuggestedItems();
      }
    });
  }

  Future<void> _loadEventAndItems() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final eventData = await _eventItemsApi.getEventById(widget.eventId);
      final items = await _eventItemsApi.getItemsForEvent(widget.eventId, userId);
      setState(() {
        // テキスト設定前にフラグを立てる
        _isProgrammaticallySettingText = true;
        _eventNameController.text = eventData['name'] ?? '';
        _isProgrammaticallySettingText = false;

        _selectedDate = eventData['reminder_date'] != null 
            ? DateTime.parse(eventData['reminder_date']) 
            : null;
        _items = items;
        _initializeCheckedItems();
        _isLoading = false;
      });
      _generateSuggestedItems();
    } catch (e) {
      print('イベントとアイテムの読み込み中にエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSuggestedItems() async {
    final url = Uri.parse('https://api.dify.ai/v1/chat-messages');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer app-nnj7Ol5mQWD825PEqsQyw2kf'
    };
    final currentItems = _items.map((item) => item['name']).join(', ');
    final body = jsonEncode({
      'inputs': {},
      'query': '${_eventNameController.text}\n現在のアイテム: $currentItems\n追加で必要な持ち物:',
      'response_mode': 'streaming',
      'conversation_id': '',
      'user': 'user'
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final List<String> generatedItems = [];
        final lines = response.body.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = jsonDecode(line.substring(6));
            if (data['event'] == 'message') {
              final content = data['answer'] as String;
              if (content.isNotEmpty) {
                generatedItems.addAll(content.split('\n').where((item) => item.trim().isNotEmpty).toList());
              }
            }
          }
        }
        setState(() {
          _suggestedItems = generatedItems.where((item) => !_items.any((existingItem) => existingItem['name'] == item)).toList();
        });
      } else {
        print('Failed to generate items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating items: $e');
    }
  }

  void _initializeCheckedItems() {
    _checkedItems = {
      for (int i = 0; i < _items.length; i++) i: _items[i]['is_checked'] ?? false,
    };
  }

  Future<void> _addItem(String itemName) async {
    if (itemName.isNotEmpty) {
      try {
        final newItem = await _eventItemsApi.addItemToEvent(widget.eventId, itemName);
        setState(() {
          _items.add(newItem);
          _checkedItems[_items.length - 1] = false;
          _suggestedItems.remove(itemName);
          _newTaskController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイテムが追加されました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイテムの追加中にエラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(int index) async {
    try {
      await _eventItemsApi.removeItemFromEvent(widget.eventId, _items[index]['item_id']);
      setState(() {
        _items.removeAt(index);
        _checkedItems.remove(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイテムが削除されました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイテムの削除中にエラーが発生しました: $e')),
      );
    }
  }

  Future<void> _updateItemStatus(int index, bool value) async {
    try {
      await _eventItemsApi.updateItemStatus(widget.eventId, _items[index]['item_id'], value);
      setState(() {
        _checkedItems[index] = value;
        _items[index]['is_checked'] = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイテムのステータス更新中にエラーが発生しました: $e')),
      );
    }
  }

  Future<void> _updateEventName(String newName) async {
    try {
      await _eventItemsApi.updateEventName(widget.eventId, newName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベント名が更新されました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベント名の更新中にエラーが発生しました: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateEventDate(picked);
    }
  }

  Future<void> _updateEventDate(DateTime newDate) async {
    try {
      await _eventItemsApi.updateEventDate(widget.eventId, newDate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベント日付が更新されました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベント日付の更新中にエラーが発生しました: $e')),
      );
    }
  }

  // 新たに追加する「忘れ物提案ボタン」とそのダイアログ表示
  void _showSuggestedItemsDialog() {
    if (_suggestedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提案されたアイテムがありません')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('忘れそうな持ち物'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestedItems.length,
              itemBuilder: (context, index) {
                final item = _suggestedItems[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: Icon(Icons.add, color: Color(0xFF8B4513)),
                    onPressed: () {
                      _addItem(item);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('閉じる', style: TextStyle(color: Color(0xFF8B4513))),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          backgroundColor: Color(0xFFFFF8E7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('イベントの編集'),
        backgroundColor: Color(0xFF8B4513),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb, color: Colors.white),
            onPressed: _showSuggestedItemsDialog,
            tooltip: '忘れ物を提案',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _eventNameController,
                decoration: InputDecoration(
                  labelText: 'イベント名',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B4513)),
                  ),
                ),
                style: TextStyle(color: Color(0xFF8B4513)),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? '日付未選択'
                          : '選択された日付: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(color: Color(0xFF8B4513)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text('日付を選択'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFE4B5),
                      foregroundColor: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // 既存のサジェストされたアイテム表示部分はそのまま
              Text(
                'おすすめアイテム:',
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
                        hintText: '新しいアイテムを入力...',
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
                                  if (value != null) {
                                    _updateItemStatus(index, value);
                                  }
                                },
                                activeColor: Color(0xFF8B4513),
                              ),
                              title: Text(
                                item['name'] ?? '名称なし',
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.removeListener(_onEventNameChanged);
    _eventNameController.dispose();
    _newTaskController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
