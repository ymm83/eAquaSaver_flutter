import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/snackbar_helper.dart';

class BluetoothOffScreen extends StatefulWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  @override
  State<BluetoothOffScreen> createState() => _BluetoothOffScreenState();
}

class _BluetoothOffScreenState extends State<BluetoothOffScreen> {
  bool _locationEnabled = false;
  String _locationStatus = '...';
  String _permissionStatus = '...';
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;
  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    _checkLocationServices();
    _listenForServiceStatusChanges();
    _listenForBluetoothStateChanges();
    super.initState();
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

  Future _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    _checkLocationServices();
  }

  void _listenForServiceStatusChanges() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final bool isEnabled = status == ServiceStatus.enabled;
      debugPrint('------- status: $status');
      setState(() {
        _locationEnabled = isEnabled;
        _locationStatus = status == ServiceStatus.enabled ? 'On' : 'Off';
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

  Widget buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 30, color: Colors.grey.shade600),
    );
  }

  Widget buildSubtitle(BuildContext context) {
    String state = _bluetoothAdapterState.toString().split('.').last;
    return Text(
      'State: $state',
      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ElevatedButton(
        child: const Text('TURN ON'),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            showSnackBar("Error Turning On: $e", theme: 'error');
          }
        },
      ),
    );
  }

  Widget buildTurnOnLoction(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          activeTrackColor: Colors.grey.shade700,
          title: buildTitle('Location'),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'State: ${_locationStatus == 'On' ? 'On' : 'Off'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Permission: $_permissionStatus',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              )
            ],
          ),

          value: _locationStatus == 'On' ? true : false, // Usamos la variable de estado
          onChanged: (bool value) async {
            if (!_locationEnabled) {
              if (Platform.isAndroid) {
                await Geolocator.openLocationSettings();
                _checkLocationServices();
              }
            }
          },

          secondary: _locationEnabled
              ? Icon(Icons.location_on_outlined, size: 50, color: Colors.blue.shade700)
              : Icon(Icons.location_off_outlined, size: 50, color: Colors.grey.shade400),
        );
      },
    );
  }

  Widget buildTurnOnBluetooth(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          activeTrackColor: Colors.blue.shade700,
          title: buildTitle('Bluetooth'),
          subtitle: buildSubtitle(context),
          value: _bluetoothAdapterState == BluetoothAdapterState.on ? true : false, // Usamos la variable de estado
          onChanged: (bool value) async {
            try {
              if (Platform.isAndroid) {
                await FlutterBluePlus.turnOn();
              }
            } catch (e) {
              showSnackBar("Error Turning On: $e", theme: 'error');
            }
          },
          secondary: _bluetoothAdapterState == BluetoothAdapterState.on
              ? Icon(Icons.bluetooth_connected_outlined, size: 50.0, color: Colors.blue.shade700)
              : Icon(Icons.bluetooth_disabled, size: 50.0, color: Colors.grey.shade400),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Alinea los widgets en la parte superior
          children: <Widget>[
            // Texto "Required!" sin Padding innecesario
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 0, top: 0, right: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Ícono de advertencia
                        // Contenedor con el texto
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100, // Color de fondo
                            borderRadius: BorderRadius.circular(20), // Bordes redondeados
                          ),
                          width: MediaQuery.of(context).size.width * 0.8,
                          margin: EdgeInsets.only(top: 0, left: 20, right: 0),
                          padding: EdgeInsets.fromLTRB(50, 10, 10, 10),

                          // Limita el ancho del contenedor

                          child: Text(
                            'services.required'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).appBarTheme.backgroundColor,
                            ),
                            softWrap: true, // Permite que el texto se divida en varias líneas
                          ),
                        ),
                        Positioned(
                          left: -3,
                          top: 50,
                          child: Icon(
                            Icons.report_problem_rounded,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
            // Contenedor con los íconos, textos y botones
            Container(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  buildTurnOnBluetooth(context),
                  SizedBox(
                    height: 50,
                  ),
                  buildTurnOnLoction(context),
                  /*ListTile(
                  leading: _bluetoothAdapterState == BluetoothAdapterState.off
                      ? Icon(Icons.bluetooth_disabled, size: 50.0, color: Colors.blue.shade200)
                      : Icon(Icons.bluetooth_connected_outlined, size: 50.0, color: Colors.blue.shade200),
                  title: buildTitle('Bluetooth'),
                  subtitle: buildSubtitle(context),
                  trailing: (Platform.isAndroid ? buildTurnOnButton(context) : SizedBox.shrink()),
                ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
