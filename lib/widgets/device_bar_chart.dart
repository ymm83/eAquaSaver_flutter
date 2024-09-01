import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart';

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
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      bData = widget.beaconData;
    });
    debugPrint('------ DeviceBarChart > beaconData.runtimeType: ${bData.runtimeType}');
    debugPrint('------ DeviceBarChart > beaconData: ${bData.toString()}');

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
