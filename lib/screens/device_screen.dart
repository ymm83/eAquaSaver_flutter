import 'dart:async';
//import 'dart:math';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/snackbar_helper.dart';
import '../utils/extra.dart';
import '../bloc/beacon/beacon_bloc.dart';
import '../protoc/eaquasaver_msg.pb.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';

enum DeviceState {
  sleep,
  idle,
  tempAdjust,
  recovering,
}

String getDeviceState(int value) {
  switch (value) {
    case 0:
      return 'sleep'; //DeviceState.sleep;
    case 1:
      return 'idle'; //DeviceState.idle;
    case 2:
      return 'tempAdjust'; //DeviceState.tempAdjust;
    case 3:
      return 'recovering'; //DeviceState.recovering;
    default:
      return "unknow"; // throw Exception("unknow");
  }
}

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
  late final Map<String, dynamic> _beaconData = {};
  late Timer _beaconTimer;
  late String deviceState;

  @override
  void initState() {
    super.initState();
    //final supabaseClient = SupabaseProvider.of(context)?.supabaseClient;
    //context.read<BeaconBloc>().add(ListenBeacon('51:34:BE:F6:FA:3B'));
    //context.read<BeaconBloc>().add(StartScan());
    //context.read<BeaconBloc>().add(FakeData());
    //_beaconTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    //  context.read<BeaconBloc>().add(FakeData());
    //});
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

    _beaconTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      debugPrint('----------widget.device:${widget.device.platformName}');
      startBeaconScanning();
    });

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

  Map<String, dynamic> _decodeManufacturerData(List<int> data) {
    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage message = eAquaSaverMessage.fromBuffer(protobufData);

      //debugPrint("Tamaño del mensaje: $size");
      debugPrint("\nMensaje decodificado: --- START ---\n $message--- END ---");

      debugPrint('Temperatura caliente: ${message.hotTemperature}');
      debugPrint('\n----- message : ${message.totalRecovered.toString()}\n-------end message ----------\n');

      //debugPrint('hotTemperature: $hotTemperature');
      Map<String, dynamic> beaconData = {
        'temperature': message.temperature / 10,
        'hotTemperature': message.hotTemperature / 10,
        'coldTemperature': message.coldTemperature / 10,
        'targetTemperature': message.targetTemperature / 10,
        'minimalTemperature': message.minimalTemperature / 10,
        'ambientTemperature': message.ambientTemperature / 10,
        'currentHotUsed': message.currentHotUsed / 100,
        'currentRecovered': message.currentRecovered / 100,
        'currentColdUsed': message.currentColdUsed / 100,
        'totalColdUsed': message.totalColdUsed / 100,
        'totalRecovered': message.totalRecovered / 100,
        'totalHotUsed': message.totalHotUsed / 100,
        'state': message.state
      };
      debugPrint('------ beaconData: ${beaconData.toString()}');
      return beaconData;
    } catch (e) {
      return {};
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

  Future<void> startBeaconScanning() async {
    //debugPrint('---------- replace: ${widget.device.platformName.replaceRange(3, 4, 'b').length}');
    // String deviceName = widget.device.platformName;
    String beaconName = widget.device.platformName.replaceRange(3, 4, 'b');
    //debugPrint('---------- deviceName: ${deviceName.length}');

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) {
      //debugPrint('---------- results: ${results.length}');

      if (results.isNotEmpty) {
        try {
          for (var adv in results) {
            //debugPrint('---------- adv.advertisementData.advName: ${adv.advertisementData.advName.substring(0, 16)}');
            if (adv.advertisementData.advName.substring(0, 16) == beaconName) {
              debugPrint('----------send adversiting data---------------');
              if (adv.advertisementData.manufacturerData.isNotEmpty) {
                adv.advertisementData.manufacturerData.forEach((key, value) {
                  var decodedData = _decodeManufacturerData(value);
                  debugPrint('--- decoded: \n $decodedData');
                  context.read<BeaconBloc>().add(ListenBeacon(beaconData: decodedData));
                });
              }
            } else {
              continue;
            }
          }
        } catch (e) {
          debugPrint('Error al buscar el beacon: $e');
        }
      } else {
        //debugPrint('No se encontraron resultados en el escaneo.');
      }
    });
  }

  Future<void> _stopBeaconScanning() async {
    await FlutterBluePlus.stopScan();
    _beaconSubscription.cancel();
    _beaconData.clear();
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      showSnackBar("Connect: Success", theme: 'success');
    } catch (e) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // Ignorar conexiones canceladas por el usuario
      } else {
        showSnackBar("Connect Error: $e", theme: 'error');
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnect(queue: true);
      //await widget.device.removeBond();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      showSnackBar("Cancel: Success", theme: 'success');
    } catch (e) {
      showSnackBar("Cancel Error: $e", theme: 'error');
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnect();
      showSnackBar("Disconnect: Success", theme: 'success');
    } catch (e) {
      showSnackBar("Disconnect Error: $e", theme: 'error');
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
      showSnackBar("Discover Services: Success", theme: 'success');
    } catch (e) {
      showSnackBar("Discover Services Error:", theme: 'error');
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
      showSnackBar("Request Mtu: Success", theme: 'success');
    } catch (e) {
      showSnackBar("Change Mtu Error: $e", theme: 'error');
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
        //SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onDiscoverServicesPressed,
          icon: const Icon(Icons.bluetooth_connected_outlined),
          label: const Text("Get Services"),
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
      if (state is BeaconLoaded) {
        deviceState = getDeviceState(state.beaconData['state'] ?? 7);
      } else {
        deviceState = 'unknow';
      }
      return ScaffoldMessenger(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 7),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blue, width: 1.5), borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade100,
                  child: ListTile(
                    // leading: CircleAvatar(
                    //   child: Icon(isConnected ? Icons.bluetooth_connected_outlined : Icons.bluetooth_disabled_outlined),
                    // ),
                    leading: buildRssiTile(context),
                    title: const Text(
                      'eAquaSaver', //widget.device.platformName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    //subtitle: Text(widget.device.remoteId.toString()),
                    subtitle: (state is BeaconLoaded)
                        //? Text(widget.device.remoteId.toString())
                        ? RichText(
                            text: TextSpan(
                              text: 'status: ',
                              style: const TextStyle(
                                  fontSize: 11, color: Color.fromARGB(255, 5, 69, 85), fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: deviceState,
                                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                                ),
                              ],
                            ),
                          )
                        : Text(widget.device.remoteId.toString()),
                    trailing: buildConnectIcon(context),
                  ),
                ),
                if (state is BeaconLoaded) ...[
                  RichText(
                    text: TextSpan(
                      text: 'status: ',
                      style: const TextStyle(
                          fontSize: 11, color: Color.fromARGB(255, 5, 69, 85), fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${state.beaconData['state']} ',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                // Mostrar datos de beacon
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state is BeaconLoaded) ...[
                        Center(
                            child: Text(
                          'Temperature',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                        )),
                        Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Color.fromARGB(255, 149, 172, 190), width: 1),
                              borderRadius: BorderRadius.circular(10)),
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: ListTile(
                              leading: Transform.flip(
                                flipX: true,
                                child: Icon(
                                  Atlas.water_tap_thin,
                                  size: 30,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                if (state.beaconData['coldTemperature'].toString() == 'null')
                                  Text(
                                    '0 °C',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade700),
                                  ),
                                if (state.beaconData['coldTemperature'].toString() != 'null')
                                  Text(
                                    '${state.beaconData['coldTemperature'].toString().split('.')[0]} °C',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade700),
                                  ),
                                if (state.beaconData['temperature'].toString() == 'null')
                                  Text(
                                    '0',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green.shade800),
                                  ),
                                if (state.beaconData['temperature'].toString() != 'null')
                                  Text(
                                    state.beaconData['temperature'].toString().split('.')[0],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green.shade800),
                                  ),
                                if (state.beaconData['hotTemperature'].toString() == 'null')
                                  Text(
                                    '0 °C',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red.shade600),
                                  ),
                                if (state.beaconData['hotTemperature'].toString() != 'null')
                                  Text(
                                    '${state.beaconData['hotTemperature'].toString().split('.')[0]} °C',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red.shade600),
                                  ),
                              ]),
                              subtitle: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(
                                  'cold pipe',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'current',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                                ),
                                Text(
                                  'hot pipe',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ]),
                              trailing: Icon(
                                Atlas.water_tap_thin,
                                size: 30,
                                color: Colors.red.shade500,
                              )),
                        ),
                      ],
                      if (state is BeaconLoading) ...[
                        const Center(child: Text('Loading Beacon Data...', style: TextStyle())),
                        const Padding(
                            padding: EdgeInsets.only(left: 50, right: 50, top: 5),
                            child: LinearProgressIndicator(
                              color: Colors.blue,
                              backgroundColor: Colors.redAccent,
                            )),
                      ]
                    ],
                  ),
                ),
                //Center(child: buildConnectButton(context)),
                buildGetServices(context),

                //buildMtuTile(context),
                ..._buildServiceTiles(context, widget.device),
              ],
            ),
          ),
          //floatingActionButton: buildConnectButton(context),
        ),
      );
    });
  }
}
