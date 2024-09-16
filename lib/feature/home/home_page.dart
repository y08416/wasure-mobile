import 'package:flutter/material.dart';
import 'package:wasure_mobaile_futter/feature/home/components/home_card.dart';
import 'package:wasure_mobaile_futter/feature/item_list/item_list_page.dart'; // 新しいインポート
import 'package:wasure_mobaile_futter/feature/reminder/reminder.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Widget>? _widgetOptions;

  @override
  void initState() {
    super.initState();
    _initializeWidgetOptions();
  }

  void _initializeWidgetOptions() {
    setState(() {
      _widgetOptions = <Widget>[
        _buildHomeContent(),
        const Text('月毎カレンダー画面'),
        const Text('リマインド画面'),
      ];
    });
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75, // 高さを調整
            ),
            delegate: SliverChildListDelegate([
              HomeCard(
                key: UniqueKey(), // ユニークなキーを追加
                title: 'リマインド',
                iconPath: 'assets/bell.png', // PNGアイコンのパス
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReminderPage()),
                  );
                },
              ),
              HomeCard(
                title: '持ち物追加',
                iconPath: 'assets/travel-agency.png',
                color: Colors.blue,
                onTap: () {
                  // 持ち物リストへのナビゲーション
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ItemListPage()),
                  );
                },
              ),
              HomeCard(
                title: '共同',
                iconPath: 'assets/setting.png', // PNGアイコンのパス（仮）
                color: Colors.green,
                onTap: () {
                  // 共同機能へのナビゲーション
                },
              ),
              HomeCard(
                title: '設定',
                iconPath: 'assets/setting.png', // PNGアイコンのパス
                color: Colors.orange,
                onTap: () {
                  // 設定画面へのナビゲーション
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildHomeContent(), // 直接_buildHomeContent()を呼び出す
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '月毎カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'リマインド',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
