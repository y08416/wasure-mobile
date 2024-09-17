import 'package:flutter/material.dart';
import '../feature/get_item_list/get_item_list.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> navigateToGetItemListPage(int eventId) async {
    print('navigateToGetItemListPage が呼び出されました。eventId: $eventId'); // デバッグ出力を追加
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => GetItemListPage(eventId: eventId),
        ),
      );
    } else {
      print('navigator が null です。'); // デバッグ出力を追加
    }
  }
}