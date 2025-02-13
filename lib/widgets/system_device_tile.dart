import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SystemDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onOpen;
  final VoidCallback onConnect;
  final BluetoothBondState bondState;

  const SystemDeviceTile({
    required this.device,
    required this.onOpen,
    required this.onConnect,
    required this.bondState,
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
      debugPrint("--------$value prev:${widget.device.prevBondState}");
      debugPrint("--------disconnectReason: ${widget.device.disconnectReason}");
      if (value == BluetoothBondState.none && widget.device.prevBondState == BluetoothBondState.bonding) {}
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

  Widget _buildDeviceCard({
    required Color borderColor,
    required Color cardColor,
    required IconData leadingIcon,
    required Widget subtitle,
    required VoidCallback? onPressed,
    required IconData trailingIcon,
    Color? leadingBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        color: cardColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: leadingBackgroundColor,
            child: Icon(leadingIcon),
          ),
          title: Text(widget.device.platformName),
          subtitle: subtitle,
          trailing: IconButton(
            onPressed: onPressed,
            icon: Icon(trailingIcon),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.device.isConnected) {
      return _buildDeviceCard(
        borderColor: Colors.blue,
        cardColor: Colors.blue.shade100,
        leadingIcon: Icons.bluetooth_connected,
        subtitle: Text(widget.device.remoteId.str),
        onPressed: isConnected ? widget.onOpen : widget.onConnect,
        trailingIcon: isConnected ? Icons.link : Icons.link_off,
      );
    } else if (widget.device.prevBondState == BluetoothBondState.bonding) {
      return _buildDeviceCard(
        borderColor: Colors.red,
        cardColor: Colors.red.shade100,
        leadingIcon: Icons.bluetooth_disabled,
        subtitle: Text('Pairing failed!', style: TextStyle(color: Colors.red.shade700, letterSpacing: 1.5)),
        onPressed: null,
        trailingIcon: Icons.lock_rounded,
        leadingBackgroundColor: Colors.red.shade100,
      );
    } else {
      return _buildDeviceCard(
        borderColor: Colors.blue,
        cardColor: Colors.blue.shade100,
        leadingIcon: Icons.bluetooth_connected,
        subtitle: Text(widget.device.remoteId.str),
        onPressed: isConnected ? widget.onOpen : widget.onConnect,
        trailingIcon: isConnected ? Icons.link : Icons.link_off,
      );
    }
  }
}
