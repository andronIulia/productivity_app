import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/index.dart';
import 'package:productivity_app/screens/auth/screen_time_manager.dart';
import 'package:productivity_app/screens/usage_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
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

  late Future<DocumentSnapshot<Map<String, dynamic>>?> updatedUsage;

  late Timer refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    updatedUsage = getScreenUsage();
    initPermissions();
    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) => refreshData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refreshTimer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
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
      await refreshData();
    }
    if (!granted) {
      bool alreadyRequested =
          prefs.getBool('usagePermissionRequested') ?? false;

      if (!alreadyRequested) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
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
    if (!mounted) return;
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

  Future<DocumentSnapshot<Map<String, dynamic>>?> getScreenUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime endDate = tz.TZDateTime.now(tz.local); //DateTime.now();
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
    if (!mounted) return;
    bool? granted = await UsageStats.checkUsagePermission();
    if (granted != true) {
      setState(() => hasPermission = false);
      return;
    }
    if (mounted) setState(() => hasPermission = true);
    await ScreenTimeManager().fetchTodayUsageStats();
    updatedUsage = getScreenUsage();
    if (mounted) setState(() {});
  }

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
                  future: updatedUsage,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text("No usage data.");
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final appsMap = data['apps'] as Map<String, dynamic>? ?? {};

                    final appsList =
                        appsMap.entries.toList()..sort((a, b) {
                          final aMinutes = (a.value['minutes'] as int? ?? 0);
                          final bMinutes = (b.value['minutes'] as int? ?? 0);
                          return bMinutes.compareTo(aMinutes);
                        });

                    //print("appsList: ${appsList.length}");

                    if (showChart) {
                      final appNames =
                          appsList
                              .map((e) => e.value['name'] as String? ?? e.key)
                              .toList();
                      final durations =
                          appsList
                              .map((e) => (e.value['minutes'] as int? ?? 0))
                              .toList();
                      final appIcons =
                          appsList.map((e) {
                            final iconBase64 = e.value['icon'] as String?;
                            return iconBase64 != null
                                ? base64Decode(iconBase64)
                                : Uint8List(0);
                          }).toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 400,
                                  child: UsageChartSf(
                                    icons: appIcons,
                                    durations: durations,
                                    names: appNames,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: appsList.length,
                        itemBuilder: (context, index) {
                          final appEntry = appsList[index];
                          final appName = appEntry.key;
                          final appData =
                              appEntry.value as Map<String, dynamic>;
                          final name = appData['name'];
                          final minutes = appData['minutes'] ?? 0;
                          final iconBase64 = appData['icon'] as String?;
                          final iconBytes =
                              iconBase64 != null
                                  ? base64Decode(iconBase64)
                                  : null;

                          final formattedTime =
                              "${minutes ~/ 60}h ${minutes % 60}m";

                          return ListTile(
                            leading:
                                iconBytes != null
                                    ? Image.memory(
                                      iconBytes,
                                      width: 40,
                                      height: 40,
                                    )
                                    : Icon(Icons.apps),
                            title: Text(name ?? appName),
                            subtitle: Text('Usage: $formattedTime'),
                          );
                        },
                      );
                    }
                  },
                )
                : Text('Usage permission not granted.'),
      ),
    );
  }
}
