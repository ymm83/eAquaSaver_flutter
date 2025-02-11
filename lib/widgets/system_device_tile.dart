import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SystemDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onOpen;
  final VoidCallback onConnect;

  const SystemDeviceTile({
    required this.device,
    required this.onOpen,
    required this.onConnect,
    super.key,
  });

  @override
  State<SystemDeviceTile> createState() => _SystemDeviceTileState();
}

class _SystemDeviceTileState extends State<SystemDeviceTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<BluetoothBondState> _bsSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });

    _bsSubscription = widget.device.bondState.listen((value) {
      setState(() {});
      if (value == BluetoothBondState.none && widget.device.prevBondState == BluetoothBondState.bonding) {}
      //debugPrint("--------$value prev:${widget.device.prevBondState}");
      //debugPrint("--------disconnectReason: ${widget.device.disconnectReason}");
    });
    widget.device.cancelWhenDisconnected(_bsSubscription);
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _bsSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.device.prevBondState == BluetoothBondState.bonding) {
      return Container(
          // Agregado para definir el tamaño
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.red.shade100,
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.bluetooth_disabled), backgroundColor: Colors.red.shade100,),
              title: Text(widget.device.platformName),
              subtitle: Text('Pairing failed!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, letterSpacing: 1.5),),
              trailing: const IconButton(
                onPressed: null,
                icon: Icon(Icons.lock_rounded),
              ),
            ),
          ));
    } else {
      return Container(
          // Agregado para definir el tamaño
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: (widget.device.prevBondState == BluetoothBondState.bonding) ? Colors.red : Colors.blue,
                  width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.blue.shade100,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.bluetooth_connected)),
              title: Text(widget.device.platformName),
              subtitle: Text(widget.device.remoteId.str),
              trailing: IconButton(
                onPressed: isConnected ? widget.onOpen : widget.onConnect,
                icon: (isConnected ? const Icon(Icons.link) : Icon(Icons.link_off)),
              ),
            ),
          ));
    }
  }
}
