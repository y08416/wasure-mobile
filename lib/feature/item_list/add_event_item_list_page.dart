import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../apis/event_items_api.dart';

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
  List<String> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントと持ち物を追加'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                labelText: 'イベント名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: '持ち物',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_items[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeItem(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedDate == null
                      ? '日付未選択'
                      : '選択された日付: ${_formatDate(_selectedDate!)}'),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('日付を選択'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addEventAndItems,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _items.add(_itemController.text);
        _itemController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
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
    if (_eventController.text.isEmpty || _items.isEmpty) {
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
        _items,
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
    _eventController.dispose();
    _itemController.dispose();
    super.dispose();
  }
}