import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/extra.dart';
import '../utils/snackbar.dart';
import '../bloc/ble_bloc.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';

class ScanScreen extends StatefulWidget {
  final PageController pageController;

  const ScanScreen({super.key, required this.pageController});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this, // Usa 'this' porque _ScanScreenState ahora implementa TickerProviderStateMixin
    );
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(withNames: ['eAquaSaver'], timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
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
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
          onPressed: onScanPressed,
          backgroundColor: Colors.blue.shade300,
          shape: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: _controller.value * 2.0 * 3.141592653589793,
                child: const Icon(
                  Icons.sync,
                  size: 40,
                  color: Colors.purple,
                ),
              );
            },
          ));
    } else {
      return FloatingActionButton(
        onPressed: onScanPressed,
        backgroundColor: Colors.blue.shade300,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.sync,
          size: 40,
          color: Colors.purple,
        ),
      );
    }
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
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Find Devices')),
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}