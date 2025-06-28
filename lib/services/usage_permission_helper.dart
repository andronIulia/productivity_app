import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class UsagePermissionHelper {
  static Future<bool> checkPermission() async {
    return await UsageStats.checkUsagePermission() ?? false;
  }

  static Future<void> requestPermission() async {
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
        // ignore: use_build_context_synchronously
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'For screen time tracking, Usage Access permission is required.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await requestPermission();
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
