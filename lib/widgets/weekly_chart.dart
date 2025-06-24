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
              height: 300,
              child: SfCartesianChart(
                tooltipBehavior: TooltipBehavior(enable: true),
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(fontSize: 12),
                  maximum:
                      (totals.reduce((a, b) => a > b ? a : b) * 1.2)
                          .ceilToDouble(),
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
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      overflowMode: OverflowMode.shift,
                      textStyle: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      //labelAlignment: ChartDataLabelAlignment.top,
                    ),
                    dataLabelMapper: (i, _) {
                      final total = totals[i];
                      final hours = total ~/ 60;
                      final minutes = total % 60;
                      if (hours > 0) {
                        return "${hours}h${minutes > 0 ? ' ${minutes}m' : ''}";
                      } else {
                        return "${minutes}m";
                      }
                    },
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
