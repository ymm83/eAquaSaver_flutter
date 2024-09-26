import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/extra.dart';
import '../protoc/eaquasaver_msg.pb.dart';
import '../utils/snackbar.dart';
import '../bloc/ble/ble_bloc.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
//import '../protoc/eaquasaver_msg.pb.dart';

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
          debugPrint('----------------START---------------');
          debugPrint('--------------------r.device.advName:${r.device.advName}');
          debugPrint('--------------------r.device.platformName:${r.device.platformName}');
          debugPrint('--------------------r.device.remoteId:${r.device.remoteId}');
          debugPrint('----------------END---------------\n');

          String name = r.device.platformName;

          if (name.startsWith('eASs-')) {
            debugPrint('eAquaSaver Device encontrado: ${r.device.advName}');
          }
          if (name.startsWith('eASb-')) {
            debugPrint('eAquaS Beacon encontrado: ${r.advertisementData.advName} remoteId: ${r.device.remoteId}');
            //_processManufacturerData(r.advertisementData);
          }

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
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
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

  Future onScanPressed() async {
    //debugPrint('_uniqueRemoteIds: ${_uniqueRemoteIds.length}');

    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
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
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
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
            child: const Icon(
              Icons.sync,
              size: 40,
              color: Colors.purple,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) {
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
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    debugPrint('-----------------------_scanResults.length: ${_scanResults.length}');
    debugPrint('---------------------_systemDevices.length: ${_systemDevices.length}');
    return _scanResults
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => onConnectPressed(r.device),
            ))
        .toList();
  }


  

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              if (_systemDevices.isNotEmpty) const Center(child: Text('My devices', style: TextStyle())),
              if (_systemDevices.isNotEmpty) ..._buildSystemDeviceTiles(context),
              if (_isScanning) const Center(child: Text('Searching eAquaSaver devices...', style: TextStyle())),
              if (_isScanning)
                const Padding(
                  padding: EdgeInsets.only(left: 50, right: 50, top: 5),
                  child: LinearProgressIndicator(
                    color: Colors.blue,
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              if (!_isScanning && _scanResults.isNotEmpty)
                Center(child: Text('${_scanResults.length} dispositivos encontrados:', style: const TextStyle())),
              if (!_isScanning) ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}





/*import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/extra.dart';
import '../utils/snackbar.dart';
import '../bloc/ble/ble_bloc.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../protoc/eaquasaver_msg.pb.dart';

class ScanScreen extends StatefulWidget {
  final PageController pageController;

  const ScanScreen({super.key, required this.pageController});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<BluetoothDevice> _systemDevices = [];
  late List<ScanResult> _scanResults = FlutterBluePlus.lastScanResults;
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _initialScanCompleted = false;

  void _processManufacturerData(AdvertisementData advertisementData) {
    if (advertisementData.manufacturerData.isNotEmpty) {
      advertisementData.manufacturerData.forEach((key, value) {
        _decodeManufacturerData(value);
      });
    } else {
      debugPrint('No hay datos de fabricante disponibles.');
    }
  }

  void _decodeManufacturerData(List<int> data) {
    if (data.isEmpty) {
      debugPrint('Error: Los datos están vacíos.');
      return;
    }

    try {
      int size = data[0];
      var protobufData = data.sublist(1, size+1);
      //debugPrint("protobufData: $protobufData");
      eAquaSaverMessage decodedMessage = eAquaSaverMessage.fromBuffer(protobufData);

      double hotTemperature = decodedMessage.hotTemperature / 10.0;
      double coldTemperature = decodedMessage.coldTemperature / 10.0;

      //debugPrint("Tamaño del dato: $size");
      debugPrint("\nMensaje decodificado: --- START ---\n $decodedMessage--- END ---");

      //final decodedData = eAquaSaverMessage.fromBuffer(Uint8List.fromList(data));
      //debugPrint('Decoded Manufacturer Data: ${decodedData}');

      debugPrint('Temperatura caliente: $hotTemperature');
      debugPrint('Temperatura fría: $coldTemperature');
      //debugPrint('Current hot used: ${decodedMessage.currentHotUsed}');
    } catch (e) {
      debugPrint('Error al decodificar los datos: $e');
    }
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  List<String> getHexArray(List<int> bytes) {
    //debugPrint('////////// ${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).toList()}');
    return bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).toList();
  }

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
        for (ScanResult r in results) {
          String name = r.device.advName;
          if (name.startsWith('eAquaS')) {
            if (name == 'eAquaSaver') {
              debugPrint('eAquaSaver Device encontrado: ${r.device.advName}');
            }
            if (name == 'eAquaS Beacon') {
              debugPrint('eAquaS Beacon encontrado: ${r.advertisementData.advName} remoteId: ${r.device.remoteId}');
              _processManufacturerData(r.advertisementData);
            }
          }
        }

        setState(() {
          _scanResults = results.where((r) => r.device.advName.startsWith('eAquaS')).toList();
          //_isScanning = false;
        });
        //FlutterBluePlus.stopScan();
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
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

  Future<void> _performInitialScan() async {
    if (!_initialScanCompleted) {
      await onScanPressed();
      setState(() {
        _initialScanCompleted = true;
      });
    }
  }

  Future onScanPressed() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(
          //withServices: [Guid('0x40cddba8-0x0e58-0x47b1-0xb2fa-0xa93c4993d81d')],
          //withNames: ['eAquaSaver'],
          timeout: const Duration(seconds: 3));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
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
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
    });
    context.read<BleBloc>().add(ConnectToDevice(device));
    context.read<BleBloc>().add(const DetailsOpen());
    widget.pageController.jumpToPage(1);
  }

  Future onRefresh() {
    if (!_isScanning) {
      //FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
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
              child: const Icon(
                Icons.sync,
                size: 40,
                color: Colors.purple,
              ),
            );
          },
        ));
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) {
      return SystemDeviceTile(
        device: d,
        onOpen: () {
          onConnectPressed(d);
          context.read<BleBloc>().add(const DetailsOpen());
          widget.pageController.jumpToPage(1);
        },
        onConnect: () {
          onConnectPressed(d);
          context.read<BleBloc>().add(const DetailsOpen());
          widget.pageController.jumpToPage(1);
        },
      );
    }).toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .where((r) => r.device.advName == 'eAquaSaver')
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => onConnectPressed(r.device),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        /* appBar: AppBar(
          title: const Center(child: Text('Find Devices')),
        ),*/
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              if (_systemDevices.isNotEmpty) const Center(child: Text('My devices', style: TextStyle())),
              if (_systemDevices.isNotEmpty) ..._buildSystemDeviceTiles(context),
              // Mostrar un indicador de progreso si se está escaneando
              if (_isScanning) const Center(child: Text('Searching eAcuaSaver devices...', style: TextStyle())),
              if (_isScanning)
                const Padding(
                    padding: EdgeInsets.only(left: 50, right: 50, top: 5),
                    child: LinearProgressIndicator(
                      color: Colors.blue,
                      backgroundColor: Colors.redAccent,
                    )),
              if (_isScanning == false && _scanResults.isNotEmpty)
                Center(
                    child: Text('${_scanResults.map((r) => r.device.platformName).toList()} Founded devices:',
                        style: TextStyle())),
              if (_isScanning == false) ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
*/