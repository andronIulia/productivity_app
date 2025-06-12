import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class ScreenTimePage extends StatefulWidget {
  const ScreenTimePage({super.key});

  @override
  State<ScreenTimePage> createState() => _ScreenTimePageState();
}

class _ScreenTimePageState extends State<ScreenTimePage>
    with WidgetsBindingObserver {
  bool hasPermission = false;
  late SharedPreferences prefs;

  List<UsageInfo> usageData = [];

  /*Future<void> initState() async {
    super.initState();
    checkPermission();
    if (isPermission) {
      await fetchTodayUsageStats();
    }
  }*/
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkPermission();
    }
  }

  void checkPermission() async {
    bool? granted = await UsageStats.checkUsagePermission();
    setState(() {
      hasPermission = granted!;
    });
  }

  /*void initPermissions() async {
    prefs = await SharedPreferences.getInstance();
    bool? storedPermissions = prefs.getBool('hasGrantedUsagePermission');

    if (storedPermissions == true) {
      setState(() {
        hasPermission = true;
      });
    } else {
      bool granted = await UsageStats.checkUsagePermission() ?? false;
      if (granted) {
        await prefs.setBool('hasGrantedUsagePermission', true);
        setState(() {
          hasPermission = true;
        });
      } else {
        setState(() {
          hasPermission = false;
        });
      }
    }
  }*/

  void initPermissions() async {
    bool? granted = await UsageStats.checkUsagePermission();
    prefs = await SharedPreferences.getInstance();
    if (!granted!) {
      //prefs = await SharedPreferences.getInstance();
      bool alreadyRequested =
          prefs.getBool('usagePermissionRequested') ?? false;

      if (!alreadyRequested) {
        //await prefs.setBool('usagePermissionRequested', true);
        //await requestPermission();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Permission Required'),
                  content: Text(
                    'For screen time tracking, Usage Access permission is required.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        requestPermission();
                        prefs.setBool('usagePermissionRequested', true);
                      },
                      child: Text('Open Settings'),
                    ),
                  ],
                ),
          );
        });
      }
    }
    setState(() {
      hasPermission = granted;
    });
  }
  /*checkPermission() async {
    UsageStats.grantUsagePermission();
    bool granted = await UsageStats.checkUsagePermission() ?? false;
    setState(() {
      isPermission = granted;
    });
  }*/

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    }
  }

  fetchTodayUsageStats() async {
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startDate,
      endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Screen Time")),
      body: Center(
        child:
            hasPermission
                ? Text('Permission is granted!')
                : Text('Usage permission not granted.'),
      ),
    );
  }
}
