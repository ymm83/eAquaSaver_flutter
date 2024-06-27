import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
///import 'package:location/location.dart';

import '../utils/snackbar.dart';

class BluetoothOffScreen extends StatefulWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  @override
  State<BluetoothOffScreen> createState() => _BluetoothOffScreenState();
}

class _BluetoothOffScreenState extends State<BluetoothOffScreen> {
  /*late Location location;
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  String _locationStatus = "Unknown";

  @override
  void initState() {
    super.initState();
    location = Location();
    _checkGps();
  }

  Future<void> _checkGps() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _locationStatus = "GPS Service Disabled";
        });
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _locationStatus = "GPS Permission Denied";
        });
        return;
      }
    }

    setState(() {
      _locationStatus = "GPS is Enabled and Permission Granted";
    });
  }*/

  Widget buildBluetoothOffIcon(BuildContext context) {
    return const Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: Colors.white54,
    );
  }

  Widget buildTitle(BuildContext context) {
    String? state = widget.adapterState?.toString().split(".").last;
    return Text(
      'Bluetooth Adapter is ${state ?? 'not available'}',
      style: Theme.of(context).primaryTextTheme.titleSmall?.copyWith(color: Colors.white),
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        child: const Text('TURN ON'),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            Snackbar.show(ABC.a, prettyException("Error Turning On:", e), success: false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA,
      child: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildBluetoothOffIcon(context),
              buildTitle(context),
              if (Platform.isAndroid) buildTurnOnButton(context),
              /*Text(
                _locationStatus,
                style: const TextStyle(fontSize: 20),
              ),*/
              /*Text(
                _isGpsEnabled ? 'GPS is enabled' : 'GPS is disabled',
              ),
              const SizedBox(height: 20),
              Text(
                _isPermissionGranted ? 'Location permission granted' : 'Location permission denied',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkGpsStatus,
                child: const Text('Check GPS Status'),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
