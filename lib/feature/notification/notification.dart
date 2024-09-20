import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../../apis/event_items_api.dart';

class NotificationPage extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<NotificationPage> {
  final EventItemsApi _eventItemsApi = EventItemsApi();
  Position? _currentPosition;
  Timer? _timer;
  List<Map<String, dynamic>> item = [];
  @override
  void initState() {
    super.initState();
    // 10秒ごとに位置情報を取得するタイマーを設定
    _timer = Timer.periodic(
        Duration(seconds: 10), (Timer t) => _getCurrentLocation());

    loadItem();
  }

  Future<void> loadItem()async {
     final get_item = await _eventItemsApi.getItemsForEvent(37,"f96b2a3e-e145-4f7d-8e26-3a9cdf6ad526");
    setState(() {
      item = get_item;
    });
  }

  @override
  void dispose() {
    // ウィジェットが破棄された際にタイマーをキャンセル
    _timer?.cancel();
    super.dispose();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効か確認
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // サービスが無効な場合の処理
      print('位置情報サービスが無効です。');
      return;
    }

    // 権限の確認
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('位置情報の権限が拒否されました。');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('位置情報の権限が永久に拒否されました。');
      return;
    }

    // 現在地の取得
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

// 自宅の位置（東京駅を例として使用）
    final homePosition = Position(
      latitude: 35.681236,
      longitude: 139.767125,
      timestamp: DateTime.now(), // 現在の日時を使用
      accuracy: 1.0, // 任意の精度を設定
      altitude: 0.0, // 標高を設定
      altitudeAccuracy: 1.0, // 標高の精度を設定
      heading: 0.0, // 方角を設定
      speed: 0.0, // 速度を設定
      speedAccuracy: 1.0, // 速度の精度を設定
      headingAccuracy: 1.0,
    );

    // 距離を計算する (メートル単位)
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      homePosition.latitude,
      homePosition.longitude,
    );

    // 200メートル以上離れているかを確認
    if (distanceInMeters > 200) {
      print('自宅から200m以上離れています');
      await sendNotification('忘れ物があります', '${item.map((i) => i['name']).join(', \n')}');
    } else {
      print('自宅から200m以内です');
    }

    // 通知を送る

    setState(() {
      _currentPosition = position;
    });

    // 取得した位置情報を表示
    print('位置情報: ${position.latitude}, ${position.longitude}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('10秒ごとに位置情報を取得'),
        ),
        body: Center(
          child: _currentPosition != null
              ? Text(
                  '${item.map((i) => i['name']).join(', \n')}  緯度: ${_currentPosition!.latitude}, 経度: ${_currentPosition!.longitude}')
              : Text('位置情報を取得中...'),
        ),
      ),
    );
  }
}

// 通知を送る関数
Future<void> sendNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id', // チャンネルID
    'your_channel_name', // チャンネル名
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await FlutterLocalNotificationsPlugin().show(
    0, // 通知ID
    title, // 通知のタイトル
    body, // 通知の本文
    platformChannelSpecifics,
  );
}
