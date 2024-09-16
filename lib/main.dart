import 'package:flutter/material.dart';
import 'package:wasure_mobaile_futter/services/notification_service.dart';
import 'package:wasure_mobaile_futter/services/reminder_check_service.dart';
import 'feature/auth/sign_up_page.dart';
import 'feature/home/home_page.dart';
import 'shared/apis/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  ReminderCheckService().startReminderCheck();
  await SupabaseClientWrapper.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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