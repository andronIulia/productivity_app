import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/notifications.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/daily_tasks_page.dart';
import 'package:productivity_app/screens/screen_time.dart';

class MyHomePage extends StatefulWidget {
  final Notifications notifications;
  const MyHomePage({super.key, required this.notifications});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  initState() {
    super.initState();
    //widget.notifications.displayNotification('Salut!', 'Test notificare');
  }

  @override
  Widget build(BuildContext context) {
    //return MaterialApp(
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: "Daily tasks"),
              Tab(text: "Other tasks"),
              Tab(text: "Screen time"),
            ],
          ),
          title: const Text('Task Demo'),
          actions: [
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            LoginPage(notifications: widget.notifications),
                  ),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: TabBarView(
          children: [DailyTasksPage(), DailyTasksPage(), ScreenTimePage()],
        ),
      ),
    );
  }
}
