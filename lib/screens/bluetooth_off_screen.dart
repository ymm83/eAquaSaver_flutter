
import 'dart:async';
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
  bool _locationEnabled = false;
  String _locationStatus = 'Comprobando...';
  String _permissionStatus = 'Comprobando permisos...';
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;
  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _checkLocationServices();
    _listenForServiceStatusChanges();
    _listenForBluetoothStateChanges();
  }

  @override
  void dispose() {
    _serviceStatusStream?.cancel();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationServices() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _locationEnabled = serviceEnabled;
      _locationStatus = serviceEnabled ? 'On' : 'Off';
    });

    // Solicitar permiso de ubicación
    permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _permissionStatus = 'denied';
          });
          return;
        }
        break;
      case LocationPermission.deniedForever:
        setState(() {
          _permissionStatus = 'deniedForever';
        });
        return;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        setState(() {
          _permissionStatus = 'granted';
        });
        break;
      default:
        break;
    }
  }

  void _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    _checkLocationServices();
  }

  void _listenForServiceStatusChanges() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final bool isEnabled = status == ServiceStatus.enabled;
      setState(() {
        _locationEnabled = isEnabled;
        _locationStatus = isEnabled ? 'On' : 'Off';
      });
    });
  }

  void _listenForBluetoothStateChanges() {
    _bluetoothStateSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      setState(() {
        _bluetoothAdapterState = state;
      });
    });
  }

  Widget buildTitle(BuildContext context) {
    String state = _bluetoothAdapterState.toString().split('.').last;
    return Text(
      'Bluetooth Adapter is $state',
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
              _bluetoothAdapterState == BluetoothAdapterState.off
                  ? const Icon(Icons.bluetooth_disabled, size: 100.0, color: Colors.white70)
                  : const Icon(Icons.bluetooth_connected_outlined, size: 100.0, color: Colors.white70),
              buildTitle(context),
              if (Platform.isAndroid) buildTurnOnButton(context),
              _locationEnabled
                  ? const Icon(Icons.location_on_outlined, size: 100, color: Colors.white70)
                  : const Icon(Icons.location_off_outlined, size: 100, color: Colors.white70),
              Text('Ubication status: $_locationStatus',
              style: Theme.of(context).primaryTextTheme.titleSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              Text('Estado de permisos: $_permissionStatus',
              style: Theme.of(context).primaryTextTheme.titleSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _locationEnabled ? null : _openLocationSettings,
                child: const Text('TURN ON'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}