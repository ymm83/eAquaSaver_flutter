import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_device_tile.dart';
import '../utils/snackbar_helper.dart';

class ScanScreen extends StatefulWidget {
  final PageController pageController;

  const ScanScreen({super.key, required this.pageController});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BleBloc, BleState>(
      listener: (context, state) {
        if (state is BleConnected) {
          widget.pageController.jumpToPage(1);
        }
      },
      builder: (context, state) {
        final bloc = context.read<BleBloc>();

        // Controlar animación basada en el estado
        if (state is BleScanning) {
          _controller.repeat();
        } else {
          _controller.stop();
          _controller.reset();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('scan.title'.tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => bloc.add(StartScan()),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              bloc.add(StartScan());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                // Dispositivos emparejados
                if (bloc.systemDevices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('scan.my_devices'.tr()),
                    ),
                  ),
                if (bloc.systemDevices.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SystemDeviceTile(
                        device: bloc.systemDevices[index],
                        onTap: () => bloc.add(ConnectToDevice(bloc.systemDevices[index])),
                      ),
                      childCount: bloc.systemDevices.length,
                    ),
                  ),
                
                // Resultados de escaneo
                if (state is BleScanning)
                  const SliverToBoxAdapter(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('scan.searching_devices'),
                    ),
                  ),
                if (state is BleScanResults && state.results.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('scan.devices_found'.tr()),
                    ),
                  ),
                if (state is BleScanResults)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ScanDeviceTile(
                        result: state.results[index],
                        onTap: () => bloc.add(ConnectToDevice(state.results[index].device)),
                      ),
                      childCount: state.results.length,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => bloc.add(state is BleScanning ? StopScan() : StartScan()),
            backgroundColor: Colors.blue.shade300,
            shape: const CircleBorder(),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
              child: Icon(
                state is BleScanning ? Icons.sync : Icons.sync,
                size: 40,
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/*import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/extra.dart';
import '../bloc/ble/ble_bloc.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_bar_loading_indicator.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_device_tile.dart';
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
      showSnackBar("${'errors.ble.scan_error'}: $e", theme: 'error');
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
      showSnackBar("${'errors.ble.system_devices'}: $e", theme: 'error');
    }
    try {
      _scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5), androidUsesFineLocation: true);
    } catch (e) {
      showSnackBar("${'errors.ble.on_scan'.tr()}: $e", theme: 'error');
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
      showSnackBar("${'errors.ble.on_stop'.tr()}: $e", theme: 'error');
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      showSnackBar("${'errors.ble.on_connect'.tr()}: $e", theme: 'error');
    });
    context.read<BleBloc>().add(ConnectToDevice(device));
    context.read<BleBloc>().add(DetailsOpen());
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
          debugPrint('------------Device: ${d.advName}, Bond State: $bondState');

          return SystemDeviceTile(
            device: d,
            onTap:() {
                onConnectPressed(d);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildScanDeviceTiles(BuildContext context) {
    return _scanResults
        .where((r) => (/*r.device.advName.toString().startsWith('eASb', 0) ||*/
            r.device.platformName.toString().startsWith('eASs', 0)))
        .map((r) => ScanDeviceTile(
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
    return BlocConsumer<BleBloc, BleState>(
      listener: (context, state) {
        if (state is BleConnected) {
          widget.pageController.jumpToPage(1);
        }
      },
      builder: (context, state) {
        final bloc = context.read<BleBloc>();

        return Scaffold(
          appBar: AppBar(
            title: Text('scan.title'.tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => bloc.add(StartScan()),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              bloc.add(StartScan());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                // Dispositivos emparejados
                if (bloc.systemDevices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('scan.my_devices'.tr()),
                    ),
                  ),
                if (bloc.systemDevices.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SystemDeviceTile(
                        device: bloc.systemDevices[index],
                        onTap: () => bloc.add(ConnectToDevice(bloc.systemDevices[index])),
                      ),
                      childCount: bloc.systemDevices.length,
                    ),
                  ),
                
                // Resultados de escaneo
                if (state is BleScanning)
                  const SliverToBoxAdapter(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('scan.searching_devices'),
                    ),
                  ),
                if (state is BleScanResults && state.results.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('scan.devices_found'.tr()),
                    ),
                  ),
                if (state is BleScanResults)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ScanDeviceTile(
                        result: state.results[index],
                        onTap: () => bloc.add(ConnectToDevice(state.results[index].device)),
                      ),
                      childCount: state.results.length,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => bloc.add(state is BleScanning ? StopScan() : StartScan()),
            backgroundColor: Colors.blue.shade300,
            shape: const CircleBorder(),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
              child: Icon(
                state is BleScanning ? Icons.sync : Icons.search,
                size: 40,
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
            ),
          ),
          /*floatingActionButton: FloatingActionButton(
            onPressed: () => bloc.add(
              state is BleScanning ? StopScan() : StartScan()
            ),
            child: Icon(
              state is BleScanning ? Icons.stop : Icons.search,
              color: Colors.white,
            ),
          ),*/
        );
      },
    );
  }
}*/

 /* @override
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
              const SizedBox(
                height: 5,
              ),
              //TopLoadingIndicator(isLoading: _isScanning),
              if (_systemDevices.isNotEmpty) ...[
                _buildTitle('scan.my_devices'.tr()),
                ..._buildSystemDeviceTiles(context),
              ],

              if (_isScanning) _buildTitle('scan.searching_devices'.tr(), size: 14.5),
              if (!_isScanning && _buildScanDeviceTiles(context).isEmpty) _buildTitle('scan.no_devices'.tr()),
              /*if (!_isScanning && _scanResults.isNotEmpty)
                Center(
                    child: Text('${_buildScanDeviceTiles(context).length} dispositivos encontrados:',
                        style: const TextStyle())),*/
              const SizedBox(
                height: 5,
              ),
              if (!_isScanning && _buildScanDeviceTiles(context).isNotEmpty) _buildTitle('scan.devices_found'.tr()),
              if (!_isScanning) ..._buildScanDeviceTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }*/
