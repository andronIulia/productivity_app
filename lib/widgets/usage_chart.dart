import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class UsageChart extends StatelessWidget {
  final List<Uint8List> icons;
  final List<int> durations;
  final List<String> names;

  const UsageChart({
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
          color: Theme.of(context).colorScheme.primary,
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
                  ? Image.memory(icons[index], width: 20, height: 20)
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
