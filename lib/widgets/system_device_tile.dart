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

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        // Agregado para definir el tamaño
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.blue.shade100,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.bluetooth_connected)),
            title: Text(widget.device.platformName),
            subtitle: Text(widget.device.remoteId.str),
            trailing: IconButton(
              onPressed: isConnected ? widget.onOpen : widget.onConnect,
              icon: (isConnected ? const Icon(Icons.link) : const Icon(Icons.link_off)),
            ),
          ),
        ));
  }
}
