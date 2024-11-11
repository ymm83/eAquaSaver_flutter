import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../protoc/eaquasaver_msg.pbserver.dart';

class ScanResultTile extends StatefulWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  bool _isLedOn = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startBlinking();
    _connectionStateSubscription = widget.result.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
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
            widget.result.device.remoteId.str,
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
      var protobufData = data.sublist(1, size+1);
      eAquaSaverMessage message = eAquaSaverMessage.fromBuffer(protobufData);

      debugPrint("Tamaño del mensaje: $size");
      //debugPrint("\nMensaje decodificado: --- START ---:\n ${message.toString()} --- END ---");

      //debugPrint('Temperatura caliente: ${message.hotTemperature[0].toString()}');
      //debugPrint('\n----- message : ${message.state[0]}\n-------end message ----------\n');
      //debugPrint('\n----- message : ${message.temperature.toString()}\n-------end message ----------\n');
      Map<String, dynamic> beaconData = {
        'temperature': message.temperature.toInt()/10,
        'hotTemperature': message.hotTemperature.toInt()/10,
        'coldTemperature': message.coldTemperature.toInt()/10,
        'targetTemperature': message.targetTemperature.toInt()/10,
        'minimalTemperature': message.minimalTemperature.toInt()/10,
        'ambientTemperature': message.ambientTemperature.toInt()/10,
        'currentHotUsed': message.currentHotUsed.toInt()/100,
        'currentRecovered': message.currentRecovered.toInt()/100,
        'currentColdUsed': message.currentColdUsed.toInt()/100,
        'totalColdUsed': message.totalColdUsed.toInt()/100,
        'totalRecovered': message.totalRecovered.toInt()/100,
        'totalHotUsed': message.totalHotUsed.toInt()/100,
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
        if (adv.serviceUuids.isNotEmpty) _buildAdvRow(context, 'Service UUIDs', getNiceServiceUuids(adv.serviceUuids)),
        if (adv.serviceData.isNotEmpty) _buildAdvRow(context, 'Service Data', getNiceServiceData(adv.serviceData)),
      ],
    );
  }
}
