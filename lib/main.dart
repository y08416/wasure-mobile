import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:firebase_messaging/firebase_messaging.dart';  // 追加
import 'package:wasure_mobaile_futter/firebase_options.dart';
import 'feature/auth/sign_up_page.dart';
import 'feature/home/home_page.dart';
import 'shared/apis/supabase_client.dart';
import 'services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'feature/get_item_list/get_item_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: SupabaseClientWrapper.instance.then((client) => client.auth.currentUser),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return NotificationInitializer(child: HomePage(title: 'ホーム'));
          }
          return SignUpPage();
        },
      ),
    );
  }
}

class NotificationInitializer extends StatefulWidget {
  final Widget child;

  const NotificationInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _NotificationInitializerState createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    // 通知サービスの初期化
    await _notificationService.init(context);

    // FCM の通知権限リクエスト
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // FCMトークンの取得
    String? token = await messaging.getToken();
    if (token != null) {
      print('FCMトークン: $token');
      // サーバーにトークンを送信したり、ローカルに保存したりする処理を追加
      // await sendTokenToServer(token);
    } else {
      print('FCMトークンの取得に失敗しました');
    }

    // トークンがリフレッシュされたときのリスナーを設定
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCMトークンがリフレッシュされました: $newToken');
      // リフレッシュされたトークンをサーバーに送信したり、ローカルに保存したりする処理
      // await sendTokenToServer(newToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}