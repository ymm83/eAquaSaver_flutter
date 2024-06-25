import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/snackbar.dart';

class BluetoothOffScreen extends StatefulWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  @override
  State<BluetoothOffScreen> createState() => _BluetoothOffScreenState();
}

class _BluetoothOffScreenState extends State<BluetoothOffScreen> {
 bool _isGpsEnabled = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
  }

  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    setState(() {
      _isGpsEnabled = serviceEnabled;
      _isPermissionGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    });

    if (!serviceEnabled) {
      _promptEnableGps();
    } else if (!_isPermissionGranted) {
      _requestLocationPermission();
    }
  }

  void _promptEnableGps() async {
    // Implementa aquí la lógica para mostrar un diálogo que pida al usuario activar el GPS
    // En Flutter no hay una manera directa de activar el GPS, debes dirigir al usuario a la configuración
    await Geolocator.openLocationSettings();
  }

  void _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    setState(() {
      _isPermissionGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    });
  }

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
             Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
