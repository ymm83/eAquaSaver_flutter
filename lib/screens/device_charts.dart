import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../bloc/beacon/beacon_bloc.dart';
//import '../widgets/device_bar_chart.dart';
import '../widgets/device_pie_chart.dart';

class DeviceCharts extends StatefulWidget {
  final bool animate;
  final BluetoothDevice? device;
  //final String? role;
  const DeviceCharts({super.key, this.animate = false, this.device}); //, this.role

  @override
  DeviceChartsState createState() => DeviceChartsState();
}

class DeviceChartsState extends State<DeviceCharts> {
  //late Timer beaconTimer;

  @override
  void initState() {
    super.initState();
    //context.read<BeaconBloc>().add(FakeData());
    //beaconTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //context.read<BeaconBloc>().add(FakeData());
    //});
  }

  @override
  void dispose() {
    //beaconTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeaconBloc, BeaconState>(
      builder: (context, state) {
        if (state is BeaconLoaded) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                if (state.beaconData.isEmpty) ...[
                  const Text('No hay datos para mostrar'),
                ],
                if (state.beaconData['totalRecovered'] == 0 &&
                    state.beaconData['totalHotUsed'] == 0 &&
                    state.beaconData['totalColdUsed'] == 0) ...[
                  const Text('No hay datos para mostrar'),
                ],
                if (state.beaconData['totalRecovered'] != 0 ||
                    state.beaconData['totalHotUsed'] != 0 ||
                    state.beaconData['totalColdUsed'] != 0) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints.expand(height: 500.0),
                    child: DevicePieChart(beaconData: state.beaconData),
                  ),
                ],
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
