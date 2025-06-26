import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:productivity_app/services/screen_time_manager.dart';
import 'package:productivity_app/models/app_usage.dart';
import 'package:productivity_app/services/usage_permission_helper.dart';
import 'package:productivity_app/widgets/usage_chart.dart';
import 'package:productivity_app/widgets/weekly_chart.dart';

class ScreenTimePage extends StatefulWidget {
  const ScreenTimePage({super.key});

  @override
  State<ScreenTimePage> createState() => _ScreenTimePageState();
}

class _ScreenTimePageState extends State<ScreenTimePage>
    with WidgetsBindingObserver {
  bool hasPermission = false;
  bool showChart = false;
  final screenTimeManager = ScreenTimeManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPermissions();
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshData();
    }
  }

  Future<void> _initPermissions() async {
    final granted = await UsagePermissionHelper.checkPermission();
    setState(() => hasPermission = granted);
    if (!granted && mounted) {
      await UsagePermissionHelper.showPermissionDialog(context);
      final grantedAfter = await UsagePermissionHelper.checkPermission();
      setState(() => hasPermission = grantedAfter);
    }
    if (hasPermission) {
      await _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final granted = await UsagePermissionHelper.checkPermission();
    setState(() => hasPermission = granted);
    if (granted) {
      await screenTimeManager.fetchTodayUsageStats();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Screen Time"),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() => showChart = !showChart);
              await _refreshData();
            },
            icon: Icon(showChart ? Icons.list : Icons.bar_chart),
          ),
        ],
      ),
      body: Center(
        child:
            hasPermission
                ? FutureBuilder<List<AppUsage>>(
                  future: screenTimeManager.getTodayAppUsages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("No usage data.");
                    }
                    final appsList = snapshot.data!;
                    if (showChart) {
                      final appNames = appsList.map((e) => e.name).toList();
                      final durations = appsList.map((e) => e.minutes).toList();
                      final appIcons =
                          appsList.map((e) {
                            return e.iconBase64 != null
                                ? base64Decode(e.iconBase64!)
                                : Uint8List(0);
                          }).toList();
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
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
                                      const Text(
                                        "Screen time pe aplicații (azi)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 300,
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
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              child: FutureBuilder<Map<String, int>>(
                                future: screenTimeManager
                                    .getScreenTimeForLastNDays(7),
                                builder: (context, weeklySnapshot) {
                                  if (weeklySnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!weeklySnapshot.hasData ||
                                      weeklySnapshot.data!.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        "Nu există date pentru ultimele 7 zile.",
                                      ),
                                    );
                                  }
                                  return WeeklyScreenTimeChart(
                                    data: weeklySnapshot.data!,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: appsList.length,
                        itemBuilder: (context, index) {
                          final app = appsList[index];
                          final iconBytes =
                              app.iconBase64 != null
                                  ? base64Decode(app.iconBase64!)
                                  : null;
                          final formattedTime =
                              "${app.minutes ~/ 60}h ${app.minutes % 60}m";
                          return ListTile(
                            leading:
                                iconBytes != null && iconBytes.isNotEmpty
                                    ? Image.memory(
                                      iconBytes,
                                      width: 40,
                                      height: 40,
                                    )
                                    : const Icon(Icons.apps),
                            title: Text(app.name),
                            subtitle: Text('Usage: $formattedTime'),
                          );
                        },
                      );
                    }
                  },
                )
                : const Text('Usage permission not granted.'),
      ),
    );
  }
}
