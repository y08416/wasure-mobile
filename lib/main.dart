import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'feature/auth/sign_up_page.dart';
import 'feature/home/home_page.dart';
import 'shared/apis/supabase_client.dart';
import 'services/notification_service.dart';
import 'package:wasure_mobaile_futter/services/reminder_check_service.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/navigation_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wasure_mobaile_futter/feature/get_item_list/get_item_list.dart'; // GetItemListPageをインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

  final notificationService = NotificationService();
  await notificationService.init();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await notificationService.flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  String? initialPayload;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
    print('アプリが通知から起動されました。ペイロード: $initialPayload');
  }

  runApp(MyApp(initialPayload: initialPayload));
}

class MyApp extends StatefulWidget {
  final String? initialPayload;

  const MyApp({Key? key, this.initialPayload}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _notificationService.setOnNotificationTap((String? payload) {
      if (payload != null) {
        final int eventId = int.parse(payload);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => GetItemListPage(eventId: eventId),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
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
            return HomePage(title: 'ホーム');
          }
          return SignUpPage();
        },
      ),
    );
  }
}