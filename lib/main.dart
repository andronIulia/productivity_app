import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/notification_manager.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/home_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  //final notifications = Notifications();
  final notificationManager = NotificationManager();
  await notificationManager.init();

  //await notifications.initi();
  //await notifications.scheduleDailyTasksRemainder();
  /*try {
    await notifications.initi();
  } catch (e) {
    print('Eroare la initializarea notificărilor: $e');
  }*/

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  //final Notifications notifications;
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Productivity App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: UserApp(),
    );
  }
}

class UserApp extends StatelessWidget {
  //final Notifications notifications;
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return MyHomePage();
    } else {
      return LoginPage();
    }
  }
}
