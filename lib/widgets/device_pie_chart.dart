import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

class DevicePieChart extends StatefulWidget {
  final Map<String, dynamic> beaconData;
  final bool animate;

  const DevicePieChart({super.key, required this.beaconData, this.animate = false});

  @override
  State<DevicePieChart> createState() => _DevicePieChartState();
}

class _DevicePieChartState extends State<DevicePieChart> {
  @override
  Widget build(BuildContext context) {
    List<Series<LinearData, String>> series = [
      Series<LinearData, String>(
        id: 'Water data',
        domainFn: (LinearData data, _) => data.label,
        measureFn: (LinearData data, _) => data.value,
        data: [
          LinearData('Recovered', widget.beaconData['TotalRecovered']),
          LinearData('Hot used', widget.beaconData['totalHotUsed']),
          LinearData('Cold used', widget.beaconData['totalColdUsed']),
        ],
      )
    ];

    return SizedBox(
        height: 100,
        width: 100,
        child: charts.PieChart<String>(
          series,
          animate: widget.animate,
          defaultRenderer: charts.ArcRendererConfig<String>(
            arcWidth: 90,
            arcRendererDecorators: [
              charts.ArcLabelDecorator(
                insideLabelStyleSpec: const charts.TextStyleSpec(fontSize: 12),
                labelPosition: charts.ArcLabelPosition.auto, // Mostrar las etiquetas dentro
              ),
            ],
          ),
          behaviors: [
            charts.DatumLegend(
              position: charts.BehaviorPosition.bottom,
              outsideJustification: charts.OutsideJustification.middleDrawArea,
              horizontalFirst: false,
              cellPadding: const EdgeInsets.only(right: 60.0, left: 40, bottom: 20.0),
              showMeasures: true,
              legendDefaultMeasure: charts.LegendDefaultMeasure.lastValue,
              measureFormatter: (num? value) {
                return value == null ? '-' : '$value L';
              },
            ),
          ],
        ));
  }
}

class LinearData {
  final String label;
  final int value;

  LinearData(this.label, this.value);
}
