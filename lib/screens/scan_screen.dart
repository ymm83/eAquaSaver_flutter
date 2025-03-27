import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/extra.dart';
import '../bloc/ble/ble_bloc.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_bar_loading_indicator.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../api/ble_characteristics_uuids.dart';

class ScanScreen extends StatefulWidget {
  final PageController pageController;

  const ScanScreen({super.key, required this.pageController});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<BluetoothDevice> _systemDevices = [];
  late final List<ScanResult> _scanResults = [];
  final Set<String> _uniqueRemoteIds = {}; // Conjunto para almacenar remoteId únicos
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _initialScanCompleted = false;

  /*void _processManufacturerData(AdvertisementData advertisementData) {
    if (advertisementData.manufacturerData.isNotEmpty) {
      advertisementData.manufacturerData.forEach((key, value) {
        _decodeManufacturerData(value);
      });
    } else {
      debugPrint('No hay datos de fabricante disponibles.');
    }
  }*/

  /*void _decodeManufacturerData(List<int> data) {
    if (data.isEmpty) {
      debugPrint('Error: Los datos están vacíos.');
      return;
    }

    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage decodedMessage = eAquaSaverMessage.fromBuffer(protobufData);

      double hotTemperature = decodedMessage.hotTemperature / 10.0;
      double coldTemperature = decodedMessage.coldTemperature / 10.0;

      debugPrint("\nMensaje decodificado: --- START ---\n $decodedMessage--- END ---");
      debugPrint('Temperatura caliente: $hotTemperature');
      debugPrint('Temperatura fría: $coldTemperature');
    } catch (e) {
      debugPrint('Error al decodificar los datos: $e');
    }
  }*/

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _performInitialScan();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        // Limpiar la lista de resultados de escaneo antes de agregar nuevos resultados
        _scanResults.clear();
        _uniqueRemoteIds.clear(); // Limpiar también los IDs únicos

        for (ScanResult r in results) {
          /*debugPrint('----------------START---------------');
          debugPrint('--------------------r.device.advName:${r.device.advName}');
          debugPrint('--------------------r.device.platformName:${r.device.platformName}');
          debugPrint('--------------------r.device.remoteId:${r.device.remoteId}');
          debugPrint('----------------END---------------\n');*/

          // if (r.device.platformName.toString().startsWith('eASs', 0)) {
          //   debugPrint('---- eAquaSaver Device encontrado: ${r.device.advName} ------');
          // }
          // if (r.device.advName.startsWith('eASb', 0)) {
          //   debugPrint('---- eAquaS Beacon encontrado: ${r.advertisementData.advName}  ------');
          //   //_processManufacturerData(r.advertisementData);
          // }

          // Filtrar por remoteId único
          // if (!_uniqueRemoteIds.contains(r.device.remoteId.toString())) {
          if (!_isDeviceInSystem(r.device)) _scanResults.add(r); // Solo agregar dispositivos connectable
          //_uniqueRemoteIds.add(r.device.remoteId.toString());
          // if (r.advertisementData.connectable) {
          // } else {
          //debugPrint('Dispositivo no connectable ignorado: ${r.device.remoteId}');
          // }
          //}
        }

