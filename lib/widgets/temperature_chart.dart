import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart';

class TemperatureChart extends StatelessWidget {
  final Map<String, dynamic> beaconData;

  const TemperatureChart({super.key, required this.beaconData});

  @override
  Widget build(BuildContext context) {
    List<Series<TemperatureData, String>> series = [
      Series<TemperatureData, String>(
        id: 'Temperaturas',
        domainFn: (TemperatureData data, _) => data.label,
        measureFn: (TemperatureData data, _) => data.value,
        data: [
          TemperatureData('Actual', beaconData['temperature']),
          TemperatureData('Caliente', beaconData['hotTemperature']),
          TemperatureData('Fría', beaconData['coldTemperature']),
        ],
      )
    ];

    return Expanded(
        flex: 0,
        child: SizedBox(
            height: 200,
            width: 300,
            child: BarChart(
              series,
              behaviors: [
                LinePointHighlighter(
                  showHorizontalFollowLine: LinePointHighlighterFollowLineType.nearest,
                  showVerticalFollowLine: LinePointHighlighterFollowLineType.nearest,
                ),
              ],
              primaryMeasureAxis: const NumericAxisSpec(
                tickProviderSpec: BasicNumericTickProviderSpec(
                  desiredTickCount: 6, // Número de ticks deseados
                ),
                /* tickFormatterSpec: NumericTickFormatterSpec(
              formatter: (value) => '$value°C', // Formato para mostrar grados Celsius
            ),*/
              ),
            )));
  }
}

class TemperatureData {
  final String label;
  final double value;

  TemperatureData(this.label, this.value);
}
