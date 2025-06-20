import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/notifications.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notifications = Notifications();
  await notifications.initi();
  await notifications.scheduleDailyTasksRemainder();
  /*try {
    await notifications.initi();
  } catch (e) {
    print('Eroare la initializarea notificărilor: $e');
  }*/

  runApp(MyApp(notifications: notifications));
}

class MyApp extends StatelessWidget {
  final Notifications notifications;
  const MyApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Productivity App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: UserApp(notifications: notifications),
    );
  }
}

class UserApp extends StatelessWidget {
  final Notifications notifications;
  const UserApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return MyHomePage(notifications: notifications);
    } else {
      return LoginPage(notifications: notifications);
    }
  }
}
