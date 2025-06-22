import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:usage_stats/usage_stats.dart';

class ScreenTimeManager {
  final user = FirebaseAuth.instance.currentUser;
  String? uid;

  Future<void> fetchTodayUsageStats() async {
    uid = user?.uid;

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

    /*List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startDate,
      endDate,
    );*/

    /*usageStats =
        usageStats.where((app) {
          final timeMs = int.tryParse(app.totalTimeInForeground ?? '0') ?? 0;
          return timeMs > 0 &&
              app.packageName != null &&
              app.packageName!.isNotEmpty;
        }).toList();*/

    /*usageStats =
        usageStats.where((app) {
          //=>
          //app.totalTimeInForeground != null &&
          //int.tryParse(app.totalTimeInForeground!) != null &&
          //int.parse(app.totalTimeInForeground!) > 0,
          //app.packageName != null && app.packageName!.isNotEmpty,
          // Verifică basic package name
          //if (app.packageName == null || app.packageName!.isEmpty) return false;

          // Acceptă orice aplicație cu timp în foreground, chiar și mic
          //final timeMs = int.tryParse(app.totalTimeInForeground ?? '0') ?? 0;
          //if (timeMs == 0) return false; // Ignoră sub 1 secundă

          // Verifică ultima utilizare doar dacă există
          if (app.lastTimeUsed != null) {
            final lastUsedMillis = int.tryParse(app.lastTimeUsed!) ?? 0;
            if (lastUsedMillis > 0) {
              final lastUsed = DateTime.fromMillisecondsSinceEpoch(
                lastUsedMillis,
              );
              return lastUsed.isAfter(
                startDate.subtract(Duration(hours: 1)),
              ); // Buffer de 1 oră
            }
          }

          return true;
        }).toList();*/

    /*print('==== FILTERED STATS ====');
    for (var app in usageStats) {
      final mins = (int.tryParse(app.totalTimeInForeground!) ?? 0) ~/ 60000;
      print('${app.packageName}: ${mins}min');
    }*/

    /*usageStats.sort(
      (a, b) => int.parse(
        b.totalTimeInForeground!,
      ).compareTo(int.parse(a.totalTimeInForeground!)),
    );*/

    final apps = await InstalledApps.getInstalledApps(false, true, '');

    //final userPackages = apps.map((app) => app.packageName).toSet();

    final appMap = {for (var app in apps) app.packageName: app};
    final excludedPackages = <String>{
      'com.sec.android.app.launcher', // One UI Home
      'com.samsung.android.oneconnect',
      'com.samsung.android.lool', // Digital Wellbeing
      'com.google.android.apps.wellbeing',
      'com.android.launcher',
      // Add more if needed
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
    /*usageStats =
        usageStats
            .where(
              (usage) =>
                  userPackages.contains(usage.packageName) &&
                  usage.packageName != null &&
                  usage.packageName!.isNotEmpty,
            )
            .toList();

    Map<String, dynamic> appUsageMinutes = {};
    int totalMinutes = 0;

    final excludedPackages = <String>{
      'com.sec.android.app.launcher', // One UI Home
      'com.samsung.android.oneconnect',
      'com.samsung.android.lool', // Digital Wellbeing
      'com.google.android.apps.wellbeing',
      'com.android.launcher',

      //'com.samsung.android.forest',
    };

    final filteredUsage =
        usageStats.where((usage) {
          final pkg = usage.packageName ?? '';
          return !excludedPackages.contains(pkg);
        }).toList();

    for (var usage in filteredUsage) {
      final packageName = usage.packageName;
      final appInfo = appMap[packageName];

      //final nameApp = appInfo?.name ?? packageName;

      final timeMs = int.tryParse(usage.totalTimeInForeground ?? '0') ?? 0;
      final timeMinutes = timeMs ~/ 60000;
      //debugPrint('$timeMinutes minute');
      if (timeMinutes > 0 && packageName != null) {
        //final nameApp = appInfo?.name ?? packageName;
        String nameApp = packageName;
        String? iconBase64;
        if (appInfo != null) {
          if (appInfo.name.isNotEmpty) {
            nameApp = appInfo.name;
          }
          if (appInfo.icon != null && appInfo.icon!.isNotEmpty) {
            iconBase64 = base64Encode(appInfo.icon!);
          }
        } else {
          print("App not found in installed list: $packageName");
        }
        appUsageMinutes[packageName] = {
          'name': nameApp,
          'minutes': timeMinutes,
          'icon': iconBase64,
        };

        //print("Saved app: $packageName ($nameApp) = $timeMinutes min");

        totalMinutes += timeMinutes;
      }
    }*/

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
}
