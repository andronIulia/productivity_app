import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:device_installed_apps/app_info.dart';
//import 'package:device_installed_apps/device_installed_apps.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/index.dart';
import 'package:productivity_app/screens/auth/screen_time_manager.dart';
import 'package:productivity_app/screens/usage_chart.dart';
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
  List<AppInfo> apps = [];
  Map<String, AppInfo> appMap = {};

  List<String> appName = [];
  List<int> appDuration = [];
  bool showChart = false;

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
    if (state == AppLifecycleState.resumed) {
      //checkPermission();
      refreshData();
    }
  }

  void checkPermission() async {
    bool? granted = await UsageStats.checkUsagePermission();
    setState(() {
      hasPermission = granted!;
    });
  }

  void initPermissions() async {
    bool? granted = await UsageStats.checkUsagePermission();
    prefs = await SharedPreferences.getInstance();
    if (granted!) {
      await ScreenTimeManager().fetchTodayUsageStats();
    }
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

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    }
  }

  /*Future<Map<UsageInfo, AppInfo?>> fetchTodayUsageStats() async {
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startDate,
      endDate,
    );

    usageStats =
        usageStats
            .where(
              (app) =>
                  app.totalTimeInForeground != null &&
                  int.tryParse(app.totalTimeInForeground!) != null &&
                  int.parse(app.totalTimeInForeground!) > 0,
            )
            .toList();

    usageStats.sort(
      (a, b) => int.parse(
        b.totalTimeInForeground!,
      ).compareTo(int.parse(a.totalTimeInForeground!)),
    );

    apps = await InstalledApps.getInstalledApps(false, true, '');

    /*setState(() {
      usageData = usageStats.take(10).toList();
    });*/
    appMap = {for (var app in apps) app.packageName: app};
    //await getAppsInfo();
    Map<UsageInfo, AppInfo?> usageWithApps = {
      for (var usage in usageStats.take(10)) usage: appMap[usage.packageName],
    };
    screenTimeChart();
    return usageWithApps;
  }*/

  Future<DocumentSnapshot<Map<String, dynamic>>?> getScreenUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime endDate = DateTime.now();
    final dateString =
        "${endDate.year}-${endDate.month.toString()}-${endDate.day.toString()}";
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('screen_time')
        .doc(dateString);
    final doc = await docRef.get();
    if (doc.exists) return doc;
    return null;
  }

  void screenTimeChart() {
    appName.clear();
    appDuration.clear();

    for (var usage in usageData) {
      final packageName = usage.packageName;
      final appInfo = appMap[packageName];
      final name = appInfo?.name ?? packageName;
      final timeMs = int.tryParse(usage.totalTimeInForeground ?? '0') ?? 0;
      final timeMinutes = timeMs ~/ 60000;
      appName.add(name!);
      appDuration.add(timeMinutes);
    }
  }

  Future<void> refreshData() async {
    /*final granted = await UsageStats.checkUsagePermission();
    setState(() {
      hasPermission = granted!;
    });*/
    if (hasPermission) {
      await ScreenTimeManager().fetchTodayUsageStats();
      setState(() {});
    }
  }

  /*Future<void> getAppsInfo() async {
    apps = await InstalledApps.getInstalledApps(false, true, '');
    appMap = {for (var app in apps) app.packageName: app};
    setState(() {});
  }*/

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Screen Time")),
      body: Center(
        child:
            hasPermission
                ? usageData.isEmpty
                    ? CircularProgressIndicator()
                    : ListView.builder(
                      itemCount: usageData.length,
                      itemBuilder: (context, index) {
                        final usage = usageData[index];
                        final app = appMap[usage.packageName];
                        final durationMs = int.parse(
                          usage.totalTimeInForeground ?? '0',
                        );
                        final duration = Duration(microseconds: durationMs);
                        final formattedTime =
                            "${duration.inHours}h ${(duration.inMinutes % 60)}";
                        return ListTile(
                          leading:
                              app?.icon != null
                                  ? Image.memory(
                                    app!.icon!,
                                    width: 40,
                                    height: 40,
                                  )
                                  : Icon(Icons.apps),
                          title: Text(app?.name ?? usage.packageName!),
                          subtitle: Text('Usage: $formattedTime'),
                        );
                      },
                    )
                : Text('Usage permission not granted.'),
      ),
    );
  }
}*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Screen Time"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showChart = !showChart;
              });
            },
            icon: Icon(showChart ? Icons.list : Icons.bar_chart),
          ),
        ],
      ),
      body: Center(
        child:
            hasPermission
                ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                  future: getScreenUsage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text("No usage data.");
                    }

                    final usageWithApps = snapshot.data!.data();
                    final appsList = usageWithApps?['apps'] ?? [];
                    //final totalMinutes = usageWithApps?['totalMinutes'];
                    final appNames =
                        appsList.map((e) => e['name'] ?? 'Uknown').toList();
                    final durations =
                        appsList.map((e) {
                          final time = e['screen_time'] as String;
                          final match = RegExp(
                            r'(\d+)h\s+(\d+)m',
                          ).firstMatch(time);
                          final hours =
                              int.tryParse(match?.group(1) ?? '0') ?? 0;
                          final minutes =
                              int.tryParse(match?.group(2) ?? '0') ?? 0;
                          return hours * 60 + minutes;
                        }).toList();

                    return showChart
                        ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: UsageChart(
                            name: List<String>.from(appNames),
                            durations: List<int>.from(durations),
                          ),
                        )
                        : ListView.builder(
                          itemCount: appsList.length,
                          itemBuilder: (context, index) {
                            //final usage = appsList[index].key;
                            final app = appsList[index];
                            final icon = app['icon'];
                            final iconBytes =
                                icon != null ? base64Decode(icon) : null;
                            //final durationMs = int.parse(
                            //usage.totalTimeInForeground ?? '0',
                            //);
                            //final duration = Duration(milliseconds: durationMs);
                            //final formattedTime =
                            //  "${duration.inHours}h ${(duration.inMinutes % 60)}m";

                            return ListTile(
                              leading:
                                  iconBytes != null
                                      ? Image.memory(
                                        iconBytes,
                                        width: 40,
                                        height: 40,
                                      )
                                      : Icon(Icons.apps),
                              title: Text(app['name'] ?? 'unknown'),
                              subtitle: Text('Usage: ${app['screen_time']}'),
                            );
                          },
                        );
                  },
                )
                : Text('Usage permission not granted.'),
      ),
    );
  }
}
