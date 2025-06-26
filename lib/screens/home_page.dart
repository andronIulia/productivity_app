import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/screens/auth/login_page.dart';
import 'package:productivity_app/screens/daily_tasks_page.dart';
import 'package:productivity_app/screens/other_tasks_page.dart';
import 'package:productivity_app/screens/screen_time.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
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
          title: const Text('Productivity App'),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: Text('Log out'),
                      content: Text('Do you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          child: const Text('Log out'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: TabBarView(
          children: [DailyTasksPage(), OtherTasksPage(), ScreenTimePage()],
        ),
      ),
    );
  }
}
