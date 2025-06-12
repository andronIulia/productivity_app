import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/daily_tasks_page.dart';
import 'package:productivity_app/screens/screen_time.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
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
                    MaterialPageRoute(builder: (context) => LoginPage()),
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
      ),
    );
  }
}
