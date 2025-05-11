import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SystemDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SystemDeviceTile({
    Key? key,
    required this.device,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<SystemDeviceTile> createState() => _SystemDeviceTileState();
}

class _SystemDeviceTileState extends State<SystemDeviceTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  BluetoothBondState _bondState = BluetoothBondState.none;
  
  late StreamSubscription<BluetoothConnectionState> _connectionSub;
  late StreamSubscription<BluetoothBondState> _bondSub;

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    _getInitialStates();
  }

  void _initSubscriptions() {
    _connectionSub = widget.device.connectionState.listen((state) {
      if (mounted && _connectionState != state) {
        setState(() => _connectionState = state);
      }
    });

    _bondSub = widget.device.bondState.listen((state) {
      if (mounted && _bondState != state) {
        setState(() => _bondState = state);
        debugPrint("Bond state changed to: $state");
      }
    });

    // Cancelar suscripciones cuando el dispositivo se desconecte
    widget.device.cancelWhenDisconnected(_connectionSub);
    widget.device.cancelWhenDisconnected(_bondSub);
  }

  Future<void> _getInitialStates() async {
    try {
      // Obtener estado de conexión inicial
      final connectionState = await widget.device.connectionState.first;
      if (mounted) {
        setState(() => _connectionState = connectionState);
      }

      // Obtener estado de bonding inicial
      final bondState = await widget.device.bondState.first;
      if (mounted) {
        setState(() => _bondState = bondState);
      }
    } catch (e) {
      debugPrint("Error getting initial states: $e");
    }
  }

  @override
  void dispose() {
    _connectionSub.cancel();
    _bondSub.cancel();
    super.dispose();
  }

  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isBonded => _bondState == BluetoothBondState.bonded;
  bool get isBonding => _bondState == BluetoothBondState.bonding;

  Color _getBorderColor() {
    if (isBonding) return Colors.orange;
    if (!isBonded) return Colors.red;
    return isConnected ? Colors.green : Colors.blue;
  }

  Color _getCardColor() {
    if (isBonding) return Colors.orange.shade50;
    if (!isBonded) return Colors.red.shade50;
    return isConnected ? Colors.green.shade50 : Colors.blue.shade50;
  }

  IconData _getLeadingIcon() {
    if (isBonding) return Icons.bluetooth_searching;
    if (!isBonded) return Icons.bluetooth_disabled;
    return isConnected ? Icons.bluetooth_connected : Icons.bluetooth;
  }

  String _getStatusText() {
    if (isBonding) return 'Pairing...';
    if (!isBonded) return 'Not paired';
    return isConnected ? 'Connected' : 'Disconnected';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: _getBorderColor(),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        color: _getCardColor(),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getBorderColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getLeadingIcon(),
                    color: _getBorderColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.platformName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.device.remoteId.str,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getBorderColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isConnected ? Icons.link : Icons.link_off,
                      color: _getBorderColor(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*import 'dart:async';

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
    super.key, required void Function() onTap,
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
}*/
