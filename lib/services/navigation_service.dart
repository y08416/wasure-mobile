import 'package:flutter/material.dart';
import '../feature/get_item_list/get_item_list.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  

  static Future<void> navigateToGetItemListPage(int eventId) async {
  print('GetItemListPage へのナビゲーションを開始します。eventId: $eventId');
  final navigator = navigatorKey.currentState;
  print('navigatorKey.currentState: $navigator');
  if (navigator != null) {
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => GetItemListPage(eventId: eventId),
      ),
    );
  } else {
    print('ナビゲーターがまだ初期化されていません。再試行します。');
    Future.delayed(Duration(milliseconds: 100), () => navigateToGetItemListPage(eventId));
  }
}

}