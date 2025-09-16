import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MultiDeviceBLEScreen extends StatefulWidget {
  final List<BluetoothDevice> devices;
  final PageController pageController;

  const MultiDeviceBLEScreen({
    super.key,
    required this.devices,
    required this.pageController,
  });

  @override
  State<MultiDeviceBLEScreen> createState() => _MultiDeviceBLEScreenState();
}

class _MultiDeviceBLEScreenState extends State<MultiDeviceBLEScreen> {
  int _currentDeviceIndex = 0;
  Map<String, BluetoothConnectionState> _connectionStates = {};
  Map<String, int?> _rssiValues = {};
  Map<String, List<BluetoothService>> _services = {};
  Map<String, bool> _isDiscoveringServices = {};
  Map<String, Map<String, dynamic>> _beaconData = {};

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late Timer _beaconTimer;

  @override
  void initState() {
    super.initState();
    _initializeDeviceStates();
    _startBeaconScanning();
  }


  void _initializeDeviceStates() {
    for (var device in widget.devices) {
      _connectionStates[device.remoteId.str] = BluetoothConnectionState.disconnected;
      _rssiValues[device.remoteId.str] = null;
      _services[device.remoteId.str] = [];
      _isDiscoveringServices[device.remoteId.str] = false;
      _beaconData[device.remoteId.str] = {};
    }

    // Listen for connection state changes
    _connectionStateSubscription = FlutterBluePlus.onConnectionStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          _connectionStates[event.device.remoteId.str] = event.connectionState;
        });
      }
    });
  }

  void _startBeaconScanning() {
    _beaconTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _scanForBeacons();
    });
  }

  Future<void> _scanForBeacons() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    
    FlutterBluePlus.onScanResults.listen((results) {
      if (mounted) {
        setState(() {
          for (var result in results) {
            if (widget.devices.any((device) => device.remoteId == result.device.remoteId)) {
              // Process manufacturer data if available
              if (result.advertisementData.manufacturerData.isNotEmpty) {
                _beaconData[result.device.remoteId.str] = 
                  _decodeManufacturerData(result.advertisementData.manufacturerData.values.first);
              }
            }
          }
        });
      }
    });
  }

  Map<String, dynamic> _decodeManufacturerData(List<int> data) {
    // Your decoding logic here
    return {
      'temperature': 25.0,
      'state': 1,
      // Add other fields as needed
    };
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _rssiValues[device.remoteId.str] = await device.readRssi();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting: $e')),
      );
    }
  }

  Future<void> _disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error disconnecting: $e')),
      );
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    setState(() {
      _isDiscoveringServices[device.remoteId.str] = true;
    });

    try {
      final services = await device.discoverServices();
      setState(() {
        _services[device.remoteId.str] = services;
        _isDiscoveringServices[device.remoteId.str] = false;
      });
    } catch (e) {
      setState(() {
        _isDiscoveringServices[device.remoteId.str] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error discovering services: $e')),
      );
    }
  }

  Widget _buildDeviceSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButton<int>(
        value: _currentDeviceIndex,
        items: List.generate(widget.devices.length, (index) {
          final device = widget.devices[index];
          return DropdownMenuItem<int>(
            value: index,
            child: Text(
              device.platformName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _currentDeviceIndex = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    final isConnected = _connectionStates[device.remoteId.str] == BluetoothConnectionState.connected;
    final rssi = _rssiValues[device.remoteId.str];
    final beaconData = _beaconData[device.remoteId.str] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.platformName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(isConnected ? Icons.link_off : Icons.link),
                  onPressed: () {
                    if (isConnected) {
                      _disconnectFromDevice(device);
                    } else {
                      _connectToDevice(device);
                    }
                  },
                ),
              ],
            ),
            if (rssi != null) Text('RSSI: $rssi dBm'),
            if (beaconData.isNotEmpty) ..._buildBeaconData(beaconData),
            const SizedBox(height: 16),
            _buildServiceDiscoveryButton(device),
            if (_services[device.remoteId.str]!.isNotEmpty) 
              ..._buildServiceTiles(_services[device.remoteId.str]!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBeaconData(Map<String, dynamic> beaconData) {
    return [
      const SizedBox(height: 8),
      Text('Temperature: ${beaconData['temperature']?.toStringAsFixed(1) ?? 'N/A'}°C'),
      Text('State: ${_getDeviceStateString(beaconData['state'] ?? 0)}'),
    ];
  }

  String _getDeviceStateString(int state) {
    switch (state) {
      case 1: return 'Sleep';
      case 2: return 'Idle';
      case 3: return 'Temp Adjust';
      case 4: return 'Recovering';
      default: return 'Unknown';
    }
  }

  Widget _buildServiceDiscoveryButton(BluetoothDevice device) {
    final isDiscovering = _isDiscoveringServices[device.remoteId.str] ?? false;
    final isConnected = _connectionStates[device.remoteId.str] == BluetoothConnectionState.connected;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isConnected && !isDiscovering
                ? () => _discoverServices(device)
                : null,
            child: const Text('Discover Services'),
          ),
        ),
        if (isDiscovering)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services.map((service) {
      return ExpansionTile(
        title: Text('Service: ${service.uuid}'),
        children: service.characteristics.map((characteristic) {
          return ListTile(
            title: Text('Characteristic: ${characteristic.uuid}'),
            subtitle: Text('Properties: ${characteristic.properties}'),
          );
        }).toList(),
      );
    }).toList();
  }

  Widget _buildTemperatureGauge(double temperature) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 50,
          ranges: <GaugeRange>[
            GaugeRange(startValue: 0, endValue: 20, color: Colors.blue),
            GaugeRange(startValue: 20, endValue: 30, color: Colors.yellow),
            GaugeRange(startValue: 30, endValue: 50, color: Colors.red),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: temperature,
              enableAnimation: true,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              positionFactor: 0.5,
              angle: 90,
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _beaconTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = widget.devices[_currentDeviceIndex];
    final beaconData = _beaconData[currentDevice.remoteId.str] ?? {};
    final temperature = beaconData['temperature'] ?? 25.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Device BLE Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh device list or data
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDeviceSelector(),
            _buildDeviceCard(currentDevice),
            const SizedBox(height: 24),
            Text(
              'Current Temperature',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildTemperatureGauge(temperature.toDouble()),
            ),
          ],
        ),
      ),
    );
  }
}