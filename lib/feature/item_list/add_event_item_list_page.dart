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
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: '持ち物',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addEventAndItem,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEventAndItem() async {
    if (_eventController.text.isEmpty || _itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベント名と持ち物を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final result = await _eventItemsApi.addEventAndItem(
        _eventController.text,
        _itemController.text,
        userId,
      );

      // レスポンスを表示
      _showResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('追加完了'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('イベント名: ${result['event']['name']}'),
                Text('イベントID: ${result['event']['event_id']}'),
                Text('持ち物: ${result['item']['name']}'),
                Text('持ち物ID: ${result['item']['item_id']}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, result);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    _itemController.dispose();
    super.dispose();
  }
}