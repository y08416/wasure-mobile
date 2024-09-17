import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'feature/auth/sign_up_page.dart';
import 'feature/home/home_page.dart';
import 'shared/apis/supabase_client.dart';
import 'services/notification_service.dart';
import 'package:wasure_mobaile_futter/services/reminder_check_service.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();  // ここでタイムゾーンを初期化
  await NotificationService().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Brand.ai',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
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