        // Actualizar la UI
        setState(() {});
      }
    }, onError: (e) {
      showSnackBar("Scan Error: $e", theme: 'error');
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
          if (_isScanning) {
            _controller.repeat();
          } else {
            _controller.stop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _controller.dispose();

    super.dispose();
  }

  bool _isDeviceInSystem(BluetoothDevice device) {
    // Verifica si el dispositivo está en systemDevices
    return _systemDevices.any((sysDevice) => sysDevice.remoteId == device.remoteId);
  }

  Future<void> _performInitialScan() async {
    if (!_initialScanCompleted) {
      await onScanPressed();
      setState(() {
        _initialScanCompleted = true;
      });
    }
  }

  Future<List<BluetoothDevice>> getSystemDevices() async {
    // Esperar el Future que retorna FlutterBluePlus.systemDevices
    List<Guid> withServices = [charEnabledUuid];
    List<BluetoothDevice> _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    //List<BluetoothDevice> _systemDevices = [];
    //_systemDevices = await FlutterBluePlus.systemDevices([charEnabledUuid]);
    return _systemDevices;
  }

  Future onScanPressed() async {
    //debugPrint('_uniqueRemoteIds: ${_uniqueRemoteIds.length}');

    try {
      _systemDevices = await getSystemDevices();
    } catch (e) {
      showSnackBar("System Devices Error: $e", theme: 'error');
    }
    try {
      _scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5), androidUsesFineLocation: true);
    } catch (e) {
      showSnackBar("Start Scan Error: $e", theme: 'error');
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      await FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
      _controller.stop();
    } catch (e) {
      showSnackBar("Stop Scan Error: $e", theme: 'error');
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      showSnackBar("Connect Error: $e", theme: 'error');
    });
    context.read<BleBloc>().add(ConnectToDevice(device));
    context.read<BleBloc>().add(const DetailsOpen());
    widget.pageController.jumpToPage(1);
  }

  Future onRefresh() {
    if (!_isScanning) {
      // FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: !_isScanning ? onScanPressed : onStopPressed,
      backgroundColor: Colors.blue.shade300,
      shape: const CircleBorder(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.141592653589793,
            child: Icon(
              Icons.sync,
              size: 40,
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
          );
        },
      ),
    );
  }

  /*List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) {
      debugPrint('-------- _systemDevices: ${d.prevBondState} - ${d.advName} - ');
      return SystemDeviceTile(
        device: d,
        onOpen: () {
          onConnectPressed(d);
          // context.read<BleBloc>().add(const DetailsOpen());
          // widget.pageController.jumpToPage(1);
        },
        onConnect: () {
          onConnectPressed(d);
          // context.read<BleBloc>().add(const DetailsOpen());
          // widget.pageController.jumpToPage(1);
        },
      );
    }).toList();
  }*/

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) {
      return StreamBuilder<BluetoothBondState>(
        stream: d.bondState,
        initialData: BluetoothBondState.none, // Default initial state
        builder: (context, snapshot) {
          final bondState = snapshot.data ?? BluetoothBondState.none;
          debugPrint('Device: ${d.advName}, Bond State: $bondState');

          return SystemDeviceTile(
            device: d,
            bondState: bondState, // Pass the bond state to the tile
            onOpen: () {
              onConnectPressed(d);
            },
            onConnect: () {
              onConnectPressed(d);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .where((r) => (/*r.device.advName.toString().startsWith('eASb', 0) ||*/
            r.device.platformName.toString().startsWith('eASs', 0)))
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => onConnectPressed(r.device),
            ))
        .toList();
  }

  Widget _buildTitle(String title, {double? size = 16}) {
    return Center(child: Text(title, style: TextStyle(fontSize: size)));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        appBar: AppBarLoadingIndicator(
          isLoading: _isScanning,
          backgroundColor: Colors.blue.shade200,
          progressColor: Colors.red.shade300,
          boxColor: Theme.of(context).appBarTheme.backgroundColor,
          height: 1.5,
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              SizedBox(
                height: 5,
              ),
              //TopLoadingIndicator(isLoading: _isScanning),
              if (_systemDevices.isNotEmpty) ...[
                _buildTitle('My devices:'),
                ..._buildSystemDeviceTiles(context),
              ],

              if (_isScanning) _buildTitle('Searching eAquaSaver devices...', size: 14.5),
              if (!_isScanning && _buildScanResultTiles(context).isEmpty) _buildTitle('No divices found. Try again!'),
              /*if (!_isScanning && _scanResults.isNotEmpty)
                Center(
                    child: Text('${_buildScanResultTiles(context).length} dispositivos encontrados:',
                        style: const TextStyle())),*/
              SizedBox(
                height: 5,
              ),
              if (!_isScanning && _buildScanResultTiles(context).isNotEmpty) _buildTitle('Devices found:'),
              if (!_isScanning) ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
