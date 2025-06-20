import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:usage_stats/usage_stats.dart';

class ScreenTimeManager {
  final user = FirebaseAuth.instance.currentUser;
  String? uid;

  Future<void> fetchTodayUsageStats() async {
    uid = user?.uid;

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

    final apps = await InstalledApps.getInstalledApps(false, true, '');

    final appMap = {for (var app in apps) app.packageName: app};

    List<Map<String, dynamic>> appsUsage =
        usageStats.take(10).map((usage) {
          final app = appMap[usage.packageName];
          final durationMs = int.parse(usage.totalTimeInForeground ?? '0');
          final duration = Duration(milliseconds: durationMs);
          final formattedTime =
              "${duration.inHours}h ${(duration.inMinutes % 60)}m";
          return {
            'name': app?.name,
            'screen_time': formattedTime,
            'icon': app?.icon != null ? base64Encode(app!.icon!) : null,
          };
        }).toList();

    final dateString =
        "${endDate.year}-${endDate.month.toString()}-${endDate.day.toString()}";

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('screen_time')
        .doc(dateString)
        .set({'date': Timestamp.fromDate(endDate), 'apps': appsUsage});
    await updateTotalScreenTime();
  }

  Future<void> updateTotalScreenTime() async {
    //final user = FirebaseAuth.instance.currentUser;
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startDate,
      endDate,
    );
    int totalMs = usageStats.fold(0, (suma, item) {
      final ms = int.parse(item.totalTimeInForeground ?? '0');
      return suma + ms;
    });

    int totalMinutes = totalMs ~/ 60000;
    final dateString =
        "${endDate.year}-${endDate.month.toString()}-${endDate.day.toString()}";
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('screen_time')
        .doc(dateString);
    await doc.set({'totalMinutes': totalMinutes}, SetOptions(merge: true));
  }

  //Future<DocumentSnapshot<Map<String, dynamic>>?> getScreenUsage() async {}
}
