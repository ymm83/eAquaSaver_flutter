import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DevicePieChart extends StatefulWidget {
  final Map<String, dynamic> beaconData;
  final bool animate;

  const DevicePieChart({super.key, required this.beaconData, this.animate = false});

  @override
  State<DevicePieChart> createState() => _DevicePieChartState();
}

class _DevicePieChartState extends State<DevicePieChart> {
  late Map<String, dynamic> bData;

  @override
  void initState() {
    super.initState();
    bData = widget.beaconData;
  }

  @override
  Widget build(BuildContext context) {
    final totalRecovered = bData['totalRecovered']?.toDouble() ?? 0.0;
    final totalHotUsed = bData['totalHotUsed']?.toDouble() ?? 0.0;
    final totalColdUsed = bData['totalColdUsed']?.toDouble() ?? 0.0;

    if (totalRecovered == 0 && totalHotUsed == 0 && totalColdUsed == 0) {
      return const Text('No hay datos para mostrar');
    }

    return Column(
      children: [
        const SizedBox(
          height: 60,
        ),
        SizedBox(
          height: 200,
          width: 200,
          child: PieChart(
            PieChartData(
              sections: [
                if (totalRecovered > 0)
                  PieChartSectionData(
                    color: Colors.blue,
                    value: totalRecovered,
                    title: '${totalRecovered.toInt()} L',
                    radius: 140,
                    titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                if (totalHotUsed > 0)
                  PieChartSectionData(
                    color: Colors.red,
                    value: totalHotUsed,
                    title: '${totalHotUsed.toInt()} L',
                    radius: 140,
                    titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                if (totalColdUsed > 0)
                  PieChartSectionData(
                    color: Colors.green,
                    value: totalColdUsed,
                    title: '${totalColdUsed.toInt()} L',
                    radius: 140,
                    titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
              ],
              borderData: FlBorderData(show: false),
              centerSpaceRadius: 0,
              sectionsSpace: 8, // Espaciado entre secciones
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 120,
          width: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, 'Total of water recovered', ''),
              const SizedBox(height: 16), // Espacio entre elementos de la leyenda
              _buildLegendItem(Colors.red, 'Total of hot water used', ''),
              const SizedBox(height: 16), // Espacio entre elementos de la leyenda
              _buildLegendItem(Colors.green, 'Total of cold water used', ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, dynamic value) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text('$label $value'),
      ],
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class DevicePieChart extends StatefulWidget {
//   final Map<String, dynamic> beaconData;
//   final bool animate;

//   const DevicePieChart({super.key, required this.beaconData, this.animate = false});

//   @override
//   State<DevicePieChart> createState() => _DevicePieChartState();
// }

// class _DevicePieChartState extends State<DevicePieChart> {
//   late Map<String, dynamic> bData;

//   @override
//   void initState() {
//     super.initState();
//     bData = widget.beaconData; // Inicializar bData aquí
//     bData = {
//       'totalRecovered': 30,
//       'totalHotUsed': 50,
//       'totalColdUsed': 20,
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 200,
//       width: 200,
//       child: PieChart(
//         PieChartData(
//           sections: [
//             PieChartSectionData(
//               color: Colors.blue,
//               value: bData['totalRecovered']?.toDouble() ?? 0.0,
//               title: bData['totalRecovered'] > 0 ? '${bData['totalRecovered']?.toInt()}' : '',
//               radius: 120,
//               titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
//             ),
//             PieChartSectionData(
//               color: Colors.red,
//               value: bData['totalHotUsed']?.toDouble() ?? 0.0,
//               title: bData['totalHotUsed'] > 0 ? '${bData['totalHotUsed']?.toInt()}' : '',
//               radius: 120,
//               titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
//             ),
//             PieChartSectionData(
//               color: Colors.green,
//               value: bData['totalColdUsed']?.toDouble() ?? 0.0,
//               title: bData['totalColdUsed'] > 0 ? '${bData['totalColdUsed']?.toInt()}' : '',
//               radius: 120,
//               titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
//             ),
//           ],
//           borderData: FlBorderData(show: false),
//           centerSpaceRadius: 0,
//           sectionsSpace: 8,
//         ),
//       ),
//     );
//   }
// }
