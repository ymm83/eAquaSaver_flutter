import 'package:eaquasaver/bloc/connectivity/connectivity_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../provider/supabase_provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class DeviceSettings extends StatefulWidget {
  final BluetoothDevice? device;

  const DeviceSettings({super.key, this.device});

  @override
  DeviceSettingsState createState() => DeviceSettingsState();
}

class DeviceSettingsState extends State<DeviceSettings> {
  double _value = 50;

  double _firstPointer = 30;
  double _secondPointer = 70;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future addTargetTemperature(int temperature) async {
    //supabaseEAS.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOnline) {
          return Column(
            children: [
              Center(child: Text('Temperature entries:')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('minimal'),
                  SfLinearGauge(
                    markerPointers: [
                      LinearShapePointer(
                        value: _value,
                        onChangeStart: (double newValue) {
                          _value = newValue;
                        },
                        onChanged: (double newValue) {
                          setState(() {
                            _value = newValue;
                          });
                        },
                        onChangeEnd: (double newValue) {
                          _value = newValue;
                        },
                        shapeType: LinearShapePointerType.invertedTriangle,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SfLinearGauge(
                    ranges: <LinearGaugeRange>[
                                    LinearGaugeRange(
                                        startValue: 0,
                                        endValue: 20,
                                        color: Colors.blue,
                                        endWidth: 0.03,
                                        startWidth: 0.03),
                                    LinearGaugeRange(
                                        startValue: 20,
                                        endValue: 30,
                                        color: Colors.yellow,
                                        endWidth: 0.03,
                                        startWidth: 0.03),
                                    LinearGaugeRange(
                                        startValue: 30,
                                        endValue: 50,
                                        color: Colors.red,
                                        endWidth: 0.03,
                                        startWidth: 0.03),
                                  ],
                    markerPointers: [
                      LinearShapePointer(
                        value: _firstPointer,
                        height: 25,
                        width: 25,
                        shapeType: LinearShapePointerType.invertedTriangle,
                        dragBehavior: LinearMarkerDragBehavior.constrained,
                        onChanged: (double newValue) {
                          setState(() {
                            _firstPointer = newValue;
                          });
                        },
                      ),
                      LinearShapePointer(
                        value: _secondPointer,
                        height: 25,
                        width: 25,
                        shapeType: LinearShapePointerType.invertedTriangle,
                        dragBehavior: LinearMarkerDragBehavior.constrained,
                        onChanged: (double newValue) {
                          setState(() {
                            _secondPointer = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ), 
            ],
          );
        } else if (state is ConnectivityOffline) {
          return const Text('Sin conexión!');
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
