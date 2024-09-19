import 'package:flutter/material.dart';
import 'package:wasure_mobaile_futter/feature/home/components/home_card.dart';
import 'package:wasure_mobaile_futter/feature/item_list/item_list_page.dart';
import 'package:wasure_mobaile_futter/feature/notification/notification.dart';
import 'package:wasure_mobaile_futter/feature/reminder/reminder.dart';
import 'package:wasure_mobaile_futter/apis/auth_api.dart';
import 'package:wasure_mobaile_futter/feature/auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  List<Widget>? _widgetOptions;
  late AuthAPI _authAPI;

  @override
  void initState() {
    super.initState();
    _initializeAuthAPI();
    _initializeWidgetOptions();
  }

  Future<void> _initializeAuthAPI() async {
    _authAPI = await AuthAPI.create();
  }

  void _initializeWidgetOptions() {
    setState(() {
      _widgetOptions = <Widget>[
        const ItemListPage(),
        _buildHomeContent(),
        const ReminderPage(),
      ];
    });
  }

  Widget _buildHomeContent() {
    return Scaffold(
appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
    body: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildListDelegate([
              HomeCard(
                key: UniqueKey(),
                title: 'リマインド',
                iconPath: 'assets/bell.png',
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReminderPage()),
                  );
                },
              ),
              HomeCard(
                title: '持ち物追加',
                iconPath: 'assets/travel-agency.png',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ItemListPage()),
                  );
                },
              ),
              HomeCard(
                title: '共同',
                iconPath: 'assets/setting.png',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationPage()));
                },
              ),
              HomeCard(
                title: '設定',
                iconPath: 'assets/setting.png',
                color: Colors.orange,
                onTap: () {
                  // 設定画面へのナビゲーション
                },
              ),
            ]),
          ),
        ),
      ],
    )
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _authAPI.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()), // constを削除
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _widgetOptions![_selectedIndex],
      bottomNavigationBar: Container(
        height: 70,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: '持ち物',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              label: 'リマインド',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Color(0xFFE3DCDC), //背景色
        ),
      ),
    );
  }
}
