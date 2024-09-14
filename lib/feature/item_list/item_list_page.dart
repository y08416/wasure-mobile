import 'package:flutter/material.dart';
import 'package:wasure_mobaile_futter/feature/item_list/add_event_item_list_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({Key? key}) : super(key: key);

  @override
  _ItemListPageState createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Map<String, String>> eventItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('持ち物リスト'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: eventItems.length,
              itemBuilder: (context, index) {
                final item = eventItems[index];
                return ListTile(
                  title: Text(item['event'] ?? ''),
                  subtitle: Text(item['item'] ?? ''),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEventItemPage()),
                );
                if (result != null) {
                  setState(() {
                    eventItems.add(result);
                  });
                }
              },
              child: const Text('イベントと持ち物を追加'),
            ),
          ),
        ],
      ),
    );
  }
}