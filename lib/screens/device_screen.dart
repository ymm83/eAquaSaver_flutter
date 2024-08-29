import 'dart:async';
import 'dart:math';
import 'package:eaquasaver_flutter_app/bloc/beacon/beacon_bloc.dart';
import 'package:eaquasaver_flutter_app/utils/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../protoc/eaquasaver_msg.pb.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
import '../widgets/temperature_chart.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late StreamSubscription<List<ScanResult>> _beaconSubscription;
  late Map<String, dynamic> _beaconData = {};
  late Timer _beaconTimer;

  @override
  void initState() {
    super.initState();
    //context.read<BeaconBloc>().add(ListenBeacon('51:34:BE:F6:FA:3B'));
    //context.read<BeaconBloc>().add(StartScan());
    context.read<BeaconBloc>().add(FakeData());
    _beaconTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      context.read<BeaconBloc>().add(FakeData());
    });
    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // Debe redescubrir servicios
      } else if (state == BluetoothConnectionState.disconnected) {
        _stopBeaconScanning();
      }

      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    /*_beaconTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _startBeaconScanning();
    });*/

    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription = widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

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
    debugPrint("Data: ${data}");

    if (data.isEmpty) {
      debugPrint('Error: Los datos están vacíos.');
      return;
    }

    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage decodedMessage = eAquaSaverMessage.fromBuffer(protobufData);

      debugPrint("Tamaño del mensaje: $size");
      debugPrint("\nMensaje decodificado: --- START ---\n $decodedMessage--- END ---");

      debugPrint('Temperatura caliente: ${decodedMessage.hotTemperature}');
      debugPrint('Temperatura fría: ${decodedMessage.coldTemperature}');
      if (mounted) {
        setState(() {
          _beaconData = {
            'temperature': decodedMessage.temperature,
            'hotTemperature': decodedMessage.hotTemperature / 10.0,
            'coldTemperature': decodedMessage.coldTemperature / 10.0,
            'currentHotUsed': decodedMessage.currentHotUsed,
            'currentRecovered': decodedMessage.currentRecovered,
            'totalColdUsed': decodedMessage.totalColdUsed,
            'totalRecovered': decodedMessage.totalRecovered,
            'totalHotUsed': decodedMessage.totalHotUsed,
          };
        });
      }
    } catch (e) {
      debugPrint('Error al decodificar los datos: $e');
    }
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _stopBeaconScanning();
    _beaconTimer.cancel();
    context.read<BeaconBloc>().add(ClearBeacon());
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future<void> _startBeaconScanning() async {
    // FAKE DATA
    debugPrint('------------GENERANDO DATOS FAKE---------------');
    _beaconData = {
      'fake': true,
      'temperature': Random().nextInt(10) + 20,
      'hotTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)) + 25,
      'coldTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)),
      'currentHotUsed': Random().nextInt(30) + 20,
      'currentRecovered': Random().nextInt(19) + 1,
      'totalColdUsed': Random().nextInt(500) + 10000,
      'totalRecovered': Random().nextInt(500) + 10000,
      'totalHotUsed': Random().nextInt(500) + 10000,
    };
    setState(() {});
    // ******  END FAKE DATA *******, uncomment next for true

    /*await FlutterBluePlus.startScan(
        withRemoteIds: [widget.device.remoteId.toString()], timeout: const Duration(seconds: 3));
    _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        String name = r.device.advName;
        if (name.startsWith('eAquaS')) {
          if (name == 'eAquaS Beacon') {
            if (r.device.remoteId == widget.device.remoteId) {
              _processManufacturerData(r.advertisementData);
            }
          }
        }
      }
    });*/
  }

  Future<void> _stopBeaconScanning() async {
    await FlutterBluePlus.stopScan();
    _beaconSubscription.cancel();
    _beaconData.clear();
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // Ignorar conexiones canceladas por el usuario
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnect(queue: true);
      //await widget.device.removeBond();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnect();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e), success: false);
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e), success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e), success: false);
    }
  }

  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics.map((c) => _buildCharacteristicTile(c)).toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles: c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
    );
  }

  Widget buildSpinner(BuildContext context) {
    return const SizedBox(
        width: 30,
        height: 30,
        child: Padding(
          padding: EdgeInsets.all(14.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: CircularProgressIndicator(
              backgroundColor: Colors.black12,
              color: Colors.black26,
            ),
          ),
        ));
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected ? const Icon(Icons.bluetooth_connected) : const Icon(Icons.bluetooth_disabled),
        if (isConnected && _rssi != null) Text('${_rssi!} dBm', style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: onDiscoverServicesPressed,
          child: const Text("Get Services"),
        ),
        const IconButton(
          alignment: Alignment.topRight,
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      OutlinedButton.icon(
        onPressed: _isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
        icon: Icon(_isConnecting
            ? Icons.cancel_outlined
            : (isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected_outlined)),
        label: Text(_isConnecting ? 'Cancel' : (isConnected ? 'Disconnect' : 'Connect')),
      )
    ]);
  }

  Widget buildConnectIcon(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.blue.shade400,
      child: IconButton(
        splashColor: Colors.greenAccent,
        highlightColor: Colors.blue.shade600,
        onPressed: _isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
        icon: Icon(_isConnecting
            ? Icons.cancel_outlined
            : (isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected_outlined)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeaconBloc, BeaconState>(builder: (context, state) {
      List<Widget> beaconWidget = [];
      if (state is BeaconLoaded) {
        beaconWidget.add(Text('temperature: ${state.beaconData['temperature']}'));
        beaconWidget.add(Text('hotTemperature: ${state.beaconData['hotTemperature']}'));
        beaconWidget.add(Text('coldTemperature: ${state.beaconData['coldTemperature']}'));
      }
      return ScaffoldMessenger(
        key: Snackbar.snackBarKeyC,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 7),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.blue, width: 1.5), borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade100,
                  child: ListTile(
                    // leading: CircleAvatar(
                    //   child: Icon(isConnected ? Icons.bluetooth_connected_outlined : Icons.bluetooth_disabled_outlined),
                    // ),
                    leading: buildRssiTile(context),
                    title: Text(
                      widget.device.platformName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(widget.device.remoteId.toString()),
                    trailing: buildConnectIcon(context),
                  ),
                ),

                //Center(child: buildConnectButton(context)),
                buildGetServices(context),

                //buildMtuTile(context),
                ..._buildServiceTiles(context, widget.device),
                // Mostrar datos de beacon
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state is BeaconLoaded)
                        if (state.beaconData.isNotEmpty)
                          const Text('Beacon Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (state is BeaconLoaded)
                        if (beaconWidget.isNotEmpty) // Verificar si hay datos
                          ...beaconWidget.map((widget) {
                            return widget;
                          }),
                      if (state is BeaconLoading)
                        const Center(child: Text('Loading Beacon Data...', style: TextStyle())),
                      if (state is BeaconLoading)
                        const Padding(
                            padding: EdgeInsets.only(left: 50, right: 50, top: 5),
                            child: LinearProgressIndicator(
                              color: Colors.blue,
                              backgroundColor: Colors.redAccent,
                            )),
                      // Text(state.toString()),
                      if (state is BeaconLoaded) TemperatureChart(beaconData: state.beaconData),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //floatingActionButton: buildConnectButton(context),
        ),
      );
    });
  }
}
