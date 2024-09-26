import 'dart:async';
//import 'dart:math';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/extra.dart';
import '../bloc/beacon/beacon_bloc.dart';
import '../protoc/eaquasaver_msg.pb.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
//import '../provider/supabase_provider.dart';

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

      debugPrint('Temperatura caliente: ${message.hotTemperature.join()}');
      debugPrint('\n----- message : ${message.totalRecovered.toString()}\n-------end message ----------\n');

      var hotTemperature = double.parse("${message.hotTemperature.join('.')}");
      debugPrint('hotTemperature: ${hotTemperature}');
      Map<String, dynamic> beaconData = {
        'temperature': message.temperature,
        'hotTemperature': message.hotTemperature,
        'coldTemperature': message.coldTemperature,
        'currentHotUsed': message.currentHotUsed,
        'currentRecovered': message.currentRecovered,
        'totalColdUsed': message.totalColdUsed == 0 ? 8444 : message.totalColdUsed,
        'totalRecovered': message.totalRecovered==0 ? 12544 : message.totalRecovered,
        'totalHotUsed': message.totalHotUsed==0 ? 10576 : message.totalHotUsed,
        
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
    //debugPrint('---------- replace: ${widget.device.platformName.replaceRange(3, 4, 'b')}');
    String deviceName = widget.device.platformName;
    String beaconName = 'eASb-${deviceName.split('-')[1]}';

    await FlutterBluePlus.startScan();
    _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) {
      //debugPrint('---------- results.length: ${results.length}');

      if (results.isNotEmpty) {
        try {
          for (var adv in results) {
            if (adv.advertisementData.advName.substring(0, 17) == beaconName) {
              debugPrint('----------siiiiiiiiiiiiiiiiiiiiii---------------');
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
          //debugPrint('Error al buscar el beacon: $e');
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
      return ScaffoldMessenger(
        key: Snackbar.snackBarKeyC,
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
                    title: Text(
                      widget.device.platformName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(widget.device.remoteId.toString()),
                    trailing: buildConnectIcon(context),
                  ),
                ),

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
                                Text(
                                  '${state.beaconData['coldTemperature'].toString().split('.')[0]} °C',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade700),
                                ),
                                Text(
                                  state.beaconData['temperature'].toString().split('.')[0],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green.shade800),
                                ),
                                Text(
                                  '${state.beaconData['hotTemperature'].toString().split('.')[0]} °C',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red.shade600),
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
