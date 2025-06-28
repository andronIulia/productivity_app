import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:productivity_app/models/app_usage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:usage_stats/usage_stats.dart';

class ScreenTimeManager {
  //final user = FirebaseAuth.instance.currentUser;

  Future<void> fetchTodayUsageStats({String? overrideUid}) async {
    final uid = overrideUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    DateTime endDate = tz.TZDateTime.now(tz.local);
    DateTime startDate = tz.TZDateTime(
      tz.local,
      endDate.year,
      endDate.month,
      endDate.day,
    );

    List<EventUsageInfo> events = await UsageStats.queryEvents(
      startDate,
      endDate,
    );
    final Map<String, int> appForegroundTime = {};

    events.sort(
      (a, b) => int.parse(a.timeStamp!).compareTo(int.parse(b.timeStamp!)),
    );

    String? currentPackage;
    int? lastTimestamp;

    for (var event in events) {
      if (event.eventType == '1') {
        currentPackage = event.packageName;
        lastTimestamp = int.tryParse(event.timeStamp ?? '0');
      } else if (event.eventType == '2' &&
          currentPackage != null &&
          lastTimestamp != null) {
        int endTimestamp = int.tryParse(event.timeStamp ?? '0') ?? 0;
        int duration = endTimestamp - lastTimestamp;
        if (duration > 0) {
          appForegroundTime[currentPackage] =
              (appForegroundTime[currentPackage] ?? 0) + duration;
        }
        currentPackage = null;
        lastTimestamp = null;
      }
    }

    if (currentPackage != null && lastTimestamp != null) {
      int duration = endDate.millisecondsSinceEpoch - lastTimestamp;
      if (duration > 0) {
        appForegroundTime[currentPackage] =
            (appForegroundTime[currentPackage] ?? 0) + duration;
      }
    }

    final apps = await InstalledApps.getInstalledApps(false, true, '');
    final appMap = {for (var app in apps) app.packageName: app};

    final excludedPackages = <String>{
      'com.sec.android.app.launcher',
      'com.samsung.android.oneconnect',
      'com.samsung.android.lool',
      'com.google.android.apps.wellbeing',
      'com.android.launcher',
      'com.android.android.forest',
    };

    Map<String, dynamic> appUsageMinutes = {};
    int totalMinutes = 0;

    appForegroundTime.forEach((packageName, timeMs) {
      if (excludedPackages.contains(packageName)) return;
      final timeMinutes = timeMs ~/ 60000;
      if (timeMinutes > 0) {
        final appInfo = appMap[packageName];
        String nameApp = packageName;
        String? iconBase64;
        if (appInfo != null) {
          if (appInfo.name.isNotEmpty) {
            nameApp = appInfo.name;
          }
          if (appInfo.icon != null && appInfo.icon!.isNotEmpty) {
            iconBase64 = base64Encode(appInfo.icon!);
          }
        }
        appUsageMinutes[packageName] = {
          'name': nameApp,
          'minutes': timeMinutes,
          'icon': iconBase64,
        };
        totalMinutes += timeMinutes;
      }
    });

    int sumaAppMinutes = appUsageMinutes.values
        .map((e) => e['minutes'] as int)
        .fold(0, (a, b) => a + b);
    print('Total calculat: $totalMinutes, Suma aplicațiilor: $sumaAppMinutes');

    final dateString = "${endDate.year}-${endDate.month}-${endDate.day}";

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('screen_time')
        .doc(dateString);
    await docRef.set({
      'date': Timestamp.fromDate(endDate),
      'apps': appUsageMinutes,
      'totalMinutes': totalMinutes,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getTodayScreenTimeData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final now = tz.TZDateTime.now(tz.local);
    final dateString = "${now.year}-${now.month}-${now.day}";
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('screen_time')
        .doc(dateString);
    final doc = await docRef.get();
    return doc.exists ? doc.data() : null;
  }

  Future<int> getTodayScreenTime() async {
    final data = await getTodayScreenTimeData();
    return data?['totalMinutes'] ?? 0;
  }

  Future<List<AppUsage>> getTodayAppUsages() async {
    final data = await getTodayScreenTimeData();
    final appsMap = data?['apps'] as Map<String, dynamic>? ?? {};
    final appsList =
        appsMap.entries
            .map(
              (e) => AppUsage.fromMap(e.key, e.value as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.minutes.compareTo(a.minutes));
    return appsList;
  }

  Future<Map<String, int>> getScreenTimeForLastNDays(int days) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final now = DateTime.now();
    Map<String, int> result = {};
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = "${date.year}-${date.month}-${date.day}";
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('screen_time')
              .doc(dateString)
              .get();
      final total = doc.data()?['totalMinutes'] ?? 0;
      result[dateString] = total;
    }
    final sorted = Map.fromEntries(result.entries.toList().reversed);
    return sorted;
  }
}
