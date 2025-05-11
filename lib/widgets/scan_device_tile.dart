import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import '../protoc/eaquasaver_msg.pbserver.dart';

class ScanDeviceTile extends StatefulWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanDeviceTile({
    Key? key,
    required this.result,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ScanDeviceTile> createState() => _ScanDeviceTileState();
}

class _ScanDeviceTileState extends State<ScanDeviceTile> {
  bool _isLedOn = false;
  late Timer _timer;
  Map<String, dynamic>? _decodedData;
  AdvertisementData? _advertisementData;
  int _rssi = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
    _startBlinking();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceData() async {
    try {
      _advertisementData = widget.result.advertisementData;
      _rssi = widget.result.rssi;

      // Decodificar datos del fabricante si existen
      if (_advertisementData?.manufacturerData.isNotEmpty ?? false) {
        final data = List<int>.from(_advertisementData!.manufacturerData.values.first);
        _decodedData = _decodeManufacturerData(data);
      }
    } catch (e) {
      debugPrint('Error loading device data: $e');
    }

    if (mounted) setState(() {});
  }

  void _startBlinking() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if ((_advertisementData?.connectable ?? true) && mounted) {
        if (mounted) {
          setState(() => _isLedOn = !_isLedOn);
        }
      }
    });
  }

  Map<String, dynamic> _decodeManufacturerData(List<int> manufacturerData) {
    final adv = widget.result.advertisementData;
    if (adv.manufacturerData.isNotEmpty) {
      try {
        final data = adv.manufacturerData.values.first;
        final message = eAquaSaverMessage.fromBuffer(data.sublist(1, data[0] + 1));

        return {
          'temperature': message.temperature.toInt() / 10,
          'hotTemp': message.hotTemperature.toInt() / 10,
          'coldTemp': message.coldTemperature.toInt() / 10,
          'targetTemp': message.targetTemperature.toInt() / 10,
          'minTemp': message.minimalTemperature.toInt() / 10,
          'ambientTemp': message.ambientTemperature.toInt() / 10,
          'currentHotUsed': message.currentHotUsed.toInt() / 100,
          'currentRecovered': message.currentRecovered.toInt() / 100,
          'currentColdUsed': message.currentColdUsed.toInt() / 100,
          'totalColdUsed': message.totalColdUsed.toInt() / 100,
          'totalRecovered': message.totalRecovered.toInt() / 100,
          'totalHotUsed': message.totalHotUsed.toInt() / 100,
          'state': message.state.toInt()
        };
      } catch (e) {
        debugPrint('Decoding error: $e');
        return {}; // Devuelve un mapa vacío en caso de error
      }
    }
    return {}; // Si no hay manufacturerData, devuelve un mapa vacío
  }

  Widget _buildTitle(BuildContext context) {
    final device = widget.result.device;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('eAquaSaver', overflow: TextOverflow.ellipsis),
        if (device.platformName.isNotEmpty) Text(device.platformName, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildConnectionButton(BuildContext context, bool isConnected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? Colors.green.shade400 : Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      onPressed: widget.result.advertisementData.connectable ? widget.onTap : null,
      child: Icon(isConnected ? Icons.link : Icons.link_off),
    );
  }

  Widget _buildDataRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIndicator(int rssi) {
    final int bars;
    if (rssi >= -50)
      bars = 4;
    else if (rssi >= -60)
      bars = 3;
    else if (rssi >= -70)
      bars = 2;
    else if (rssi >= -80)
      bars = 1;
    else
      bars = 0;

    return Row(
      children: List.generate(
          4,
          (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: (index + 1) * 3,
                color: index < bars ? _getSignalColor(rssi) : Colors.grey[300],
              )),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.blue;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(List<List<int>> data) {
    return data.map((val) => getNiceHexArray(val)).join(', ').toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries.map((v) => '${v.key}: ${getNiceHexArray(v.value)}').join(', ').toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  /*Map<String, dynamic> decodedMessage(List<int> manufacturerData) {
    //Map<String, dynamic> results = {};
    /*if (adv.manufacturerData.isNotEmpty) {
      adv.manufacturerData.forEach((key, value) {*/
    var decodedData = _decodeManufacturerData(manufacturerData);
    //debugPrint("\nMensaje ***********: --- START ---\n ${decodedData.toString()} --- END ---");
    return decodedData;
  }*/

  Map<String, dynamic> decodedMessage(List<int> manufacturerData) {
    //Map<String, dynamic> results = {};
    /*if (adv.manufacturerData.isNotEmpty) {
      adv.manufacturerData.forEach((key, value) {*/
    var decodedData = _decodeManufacturerData(manufacturerData);
    //debugPrint("\nMensaje ***********: --- START ---\n ${decodedData.toString()} --- END ---");
    return decodedData;
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.result.advertisementData;
    final isConnectable = adv.connectable;
    final manufacturerData =
        adv.manufacturerData.isNotEmpty ? List<int>.from(adv.manufacturerData.values.first) : <int>[];

    return BlocBuilder<BleBloc, BleState>(
      builder: (context, state) {
        final isConnected = state is BleConnected && state.device.remoteId == widget.result.device.remoteId;
        final isConnecting = state is BleConnecting && state.device.remoteId == widget.result.device.remoteId;

        // Decodificamos los datos solo cuando sea necesario
        final decodedData = !isConnectable && manufacturerData.isNotEmpty ? decodedMessage(manufacturerData) : null;

        return ExpansionTile(
          title: Row(
            children: [
              if (!isConnectable)
                AnimatedContainer(
                  margin: const EdgeInsets.only(top: 0),
                  duration: const Duration(milliseconds: 500),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLedOn ? Colors.red.shade500 : Colors.blue.shade700,
                  ),
                )
              else
                _buildSignalIndicator(widget.result.rssi),
              const SizedBox(width: 8),
              Expanded(child: _buildTitle(context)),
            ],
          ),
          trailing: _buildConnectionButton(context, isConnected),
          children: [
            if (!isConnectable) Icon(Icons.link_off_rounded, color: Colors.red.shade700),
            if (isConnectable) Icon(Icons.link_off_rounded, color: Colors.green.shade700),
            if (adv.advName.isNotEmpty) _buildDataRow(context, 'Name', adv.advName),
            if (!isConnectable && _decodedData != null) ...[
              _buildDataRow(context, 'Temperature', '${_decodedData!['temperature']}°C'),
              _buildDataRow(context, 'State', '${_decodedData!['state']}'),
              // Agrega más campos según sea necesario
            ],
            if (adv.txPowerLevel != null) _buildDataRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
            if (adv.serviceUuids.isNotEmpty) _buildDataRow(context, 'Service UUIDs', adv.serviceUuids.join(', ')),
            _buildDataRow(context, 'MAC', widget.result.device.remoteId.str),
            _buildDataRow(context, 'RSSI', '${widget.result.rssi} dBm'),
            if (!adv.connectable) Icon(Icons.link_off_rounded, color: Colors.red.shade700),
            if (isConnectable) Icon(Icons.link_off_rounded, color: Colors.green.shade700),
            if (adv.advName.isNotEmpty) _buildDataRow(context, 'Name', adv.advName),
            if (!isConnectable && adv.manufacturerData.isNotEmpty)
              Text('adv.manufacturerData.values: \n ${adv.manufacturerData.values}'),
            if (!isConnectable && adv.manufacturerData.isNotEmpty)
              Text(
                  'adv.manufacturerData.values.first: \n${decodedMessage(adv.manufacturerData.values.first).toString()}'),
            if (adv.txPowerLevel != null) _buildDataRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
            if ((adv.appearance ?? 0) > 0)
              _buildDataRow(context, 'Appearance', '0x${adv.appearance!.toRadixString(16)}'),
            if (!isConnectable && adv.msd.isNotEmpty)
              _buildDataRow(context, 'Manufacturer Data', getNiceManufacturerData(adv.msd)),
            if (isConnectable) _buildDataRow(context, 'RemoteId', widget.result.device.remoteId.str),
            if (adv.serviceUuids.isNotEmpty)
              _buildDataRow(context, 'Service UUIDs', getNiceServiceUuids(adv.serviceUuids)),
            if (adv.serviceData.isNotEmpty) _buildDataRow(context, 'Service Data', getNiceServiceData(adv.serviceData)),
          ],
        );
      },
    );
  }
}

/**
 * 
 * 
part of 'ble_bloc.dart';

sealed class BleState extends Equatable {
  const BleState();
  
  @override
  List<Object> get props => [];
}

class BleInitial extends BleState {}

class BleScanning extends BleState {}

class BleScanResults extends BleState {
  final List<ScanResult> results;
  
  const BleScanResults(this.results);
  
  @override
  List<Object> get props => [results];
}

class BleConnecting extends BleState {
  final BluetoothDevice device;
  
  const BleConnecting(this.device);
  
  @override
  List<Object> get props => [device];
}

class BleConnected extends BleState {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  
  const BleConnected({
    required this.device,
    required this.services,
  });
  
  @override
  List<Object> get props => [device, services];
}

class BleError extends BleState {
  final String message;
  
  const BleError(this.message);
  
  @override
  List<Object> get props => [message];
}
 * 
 */

/*import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../protoc/eaquasaver_msg.pbserver.dart';

class ScanDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;

  const ScanDeviceTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  State<ScanDeviceTile> createState() => _ScanDeviceTileState();
}

class _ScanDeviceTileState extends State<ScanDeviceTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  bool _isLedOn = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _connectionState = widget.device.connectionStateNow;
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() => _connectionState = state);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(List<List<int>> data) {
    return data.map((val) => getNiceHexArray(val)).join(', ').toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries.map((v) => '${v.key}: ${getNiceHexArray(v.value)}').join(', ').toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  void _startBlinking() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isLedOn = !_isLedOn; // Cambia el estado del LED
      });
    });
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.result.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'eAquaSaver',
            //widget.result.device.platformName,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.result.device.platformName,
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      );
    } else {
      return Text(widget.result.device.advName.toString());
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade400,
          foregroundColor: Colors.white,
        ),
        onPressed: (widget.result.advertisementData.connectable) ? widget.onTap : null,
        child: isConnected ? const Icon(Icons.link) : const Icon(Icons.link_off));
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _decodeManufacturerData(List<int> data) {
    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage message = eAquaSaverMessage.fromBuffer(protobufData);

      debugPrint("Tamaño del mensaje: $size");
      //debugPrint("\nMensaje decodificado: --- START ---:\n ${message.toString()} --- END ---");

      //debugPrint('Temperatura caliente: ${message.hotTemperature[0].toString()}');
      //debugPrint('\n----- message : ${message.state[0]}\n-------end message ----------\n');
      //debugPrint('\n----- message : ${message.temperature.toString()}\n-------end message ----------\n');
      Map<String, dynamic> beaconData = {
        'temperature': message.temperature.toInt() / 10,
        'hotTemperature': message.hotTemperature.toInt() / 10,
        'coldTemperature': message.coldTemperature.toInt() / 10,
        'targetTemperature': message.targetTemperature.toInt() / 10,
        'minimalTemperature': message.minimalTemperature.toInt() / 10,
        'ambientTemperature': message.ambientTemperature.toInt() / 10,
        'currentHotUsed': message.currentHotUsed.toInt() / 100,
        'currentRecovered': message.currentRecovered.toInt() / 100,
        'currentColdUsed': message.currentColdUsed.toInt() / 100,
        'totalColdUsed': message.totalColdUsed.toInt() / 100,
        'totalRecovered': message.totalRecovered.toInt() / 100,
        'totalHotUsed': message.totalHotUsed.toInt() / 100,
        'state': message.state.toInt()
      };
      //debugPrint('------ beaconData: ${beaconData['temperature']}');
      return beaconData;
    } catch (e) {
      debugPrint('Error----->: $e');
      return {};
    }
  }

  Map<String, dynamic> decodedMessage(List<int> manufacturerData) {
    //Map<String, dynamic> results = {};
    /*if (adv.manufacturerData.isNotEmpty) {
      adv.manufacturerData.forEach((key, value) {*/
    var decodedData = _decodeManufacturerData(manufacturerData);
    debugPrint("\nMensaje ***********: --- START ---\n ${decodedData.toString()} --- END ---");
    return decodedData;
  }

  Widget _buildSignalIndicator(int rssi) {
    final int bars;
    if (rssi >= -50)
      bars = 4;
    else if (rssi >= -60)
      bars = 3;
    else if (rssi >= -70)
      bars = 2;
    else if (rssi >= -80)
      bars = 1;
    else
      bars = 0;

    return Row(
      children: List.generate(
          4,
          (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: (index + 1) * 3,
                color: index < bars ? _getSignalColor(rssi) : Colors.grey[300],
              )),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.blue;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    var adv = widget.result.advertisementData;
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTitle(context),
        ],
      ),
      leading: (!adv.connectable)
          ? AnimatedContainer(
              margin: const EdgeInsets.only(top: 0),
              duration: const Duration(milliseconds: 500),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLedOn ? Colors.red.shade500 : Colors.blue.shade700, // Cambia el color según el estado
              ),
            )
          : Text(widget.result.rssi.toString()),
      trailing: _buildConnectButton(context),
      children: <Widget>[
        if (!adv.connectable) Icon(Icons.link_off_rounded, color: Colors.red.shade700),
        if (adv.connectable) Icon(Icons.link_off_rounded, color: Colors.green.shade700),
        if (adv.advName.isNotEmpty) _buildAdvRow(context, 'Name', adv.advName),
        if (!adv.connectable && adv.manufacturerData.isNotEmpty)
          Text('adv.manufacturerData.values: \n ${adv.manufacturerData.values}'),
        if (!adv.connectable && adv.manufacturerData.isNotEmpty)
          Text('adv.manufacturerData.values.first: \n${decodedMessage(adv.manufacturerData.values.first).toString()}'),
        if (adv.txPowerLevel != null) _buildAdvRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
        if ((adv.appearance ?? 0) > 0) _buildAdvRow(context, 'Appearance', '0x${adv.appearance!.toRadixString(16)}'),
        if (!adv.connectable && adv.msd.isNotEmpty)
          _buildAdvRow(context, 'Manufacturer Data', getNiceManufacturerData(adv.msd)),
        if (adv.connectable) _buildAdvRow(context, 'RemoteId', widget.result.device.remoteId.str),
        if (adv.serviceUuids.isNotEmpty) _buildAdvRow(context, 'Service UUIDs', getNiceServiceUuids(adv.serviceUuids)),
        if (adv.serviceData.isNotEmpty) _buildAdvRow(context, 'Service Data', getNiceServiceData(adv.serviceData)),
      ],
    );
  }
}*/
