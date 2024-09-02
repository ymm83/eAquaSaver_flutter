import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DeviceBarChart extends StatefulWidget {
  final Map<String, dynamic> beaconData;

  const DeviceBarChart({super.key, required this.beaconData});

  @override
  State<DeviceBarChart> createState() => _DeviceBarChartState();
}

class _DeviceBarChartState extends State<DeviceBarChart> {
  late Map<String, dynamic> bData;

  @override
  void initState() {
    super.initState();
    bData = widget.beaconData; // Inicializar bData aquí
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('------ DeviceBarChart > beaconData.runtimeType: ${bData.runtimeType}');
    debugPrint('------ DeviceBarChart > beaconData: ${bData.toString()}');

    return BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: bData['totalRecovered']?.toDouble() ?? 0.0,
                  color: Colors.blue,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: bData['totalHotUsed']?.toDouble() ?? 0.0,
                  color: Colors.red,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: bData['totalColdUsed']?.toDouble() ?? 0.0,
                  color: Colors.blue.shade400,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Recovered');
                    case 1:
                      return const Text('Hot used');
                    case 2:
                      return const Text('Cold used');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: const FlGridData(show: true),
          minY: 100
        ),
    );
  }
}




/*import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart';

class DeviceBarChart extends StatefulWidget {
  final Map<String, dynamic> beaconData;

  const DeviceBarChart({super.key, required this.beaconData});

  @override
  State<DeviceBarChart> createState() => _DeviceBarChartState();
}

class _DeviceBarChartState extends State<DeviceBarChart> {
  @override
  Widget build(BuildContext context) {
    debugPrint('------ DeviceBarChart > beaconData.runtimeType: ${widget.beaconData['TotalRecovered'].runtimeType}');
    debugPrint('------ DeviceBarChart > beaconData: ${widget.beaconData.toString()}');

    List<Series<LinearData, String>> series = [
      Series<LinearData, String>(
        id: 'Water',
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
        height: 130,
        width: 100,
        child: BarChart(
          series,
          behaviors: [
            LinePointHighlighter(
              //seriesIds: const ['10', '20', '30', '40', '50'],
              showHorizontalFollowLine: LinePointHighlighterFollowLineType.none,
              showVerticalFollowLine: LinePointHighlighterFollowLineType.none,
            ),
          ],
          primaryMeasureAxis: const NumericAxisSpec(
            renderSpec: SmallTickRendererSpec(
                // Tick and Label styling here.
                ),
            tickProviderSpec: BasicNumericTickProviderSpec(
              desiredTickCount: 6, // Número de ticks deseados
            ),
            /* tickFormatterSpec: NumericTickFormatterSpec(
              formatter: (value) => '$value°C', // Formato para mostrar grados Celsius
            ),*/
          ),
        ));
  }
}

class LinearData {
  final String label;
  final int value;

  LinearData(this.label, this.value);
}
*/