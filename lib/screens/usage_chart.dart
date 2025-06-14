import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UsageChart extends StatelessWidget {
  final List<String> name;
  final List<int> durations;

  const UsageChart({super.key, required this.name, required this.durations});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(durations.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: durations[index].toDouble(),
                  color: Colors.blueAccent,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < name.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        name[index].length > 6
                            ? '${name[index].substring(0, 6)}…'
                            : name[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }
}
