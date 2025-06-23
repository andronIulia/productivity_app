import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeeklyScreenTimeChart extends StatelessWidget {
  final Map<String, int> data;
  const WeeklyScreenTimeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final days = data.keys.toList();
    final totals = data.values.toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Screen time total pe ultimele 7 zile",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<int, String>(
                    dataSource: List.generate(days.length, (i) => i),
                    xValueMapper: (i, _) {
                      final parts = days[i].split('-');
                      return "${parts[2]}.${parts[1]}";
                    },
                    yValueMapper: (i, _) => totals[i],
                    color: Theme.of(context).colorScheme.primary,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
