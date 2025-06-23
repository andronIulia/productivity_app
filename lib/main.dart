import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/services/notification_manager.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/home_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  final notificationManager = NotificationManager();
  await notificationManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'My Productivity App',
          theme: ThemeData(
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF5B2A86),
              extendedTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
            colorScheme: lightColorScheme.copyWith(
              primary: Colors.deepPurple,
              secondary: Color(0xFFCE93D8),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            scaffoldBackgroundColor: Color(0xFFF3E5F5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              foregroundColor: Color.fromARGB(255, 156, 135, 159),
              backgroundColor: Color(0xFF5B2A86),
              extendedTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1,
                color: Color(0xFFBA68C8),
              ),
            ),
            colorScheme: darkColorScheme.copyWith(
              primary: Color(0xFF9575CD),
              secondary: Color(0xFFBA68C8),
              surface: Colors.grey[900]!,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: Color(0xFF1E1E1E),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: UserApp(),
        );
      },
    );
  }
}

class UserApp extends StatelessWidget {
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
