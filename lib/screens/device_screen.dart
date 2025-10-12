import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:eaquasaver/screens/unauthorized_screen.dart';
import 'package:eaquasaver/widgets/top_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:ble_data_converter/ble_data_converter.dart';
import '../utils/snackbar_helper.dart';
import '../utils/extra.dart';
import '../bloc/beacon/beacon_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import '../provider/supabase_provider.dart';
import '../protoc/eaquasaver_msg.pb.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../api/ble_characteristics_uuids.dart';
import '../utils/device_service.dart';

enum DeviceState {
  sleep,
  idle,
  tempAdjust,
  recovering,
}

String getDeviceState(int value) {
  switch (value) {
    case 1:
      return 'sleep';
    case 2:
      return 'idle';
    case 3:
      return 'tempAdjust';
    case 4:
      return 'recovering';
    default:
      return "unknow";
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final PageController pageController;

  const DeviceScreen({
    super.key,
    required this.device,
    required this.pageController,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<BluetoothBondState> _bsSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late StreamSubscription<List<ScanResult>> _beaconSubscription;
  late final Map<String, dynamic> _beaconData = {};
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Timer _beaconTimer;
  late String deviceState;
  late String eASSystemName;

  // Selector de temperatura
  double _currentValue = 60;
  String _cardAnnotationValue = '60';
  double _cardCurrentValue = 60;

  // Variables para el selector de dispositivos
  String? selectedDeviceId;
  // Mapa para gestionar el estado de conexión de múltiples dispositivos
  Map<String, BluetoothDevice> _connectedDevices = {};
  List<BluetoothDevice> _availableDevices = [];
  final List<Guid> withServices = [charEnabledUuid];

  // end selector
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  bool loading = false;
  String? role;
  DeviceService? deviceService;
  Device? _device;
  late List<BluetoothDevice> _systemDevices = [];
  UserProfile? _profile;
  Temperature? _temperature;
  final storage = FlutterSecureStorage();
  double tempGradoCelsius = 28;
  double fahrenheit = 60;
  double minValue = 32;
  double maxValue = 122;
  bool _isLoading = true;
  BluetoothBondState bondState = BluetoothBondState.none;

  double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  @override
  void initState() {
    super.initState();
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);

    // No nos suscribimos al estado de conexión de un solo dispositivo.
    // En su lugar, el UI reaccionará a los cambios de estado del Bloc.

    _beaconTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_connectedDevices.isNotEmpty) {
        startBeaconScanning();
      }
    });

    // La suscripción a la MTU sigue siendo relevante para el dispositivo actual
    // por lo que la mantenemos.
    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    if (Platform.isAndroid) {
      _bsSubscription = widget.device.bondState.listen((value) {
        setState(() {
          bondState = value;
        });
        if (value == BluetoothBondState.none && widget.device.prevBondState == BluetoothBondState.bonding) {
          _gotoScanScreenAsync();
        }
        if (value == BluetoothBondState.bonded && widget.device.prevBondState == BluetoothBondState.bonding) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      widget.device.cancelWhenDisconnected(_bsSubscription);
    } else if (Platform.isIOS) {
      setState(() {
        _isLoading = false;
      });
    }
    _initializeAsync();
    _initializeDeviceConnection();
  }

  Future<List<BluetoothDevice>> getSystemDevices() async {
    List<BluetoothDevice> _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    return _systemDevices;
  }

  Future<void> _gotoScanScreenAsync() async {
    await widget.device.disconnect(queue: true);
  }

  Future<void> _initializeAsync() async {
    setState(() {
      _isLoading = true;
    });

    deviceService = DeviceService(supabaseEAS, widget.device.platformName, supabase.auth.currentUser!.id);
    await deviceService?.insertDeviceIfNotExists();
    await deviceService?.registerUserDevice();
    role = await deviceService?.getUserRole();

    _device = await deviceService?.getDevice(cache: true);
    final profileData = await deviceService?.getUserProfileInfo();
    _profile = UserProfile.fromJson(profileData!);
    final info = await deviceService?.getUserDeviceInfo();
    await deviceService?.setCache(key: 'user_device', data: info);
    final temp = await deviceService?.getTemperature(cache: true);

    if (temp != null && temp['target_temperature'] != null) {
      _temperature = Temperature.fromJson(temp);
    }
    if (_temperature?.target != null) {
      tempGradoCelsius = _temperature!.target.toDouble();
      fahrenheit = celsiusToFahrenheit(tempGradoCelsius);
      _cardCurrentValue = fahrenheit;
      await _writeMinimalTemperature(_temperature!.minimal.toDouble());
      await _writeTargetTemperature(_temperature!.target.toDouble());
    }

    setState(() {
      _isLoading = false;
    });

    try {
      _systemDevices = await getSystemDevices();
      debugPrint(">>>>>> systemDevices: ${_systemDevices.toString()}");
    } catch (e) {
      showSnackBar("System Devices Error: $e", theme: "error");
    }
  }

  //🆕 FUNCIONES PARA EL SELECTOR DE DISPOSITIVOS
  Future<void> _initializeDeviceConnection() async {
    await _loadDevices();

    // Ahora, el estado de conexión se maneja por el Bloc.
    final bleState = context.read<BleBloc>().state;
    if (bleState is BleConnected) {
      final currentDevice = bleState.device;
      final isAvailable = _availableDevices.any((d) => d.remoteId == currentDevice.remoteId);

      if (isAvailable) {
        setState(() {
          _connectedDevices[currentDevice.remoteId.toString()] = currentDevice;
          selectedDeviceId = currentDevice.remoteId.toString();
        });
      }
    }
  }

  Future<void> _loadDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.systemDevices(withServices);
      setState(() {
        _availableDevices = devices;
      });
    } catch (e) {
      showSnackBar("Error al cargar dispositivos: $e", theme: "error");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    context.read<BleBloc>().add(ConnectToDevice(device));
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    context.read<BleBloc>().add(DisconnectFromDevice(device));
  }

  Widget _buildDeviceSelector() {
    final bleState = context.watch<BleBloc>().state;
    final isConnecting = bleState is BleConnecting && bleState.device.remoteId.toString() == selectedDeviceId;
    final isConnected = _connectedDevices.containsKey(selectedDeviceId);

    return ChoiceChip(
      selected: true,
      label: isConnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? _connectedDevices[selectedDeviceId]!.platformName : 'Seleccionar dispositivo',
                  style: TextStyle(
                    color: isConnected ? Colors.green : null,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
      onSelected: isConnecting ? null : (_) => _showDeviceSelectionDialog(),
    );
  }

  /*
  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar dispositivo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableDevices.length + 1,
            itemBuilder: (context, index) {
              if (index < _availableDevices.length) {
                final device = _availableDevices[index];
                final isConnected = _connectedDevices.containsKey(device.remoteId.toString());

                return ListTile(
                  leading: Icon(
                    Icons.bluetooth,
                    color: isConnected ? Colors.green : null,
                  ),
                  title: Text(
                    device.platformName,
                    style: TextStyle(
                      fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                      color: isConnected ? Colors.green : null,
                    ),
                  ),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: isConnected 
                    ? const Icon(Icons.check, color: Colors.green) 
                    : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (isConnected) {
                      _disconnectDevice(device);
                    } else {
                      _connectToDevice(device);
                      setState(() {
                        selectedDeviceId = device.remoteId.toString();
                      });
                    }
                  },
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.add, color: Colors.blue),
                  title: const Text(
                    'Añadir otro',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.pageController.jumpToPage(0);
                  },
                );
              }
            },
          ),
        ),
        actions: [
          if (_connectedDevices.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _connectedDevices.forEach((key, device) {
                  _disconnectDevice(device);
                });
                setState(() {
                  _connectedDevices.clear();
                  selectedDeviceId = null;
                });
              },
              child: const Text('Desconectar todos',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  */
  void _showDeviceSelectionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300), // Duración de la animación
      pageBuilder: (context, animation, secondaryAnimation) {
        // Este builder no se usa directamente para el contenido, pero es necesario
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Definimos la animación de deslizamiento
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, // Curva de animación
        );

        final tween = Tween(begin: Offset(0, 1), end: Offset.zero);

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              elevation: 10,
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.7, // 70% de la altura
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Seleccionar dispositivo',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableDevices.length + 1,
                        itemBuilder: (context, index) {
                          if (index < _availableDevices.length) {
                            final device = _availableDevices[index];
                            final isConnected = _connectedDevices.containsKey(device.remoteId.toString());

                            return ListTile(
                              leading: Icon(
                                Icons.bluetooth,
                                color: isConnected ? Colors.green : null,
                              ),
                              title: Text(
                                device.platformName,
                                style: TextStyle(
                                  fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                                  color: isConnected ? Colors.green : null,
                                ),
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: isConnected ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: () {
                                Navigator.pop(context);
                                if (isConnected) {
                                  _disconnectDevice(device);
                                } else {
                                  _connectToDevice(device);
                                  setState(() {
                                    selectedDeviceId = device.remoteId.toString();
                                  });
                                }
                              },
                            );
                          } else {
                            return ListTile(
                              leading: const Icon(Icons.add, color: Colors.blue),
                              title: const Text(
                                'Añadir otro',
                                style: TextStyle(color: Colors.blue),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.pageController.jumpToPage(0);
                              },
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_connectedDevices.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _connectedDevices.forEach((key, device) {
                                  _disconnectDevice(device);
                                });
                                setState(() {
                                  _connectedDevices.clear();
                                  selectedDeviceId = null;
                                });
                              },
                              child: const Text('Desconectar todos', style: TextStyle(color: Colors.red)),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🏁 FIN DE FUNCIONES PARA SELECTOR DE DISPOSITIVOS
  Map<String, dynamic> _decodeManufacturerData(List<int> data) {
    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage message = eAquaSaverMessage.fromBuffer(protobufData);
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
      return beaconData;
    } catch (e) {
      return {};
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _bsSubscription.cancel();
    }
    _mtuSubscription.cancel();
    _beaconTimer.cancel();
    _stopBeaconScanning();
    // No necesitamos cancelar _connectionStateSubscription porque ya no está presente
    context.read<BeaconBloc>().add(ClearBeacon());
    super.dispose();
  }

  bool get isConnected {
    // La lógica de conexión ahora se basa en el mapa
    return _connectedDevices.containsKey(selectedDeviceId);
  }

  Future<void> startBeaconScanning() async {
    String beaconName = widget.device.platformName.replaceRange(3, 4, 'b');

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        try {
          for (var adv in results) {
            if (adv.advertisementData.advName.substring(0, 16) == beaconName) {
              if (adv.advertisementData.manufacturerData.isNotEmpty) {
                adv.advertisementData.manufacturerData.forEach((key, value) {
                  var decodedData = _decodeManufacturerData(value);
                  context.read<BeaconBloc>().add(ListenBeacon(beaconData: decodedData));
                });
              }
            }
          }
        } catch (e) {
          // Ignorar errores de escaneo
        }
      }
    });
  }

  Future<void> _stopBeaconScanning() async {
    await FlutterBluePlus.stopScan();
    if (_beaconSubscription != null) {
      _beaconSubscription.cancel();
    }
    _beaconData.clear();
  }

  Future onConnectPressed() async {
    // Ya no necesitamos esta lógica aquí, el Bloc la maneja
    // Solo necesitamos llamar al evento del Bloc
    if (selectedDeviceId != null) {
      try {
        final deviceToConnect = _availableDevices.firstWhere((d) => d.remoteId.toString() == selectedDeviceId);
        _connectToDevice(deviceToConnect);
      } catch (e) {
        showSnackBar("Dispositivo no encontrado", theme: "error");
      }
    }
  }

  String fixedDeviceName(String name) {
    return name.replaceRange(3, 4, 's').substring(0, 16);
  }

  Future<dynamic> existsDeviceAdmin(String userId, String realName) async {
    final fixedName = fixedDeviceName(realName);
    try {
      final response = await supabaseEAS
          .from('user_device')
          .select('device_id')
          .eq('device_id', fixedName)
          .eq('role', 'Admin')
          .count();
      return response.count;
    } catch (error) {
      return 0;
    }
  }

  Future onCancelPressed() async {
    if (selectedDeviceId != null) {
      try {
        final deviceToCancel = _availableDevices.firstWhere((d) => d.remoteId.toString() == selectedDeviceId);
        await deviceToCancel.disconnect(queue: true);
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
        showSnackBar("Cancel: Success", theme: "success");
      } catch (e) {
        showSnackBar("Cancel Error: $e", theme: "error");
      }
    }
  }

  Future onDisconnectPressed() async {
    if (selectedDeviceId != null) {
      try {
        final deviceToDisconnect = _availableDevices.firstWhere((d) => d.remoteId.toString() == selectedDeviceId);
        _disconnectDevice(deviceToDisconnect);
      } catch (e) {
        showSnackBar("Dispositivo no encontrado", theme: "error");
      }
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
      showSnackBar("Discover Services: Success", theme: "success");
    } catch (e) {
      showSnackBar("Discover Services Error:", theme: "error");
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future showBondingBox() async {
    try {
      await widget.device.createBond(timeout: 240);
      debugPrint("Bonding success");
    } catch (e) {
      debugPrint("Bonding error: $e");
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
      showSnackBar("Request Mtu: Success", theme: "success");
    } catch (e) {
      showSnackBar("Change Mtu Error: $e", theme: "error");
    }
  }

  void onValueChanging(ValueChangingArgs args) {
    if (args.value > 60) {
      args.cancel = true;
    }
  }

  void onvalueChanged(double value) {}

  void handlePointerValueChanged(dynamic value) {
    if (value.toInt() > 6) {
      setState(() {
        _currentValue = value.roundToDouble();
      });
    }
  }

  void handlePointerValueChanging(ValueChangingArgs args) {
    if (args.value.toInt() <= 6) {
      args.cancel = true;
    }
  }

  void handleCardPointerValueChanged(double value) {
    if (value.toInt() > 6) {
      setState(() {
        _cardCurrentValue = value.roundToDouble();
        tempGradoCelsius = fahrenheitToCelsius(_cardCurrentValue);
        final int cardCurrentValue = _cardCurrentValue.toInt();
        _cardAnnotationValue = '$cardCurrentValue';
      });
    }
  }

  void handleCardPointerValueChanging(ValueChangingArgs args) {
    if (args.value.toInt() <= 6) {
      args.cancel = true;
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
    final bleState = context.watch<BleBloc>().state;
    final isConnecting = bleState is BleConnecting && bleState.device.remoteId.toString() == selectedDeviceId;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (isConnecting) buildSpinner(context),
      OutlinedButton.icon(
        onPressed: isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
        icon: Icon(isConnecting
            ? Icons.cancel_outlined
            : (isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected_outlined)),
        label: Text(isConnecting ? 'Cancel' : (isConnected ? 'Disconnect' : 'Connect')),
      )
    ]);
  }

  Widget buildConnectIcon(BuildContext context) {
    final bleState = context.watch<BleBloc>().state;
    final isConnecting = bleState is BleConnecting && bleState.device.remoteId.toString() == selectedDeviceId;

    return CircleAvatar(
      backgroundColor: Colors.blue.shade400,
      child: IconButton(
        splashColor: Colors.greenAccent,
        highlightColor: Colors.blue.shade600,
        onPressed: isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
        icon: Icon(isConnecting
            ? Icons.cancel_outlined
            : (isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected_outlined)),
      ),
    );
  }

  final List<Color> gradientColors = [
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  final List<double> gradientStops = [0.0, 0.5, 1.0];

  Color getCurrentPointerColor(double value, double min, double max) {
    double normalizedValue = (value - min) / (max - min);
    return interpolateColor(gradientColors, gradientStops, normalizedValue);
  }

  Future _writeStateDevice(int state) async {
    if (selectedDeviceId == null) {
      showSnackBar("No hay dispositivo seleccionado", theme: "error");
      return;
    }
    final connectedDevice = _connectedDevices[selectedDeviceId]!;

    final stateBytes = BLEDataConverter.u8.intToBytes(state * 10, endian: Endian.little);
    List<BluetoothService> services = await connectedDevice.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid == servEAquaSaverUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charEnabledUuid) {
            await characteristic.write(stateBytes);
            debugPrint('charEnabledUuid writed');
          }
        }
      }
    }
  }

  Future _writeTargetTemperature(double temperature) async {
    if (selectedDeviceId == null) {
      showSnackBar("No hay dispositivo seleccionado", theme: "error");
      return;
    }
    final connectedDevice = _connectedDevices[selectedDeviceId]!;

    debugPrint('_writeTargetTemperature param: ${temperature.toInt().toString()}');
    int targetTemperature = temperature.toInt() * 10;
    final targetBytes = BLEDataConverter.u16.intToBytes(targetTemperature, endian: Endian.big);
    List<BluetoothService> services = await connectedDevice.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == servEAquaSaverUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charTargetTemperatureUuid) {
            await characteristic.write(targetBytes);
            debugPrint('chTargetTemperatureUuid characteristic true');
          }
        }
      }
    }
  }

  Future _writeMinimalTemperature(double temperature) async {
    if (selectedDeviceId == null) {
      showSnackBar("No hay dispositivo seleccionado", theme: "error");
      return;
    }
    final connectedDevice = _connectedDevices[selectedDeviceId]!;
    debugPrint('_writeMinimalTemperature param: ${temperature.toInt().toString()}');
    int minimalTemperature = temperature.toInt() * 10;
    final minimalBytes = BLEDataConverter.u16.intToBytes(minimalTemperature, endian: Endian.big);
    List<BluetoothService> services = await connectedDevice.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == servEAquaSaverUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charMinimalTemperatureUuid) {
            await characteristic.write(minimalBytes);
            debugPrint('chMinimalTemperatureUuid characteristic true');
          }
        }
      }
    }
  }

  Color interpolateColor(List<Color> colors, List<double> stops, double t) {
    for (int i = 0; i < stops.length - 1; i++) {
      if (t >= stops[i] && t <= stops[i + 1]) {
        double localT = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], localT)!;
      }
    }
    return colors.last;
  }

  Widget _buildIcon(int beaconState) {
    if (beaconState == 2) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.redAccent,
          strokeWidth: 4,
          backgroundColor: Colors.blue[300],
        ),
      );
    } else {
      return Icon(
        Icons.power_settings_new_outlined,
        color: beaconState < 2 ? Colors.black : Colors.red,
        size: 30,
      );
    }
  }

  Widget _buildIconRole(String? role) {
    IconData iconData;
    if (role == 'Admin') {
      iconData = Icons.admin_panel_settings;
    } else if (role == 'Member') {
      iconData = Icons.person;
    } else if (role == 'Credits') {
      iconData = Icons.credit_card;
    } else if (role == 'Recerved') {
      iconData = Icons.calendar_month;
    } else {
      iconData = Icons.lock_outline;
    }

    return role != null
        ? Icon(
            iconData,
            size: 40,
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleBloc, BleState>(
      listener: (context, state) {
        if (state is BleConnected) {
          _connectedDevices[state.device.remoteId.toString()] = state.device;
          showSnackBar("Conectado a ${state.device.platformName}", theme: "success");
          setState(() {});
        } else if (state is BleDisconnected) {
          _connectedDevices.remove(state.device.remoteId.toString());
          showSnackBar("Dispositivo ${state.device.platformName} desconectado", theme: "success");
          setState(() {});
        } else if (state is BleConnectionFailed) {
          showSnackBar("Error de conexión: ${state.error}", theme: "error");
        }
      },
      child: BlocBuilder<BeaconBloc, BeaconState>(
        builder: (context, state) {
          final isConnected = _connectedDevices.containsKey(selectedDeviceId);
          debugPrint('.......... ${state.runtimeType} \n------- end -----');

          Widget mainContent;

          if (!isConnected) {
            mainContent = const Center(
                child: Text("Connecting ...",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic)));
          } else if (state is BeaconLoading) {
            mainContent = const Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Column(
                children: [
                  Text('Loading data ...', style: TextStyle()),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    color: Colors.blue,
                    backgroundColor: Colors.redAccent,
                  ),
                ],
              ),
            );
          } else if (state is BeaconLoaded) {
            final beaconData = state.beaconData;
            deviceState = getDeviceState(beaconData['state']);
            _rssi = beaconData['rssi'];

            mainContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (role == 'Admin' || role == 'Member') ...[
                  Center(
                    child: Stack(children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: SfRadialGauge(
                          axes: <RadialAxis>[
                            RadialAxis(
                              backgroundImage: const AssetImage('./assets/light_frame.png'),
                              minimum: 0,
                              maximum: 50,
                              interval: 5,
                              radiusFactor: 0.5,
                              showAxisLine: false,
                              labelOffset: 5,
                              useRangeColorForAxis: true,
                              showLastLabel: true,
                              axisLabelStyle: GaugeTextStyle(fontWeight: FontWeight.bold),
                              ranges: <GaugeRange>[
                                GaugeRange(
                                    startValue: 0,
                                    endValue: 20,
                                    sizeUnit: GaugeSizeUnit.factor,
                                    color: Colors.blue,
                                    endWidth: 0.03,
                                    startWidth: 0.03),
                                GaugeRange(
                                    startValue: 20,
                                    endValue: 30,
                                    sizeUnit: GaugeSizeUnit.factor,
                                    color: Colors.yellow,
                                    endWidth: 0.03,
                                    startWidth: 0.03),
                                GaugeRange(
                                    startValue: 30,
                                    endValue: 50,
                                    sizeUnit: GaugeSizeUnit.factor,
                                    color: Colors.red,
                                    endWidth: 0.03,
                                    startWidth: 0.03),
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                    widget: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          '${tempGradoCelsius.toInt()}',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'Times',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
                                        ),
                                        Text(
                                          '°C',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'Times',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
                                        )
                                      ],
                                    ),
                                    positionFactor: 0.8,
                                    angle: 90)
                              ],
                            ),
                            RadialAxis(
                              showLastLabel: true,
                              ticksPosition: ElementsPosition.inside,
                              labelsPosition: ElementsPosition.outside,
                              minorTicksPerInterval: 5,
                              axisLineStyle: AxisLineStyle(
                                thicknessUnit: GaugeSizeUnit.factor,
                                thickness: 0.1,
                              ),
                              axisLabelStyle: GaugeTextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              radiusFactor: 0.97,
                              majorTickStyle:
                                  MajorTickStyle(length: 0.1, thickness: 2, lengthUnit: GaugeSizeUnit.factor),
                              minorTickStyle:
                                  MinorTickStyle(length: 0.05, thickness: 1.5, lengthUnit: GaugeSizeUnit.factor),
                              minimum: minValue,
                              maximum: maxValue,
                              interval: 5,
                              startAngle: 130,
                              endAngle: 50,
                              ranges: <GaugeRange>[
                                GaugeRange(
                                    startValue: 32,
                                    endValue: 122,
                                    startWidth: 0.1,
                                    sizeUnit: GaugeSizeUnit.factor,
                                    endWidth: 0.1,
                                    gradient: SweepGradient(stops: gradientStops, colors: gradientColors))
                              ],
                              pointers: <GaugePointer>[
                                MarkerPointer(
                                    value: _cardCurrentValue,
                                    onValueChanged: handleCardPointerValueChanged,
                                    onValueChangeEnd: handleCardPointerValueChanged,
                                    onValueChanging: handleCardPointerValueChanging,
                                    enableDragging: bondState == BluetoothBondState.bonded ? true : false,
                                    enableAnimation: false,
                                    markerHeight: 30,
                                    markerWidth: 30,
                                    markerType: MarkerType.invertedTriangle,
                                    color: getCurrentPointerColor(_cardCurrentValue, minValue, maxValue),
                                    overlayRadius: 0,
                                    borderWidth: 2,
                                    markerOffset: 10,
                                    borderColor: Colors.yellow.shade800)
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                    widget: Text(
                                      '${_cardCurrentValue.toInt()} °F',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                    ),
                                    positionFactor: 0.55,
                                    angle: 90),
                                if (state is BeaconLoaded) ...[
                                  GaugeAnnotation(
                                      widget: Text(
                                        '${state.beaconData['coldTemperature'].toString()} °C',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                      ),
                                      positionFactor: 0.8,
                                      angle: 90)
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      //if (state is BeaconLoaded) ...[
                      Positioned(
                        top: 122,
                        left: 125,
                        child: FloatingActionButton.small(
                          shape: const CircleBorder(),
                          backgroundColor: getCurrentPointerColor(_cardCurrentValue, minValue, maxValue),
                          elevation: 10,
                          highlightElevation: 10,
                          onPressed: bondState == BluetoothBondState.bonded
                              ? () async {
                                  final updates = {'target_temperature': tempGradoCelsius};
                                  final userId = supabase.auth.currentUser!.id;
                                  await _writeTargetTemperature(tempGradoCelsius);
                                  //await _storage.write(key: userId, value: json.encode({'target_temperature': tempGradoCelsius}));
                                  //todo add minimal check to update
                                  await supabaseEAS.from('user_profile').update(updates).eq('id', userId);
                                }
                              : null,
                          child: const Icon(
                            Atlas.medium_thermometer_bold,
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: 0,
                        child: SizedBox(
                          height: 80,
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Atlas.cold_temperature_thermometer_bold,
                                color: Colors.blue,
                              ),
                              Text(
                                state.beaconData['coldTemperature'].toString(),
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        right: 0,
                        child: SizedBox(
                          height: 80,
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Atlas.hot_temperature_bold,
                                color: Colors.red,
                              ),
                              Text(
                                state.beaconData['hotTemperature'].toString(),
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      /*] else ...[
                        Positioned(
                            top: 125,
                            left: 130,
                            child: CircularProgressIndicator(
                              color: Colors.green.shade700,
                              backgroundColor: Colors.lightGreen.shade200,
                            )),
                      ],*/
                      //if (state is BeaconLoading || state is BeaconInitial) ...[CircularProgressIndicator()],
                    ]),
                  ),
                  SizedBox(height: 30,),
                  

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      OutlinedButton.icon(
                      onPressed: () async {
                        debugPrint('---- >> state.beaconData[state]: ${state.beaconData['state']}');
                        if (_isLoading || state.beaconData['state'] == 2) {
                          return;
                        }
                        try {
                          setState(() {
                            _isLoading = true;
                          });
                          if (state.beaconData['state'] < 2) {
                            // Power On
                            await _writeStateDevice(5);
                          }
                          if (state.beaconData['state'] > 2) {
                            // Power Off
                            await _writeStateDevice(1);
                          }
                        } catch (e) {
                          debugPrint('---- Change device state error: $e');
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      label: Text(state.beaconData['state'] < 2
                          ? 'Power On'
                          : state.beaconData['state'] == 2
                              ? 'Working'
                              : 'Power Off'),
                      icon: _buildIcon(state.beaconData['state']),
                       style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    ]),
                
                  const Divider(
                    height: 10,
                    thickness: 1,
                    color: Colors.blue,
                  ),
                  /*
                  ListTile(
                    leading: _buildIcon(beaconData['state']),
                    title: Text(
                      'Device State: $deviceState',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  */
                  ListTile(
                    leading: _buildIconRole(role),
                    title: Text(
                      'Your Role: ${role ?? 'Guest'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                ] else if (role == null) ...[
                  //Center(child: CircularProgressIndicator())
                ] else if (role == 'Credits') ...[
                  Text('Buy credits to use this device!'),
                ] else if (role == 'Recerved') ...[
                  Text('Recerved mode!')
                ] else ...[
                  Unauthorized(),
                ],
              ],
            );
          } else {
            mainContent = const Center(
                child: Text("Connecting ...",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic)));
            //Center(child: CircularProgressIndicator())
          }

          return ScaffoldMessenger(
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TopLoadingIndicator(isLoading: _isLoading),
                    Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.blue, width: 1.5),
                          borderRadius: BorderRadius.circular(10)),
                      color: Colors.blue.shade100,
                      child: ListTile(
                        title: Row(
                          children: [
                            _buildDeviceSelector(),
                            const SizedBox(width: 10),
                            if (context.watch<BleBloc>().state is BleConnecting &&
                                (context.watch<BleBloc>().state as BleConnecting).device.remoteId.toString() ==
                                    selectedDeviceId)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (isConnected)
                              const Icon(Icons.bluetooth_connected, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                          ],
                        ),
                        subtitle: (state is BeaconLoaded)
                            ? RichText(
                                text: TextSpan(
                                  text: 'status: ',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blueAccent.shade700, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: deviceState,
                                      style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1),
                                    ),
                                    TextSpan(
                                      text: _rssi != null ? '(${_rssi!} dBm)' : '',
                                      style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1),
                                    ),
                                    TextSpan(
                                      text: role != null ? '  Role:': '',
                                      style: TextStyle(
                                          color: Colors.blueAccent.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1),
                                    ),
                                    TextSpan(
                                      text: role != null ? ' $role' : '',
                                      style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              )
                            : Text(selectedDeviceId ?? 'No device selected'),
                      ),
                    ),
                    mainContent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
