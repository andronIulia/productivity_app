//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
/*import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UsageChart extends StatelessWidget {
  final List<String> name;
  final List<int> durations;
  final List<Uint8List> icons;

  const UsageChart({
    super.key,
    required this.name,
    required this.durations,
    required this.icons,
  });

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
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < name.length) {
                    final iconBytes =
                        icons.length > index ? icons[index] : null;
                    return SideTitleWidget(
                      space: 8,
                      meta: meta,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (iconBytes != null)
                            Image.memory(iconBytes, width: 24, height: 24)
                          else
                            Icon(Icons.apps, size: 24),
                          const SizedBox(height: 2),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${name[group.x]}: ${durations[group.x]} min',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}*/
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class UsageChartSf extends StatelessWidget {
  final List<Uint8List> icons;
  final List<int> durations;
  final List<String> names;

  const UsageChartSf({
    super.key,
    required this.icons,
    required this.durations,
    required this.names,
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(fontSize: 0),
        majorTickLines: const MajorTickLines(size: 0),
        axisLabelFormatter: (details) {
          return ChartAxisLabel('', null);
        },
      ),
      primaryYAxis: NumericAxis(labelStyle: const TextStyle(fontSize: 12)),
      series: <CartesianSeries>[
        ColumnSeries<int, String>(
          dataSource: List.generate(durations.length, (i) => i),
          xValueMapper: (i, _) => i.toString(),
          yValueMapper: (i, _) => durations[i],
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],

      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (
          dynamic data,
          dynamic point,
          dynamic series,
          int pointIndex,
          int seriesIndex,
        ) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Text('${names[pointIndex]}: ${durations[pointIndex]} min'),
          );
        },
      ),
      annotations: List<CartesianChartAnnotation>.generate(icons.length, (
        index,
      ) {
        return CartesianChartAnnotation(
          widget:
              icons[index].isNotEmpty
                  ? Image.memory(icons[index], width: 28, height: 28)
                  : Icon(Icons.apps, size: 28, color: Colors.grey),
          coordinateUnit: CoordinateUnit.point,
          region: AnnotationRegion.chart,
          x: index.toString(),
          y: 0,
          verticalAlignment: ChartAlignment.near,
        );
      }),
    );
  }
}
