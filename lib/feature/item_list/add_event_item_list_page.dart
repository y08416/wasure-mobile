import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AddEventItemPage extends StatefulWidget {
  const AddEventItemPage({Key? key}) : super(key: key);

  @override
  _AddEventItemPageState createState() => _AddEventItemPageState();
}

class _AddEventItemPageState extends State<AddEventItemPage> {
  final _eventController = TextEditingController();
  final _itemController = TextEditingController();
  final _eventItemsApi = EventItemsApi();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  DateTime? _selectedDate;
  List<String> _suggestedItems = [];
  List<String> _selectedItems = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _eventController.addListener(_onEventNameChanged);
  }

  void _onEventNameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1600), () {
      if (_eventController.text.isNotEmpty) {
        _generateItems(_eventController.text);
      }
    });
  }

  Future<void> _generateItems(String eventName) async {
    setState(() => _isLoading = true);
    final url = Uri.parse('https://api.dify.ai/v1/chat-messages');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer app-nnj7Ol5mQWD825PEqsQyw2kf'
    };
    final body = jsonEncode({
      'inputs': {},
      'query': '$eventName\n必要な持ち物:',
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
          _suggestedItems = generatedItems;
          _isLoading = false;
        });
      } else {
        print('Failed to generate items: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error generating items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('イベントと持ち物を追加'),
        backgroundColor: Color(0xFF8B4513),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _eventController,
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
              Text(
                'サジェストされたアイテム:',
                style: TextStyle(color: Color(0xFF8B4513)),
              ),
              SizedBox(height: 8),
              _isLoading
                  ? CircularProgressIndicator()
                  : Wrap(
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
                      controller: _itemController,
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
                    onPressed: () => _addItem(_itemController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedItems.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: Color(0xFFFFE4B5),
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(_selectedItems[index],
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
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate == null
                        ? '日付未選択'
                        : '選択された日付: ${_formatDate(_selectedDate!)}',
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
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('イベントと持ち物を追加'),
                onPressed: _isLoading ? null : _addEventAndItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFE4B5),
                  foregroundColor: Color(0xFF8B4513),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem(String itemName) {
    if (itemName.isNotEmpty) {
      setState(() {
        _selectedItems.add(itemName);
        _itemController.clear();
        _suggestedItems.remove(itemName);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
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
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addEventAndItems() async {
    if (_eventController.text.isEmpty || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベント名と少なくとも1つの持ち物を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final result = await _eventItemsApi.addEventAndItems(
        _eventController.text,
        _selectedItems,
        userId,
        _selectedDate,
      );

      Navigator.pop(context, result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _eventController.removeListener(_onEventNameChanged);
    _eventController.dispose();
    _itemController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}