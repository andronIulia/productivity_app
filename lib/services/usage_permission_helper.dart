import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class UsagePermissionHelper {
  static Future<bool> checkPermission() async {
    return await UsageStats.checkUsagePermission() ?? false;
  }

  static Future<void> requestPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    }
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyRequested = prefs.getBool('usagePermissionRequested') ?? false;

    if (!alreadyRequested) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'For screen time tracking, Usage Access permission is required.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await requestPermission(context);
                    prefs.setBool('usagePermissionRequested', true);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
      );
    }
  }
}
