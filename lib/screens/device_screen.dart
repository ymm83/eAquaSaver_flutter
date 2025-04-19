import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
//import 'dart:math';
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
      return 'sleep'; //DeviceState.sleep;
    case 2:
      return 'idle'; //DeviceState.idle;
    case 3:
      return 'tempAdjust'; //DeviceState.tempAdjust;
    case 4:
      return 'recovering'; //DeviceState.recovering;
    default:
      return "unknow"; // throw Exception("unknow");
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final PageController pageController;
  //final String? role;
  const DeviceScreen({super.key, required this.device, required this.pageController}); //, this.role

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
  //double _markerValue = 58;
  //double _firstMarkerSize = 10;
  //double _annotationFontSize = 25;
  //String _annotationValue = '60';
  String _cardAnnotationValue = '60';
  double _cardCurrentValue = 60;
  //double _cardMarkerValue = 58;
  // end selector
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  bool loading = false;
  String? role;
  DeviceService? deviceService;
  Device? _device;
  UserProfile? _profile;
  Temperature? _temperature;
  final storage = new FlutterSecureStorage();
  double tempGradoCelsius = 28;
  double fahrenheit = 60;
  double minValue = 32; // Valor mínimo del gauge
  double maxValue = 122; // Valor máximo del gauge
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
        _services = [];
      } else if (state == BluetoothConnectionState.disconnected) {
        debugPrint('--------------- D I S C O N E C T E D');
        _stopBeaconScanning();
        widget.pageController.jumpToPage(0);
      }

      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _beaconTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      //debugPrint('----------widget.device:${widget.device.platformName}');
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
        //widget.pageController.jumpToPage(0);
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
        //debugPrint("--------$value prev:${widget.device.prevBondState}");
        //debugPrint("--------disconnectReason: ${widget.device.disconnectReason}");
      });
      widget.device.cancelWhenDisconnected(_bsSubscription);
    } else if (Platform.isIOS) {
      setState(() {
        _isLoading = false;
      });
    }
    _initializeAsync();
  }

  Future<void> _gotoScanScreenAsync() async {
    await widget.device.disconnect(queue: true);
  }

  Future<void> _initializeAsync() async {
    setState(() {
      _isLoading = true; // 👈 **Cambio**: Comienza la carga
    });

    deviceService = DeviceService(supabaseEAS, widget.device.platformName, supabase.auth.currentUser!.id);
    await deviceService?.insertDeviceIfNotExists();
    await deviceService?.registerUserDevice();
    role = await deviceService?.getUserRole();

    _device = await deviceService?.getDevice(cache: true);
    final profileData = await deviceService?.getUserProfileInfo();
    //debugPrint('------ profileData: ${profileData.toString()}');
    _profile = UserProfile.fromJson(profileData!);
    final info = await deviceService?.getUserDeviceInfo();
    await deviceService?.setCache(key: 'user_device', data: info);
    final temp = await deviceService?.getTemperature(cache: true);
    debugPrint('------ profileData: ${temp.toString()}');

    if (temp != null && temp['target_temperature'] != null) {
      _temperature = Temperature.fromJson(temp);
      //debugPrint('->>>----- Temperature.fromJson(temp): ${_temperature!.target}');
    }
    if (_temperature?.target != null) {
      //debugPrint('>>>>>------ temperature > target: ${_temperature!.target}');
      tempGradoCelsius = _temperature!.target.toDouble();
      fahrenheit = celsiusToFahrenheit(tempGradoCelsius);
      _cardCurrentValue = fahrenheit;
      await _writeMinimalTemperature(_temperature!.minimal.toDouble());
      await _writeTargetTemperature(_temperature!.target.toDouble());
    } else {
      //_temperature = Temperature(minimal: 25, target: 30);
    }
    //}
    //debugPrint('------ profile: ${_profile!.targetTemperature}');
    setState(() {
      _isLoading = false; // 👈 **Cambio**: Finaliza la carga
    });
    /*if (mounted) {
        
      setState(() {});
    }*/
  }

  Map<String, dynamic> _decodeManufacturerData(List<int> data) {
    try {
      int size = data[0];
      var protobufData = data.sublist(1, size + 1);
      eAquaSaverMessage message = eAquaSaverMessage.fromBuffer(protobufData);
      //debugPrint('------ eAquaSaverMessage: ${message.toString()}');
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
      // debugPrint('------ beaconData: ${beaconData.toString()}');
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
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _beaconTimer.cancel();
    _stopBeaconScanning();

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
                  debugPrint('\n minimalTemperature: ${decodedData['minimalTemperature'].toString()}');
                  debugPrint('\n targetTemperature: ${decodedData['targetTemperature'].toString()}');
                  debugPrint('\n state: ${decodedData['state'].toString()}');

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
      showSnackBar("Connect: Success", theme: 'success');
    } catch (e) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // Ignorar conexiones canceladas por el usuario
      } else {
        showSnackBar("Connect Error: $e", theme: 'error');
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
          //.eq('user_id', userId)
          .count();

      return response.count;
    } catch (error) {
      //debugPrint('eeee Error fetching device ID: $error');
      return 0;
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

  Future showBondingBox() async {
    try {
      await widget.device.createBond(timeout: 240);
      debugPrint("Bonding success");
      //showSnackBar("Request Mtu: Success", theme: 'success');
    } catch (e) {
      //showSnackBar("Change Mtu Error: $e", theme: 'error');
      debugPrint("Bonding error: $e");
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

  //////  Circular Slider
  ///
  /// Dragged pointer new value is updated to pointer and
  /// annotation current value.
  ///
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
        final int currentValue = _currentValue.toInt();
        //_annotationValue = '$currentValue';
        //_markerValue = _currentValue - 2;
      });
    }
  }

  /// Pointer dragging is canceled when dragging pointer value is less than 6.
  void handlePointerValueChanging(ValueChangingArgs args) {
    if (args.value.toInt() <= 6) {
      args.cancel = true;
    }
  }

  /// Dragged pointer new value is updated to pointer and
  /// annotation current value.
  void handleCardPointerValueChanged(double value) {
    //debugPrint('******------ handleCardPointerValueChanged: ${value.toInt()}');
    if (value.toInt() > 6) {
      setState(() {
        _cardCurrentValue = value.roundToDouble();
        tempGradoCelsius = fahrenheitToCelsius(_cardCurrentValue);
        final int cardCurrentValue = _cardCurrentValue.toInt();
        _cardAnnotationValue = '$cardCurrentValue';
        //_cardMarkerValue = _cardCurrentValue - 2;
      });
    }
  }

  /// Pointer dragging is canceled when dragging pointer value is less than 6.
  void handleCardPointerValueChanging(ValueChangingArgs args) {
    if (args.value.toInt() <= 6) {
      args.cancel = true;
    }
  }

  ///  END

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

  // Definir el gradiente del rango (azul a rojo)
  final List<Color> gradientColors = [
    Colors.blue, // Color para el valor más bajo
    Colors.yellow, // Color intermedio
    Colors.red, // Color para el valor más alto
  ];

  // Posiciones de los colores en el gradiente (0.0 es el inicio, 1.0 es el final)
  final List<double> gradientStops = [0.0, 0.5, 1.0];

  // Función para obtener el color actual del gradiente en función del valor del puntero
  Color getCurrentPointerColor(double value, double min, double max) {
    double normalizedValue = (value - min) / (max - min); // Normalizar valor entre 0.0 y 1.0
    return interpolateColor(gradientColors, gradientStops, normalizedValue);
  }

  Future _writeStateDevice(int state) async {
    final stateBytes = BLEDataConverter.u8.intToBytes(state * 10, endian: Endian.little);
    List<BluetoothService> services = await widget.device.discoverServices();
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

    //debugPrint('Start adjTemp ${temperature.toInt()}  $targetBytes');
  }

  Future _writeTargetTemperature(double temperature) async {
    debugPrint('_writeTargetTemperature param: ${temperature.toInt().toString()}');
    int targetTemperature = temperature.toInt() * 10;
    final targetBytes = BLEDataConverter.u16.intToBytes(targetTemperature, endian: Endian.big);
    List<BluetoothService> services = await widget.device.discoverServices();

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

    //debugPrint('Start adjTemp ${temperature.toInt()}  $targetBytes');
  }

  Future _writeMinimalTemperature(double temperature) async {
    debugPrint('_writeMinimalTemperature param: ${temperature.toInt().toString()}');
    int minimalTemperature = temperature.toInt() * 10;
    final minimalBytes = BLEDataConverter.u16.intToBytes(minimalTemperature, endian: Endian.big);
    List<BluetoothService> services = await widget.device.discoverServices();

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

    //debugPrint('Start adjTemp ${temperature.toInt()}  $minimalBytes');
  }

  // Función para interpolar colores en el gradiente
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
    // Controlar la animación según el estado
    if (beaconState == 2) {
      return SizedBox(
        width: 20, // Ancho deseado
        height: 20, // Alto deseado
        child: CircularProgressIndicator(
          color: Colors.redAccent,
          strokeWidth: 4,
          backgroundColor: Colors.blue[300], // Ancho de la línea del indicador
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
    ///debugPrint('role: $role');
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
    //double fahrenheit = double.tryParse(_cardAnnotationValue) ?? 0;
    //double tempGradoCelsius = _temperature?.target.toDouble() ?? ((fahrenheit - 32) * 5 / 9);
    //double minValue = 32; // Valor mínimo del gauge
    //double maxValue = 122; // Valor máximo del gauge
    return BlocBuilder<BeaconBloc, BeaconState>(builder: (context, state) {
      if (state is BeaconLoaded) {
        deviceState = getDeviceState(state.beaconData['state']);
      } else {
        deviceState = 'unknow';
      }
      //return BlocBuilder<BleBloc, BleState>(builder: (context, bleState) {
      // Obtén el rol si el estado es BleDetailsOpen, de lo contrario deja role como null
      //  final role = bleState is BleDetailsOpen ? bleState.role : null;

      return ScaffoldMessenger(
        child: Scaffold(
          //appBar: AppBarLoadingIndicator(isLoading: _isLoading),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TopLoadingIndicator(isLoading: _isLoading),
                //const SizedBox(height: 7),
                /*if(bondState==BluetoothBondState.bonded)...[
                  Text('$bondState'),
                ]else if(bondState==BluetoothBondState.none)...[
                  Text('$bondState'),
                ]else if(bondState==BluetoothBondState.bonding)...[
                  Text('$bondState'),
                ],*/

                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blue, width: 1.5), borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade100,
                  child: ListTile(
                    // leading: CircleAvatar(
                    //   child: Icon(isConnected ? Icons.bluetooth_connected_outlined : Icons.bluetooth_disabled_outlined),
                    // ),
                    //leading: _buildIconRole(role), //buildRssiTile(context),
                    title: Row(
                      children: [
                        isConnected ? const Icon(Icons.bluetooth_connected) : const Icon(Icons.bluetooth_disabled),
                        //Text(_device?.customName ?? ' eAquaSaver ', //widget.device.platformName,
                        Text(_device?.customName ?? widget.device.platformName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (isConnected && _rssi != null) Text('(${_rssi!} dBm)', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    //subtitle: Text(widget.device.remoteId.toString()),
                    subtitle: /*Row(children: [
                      buildRssiTile(context),*/
                        (state is BeaconLoaded)
                            //? Text(widget.device.remoteId.toString())
                            ? RichText(
                                text: TextSpan(
                                  text: 'status: ',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color.fromARGB(255, 5, 69, 85), fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: deviceState,
                                      style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              )
                            : Text(widget.device.remoteId.toString()),
                    //]),
                    trailing: buildConnectIcon(context),
                  ),
                ),
                if (state is BeaconLoading /*|| role == null*/) ...[
                  const Center(child: Text('Loading Beacon Data...', style: TextStyle())),
                  const Padding(
                      padding: EdgeInsets.only(left: 50, right: 50, top: 5),
                      child: LinearProgressIndicator(
                        color: Colors.blue,
                        backgroundColor: Colors.redAccent,
                      )),
                ],
                /*if (state is BeaconLoaded && role == null) ...[
                  const Center(child: Text('Unauthorized...', style: TextStyle())),
                ],*/
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(children: [
                          SizedBox(
                            width: 300, // Establecer el ancho
                            height: 300, // Establecer la altura
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

                                    /*GaugeAnnotation(
                                  widget: Text(
                                    '°C',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                  ),
                                  positionFactor: 0.8,
                                  angle: 90)*/
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
                                        color: getCurrentPointerColor(
                                            _cardCurrentValue, minValue, maxValue), //Colors.green.shade800,
                                        overlayRadius: 0,
                                        borderWidth: 2,
                                        markerOffset: 10,
                                        borderColor: Colors.yellow.shade800)
                                  ],
                                  /*NeedlePointer(
                                  value: _cardCurrentValue,
                                  onValueChanged: handleCardPointerValueChanged,
                                  onValueChangeEnd: handleCardPointerValueChanged,
                                  onValueChanging: handleCardPointerValueChanging,
                                  enableDragging: true,
                                  //value: 60,
                                  needleColor: Colors.black,
                                  tailStyle: TailStyle(
                                      length: 0.18, width: 8, color: Colors.black, lengthUnit: GaugeSizeUnit.factor),
                                  needleLength: 2,
                                  needleStartWidth: 1,
                                  needleEndWidth: 8,
                                  knobStyle: KnobStyle(
                                      knobRadius: 0.07,
                                      color: Colors.white,
                                      borderWidth: 0.05,
                                      borderColor: Colors.black),
                                  lengthUnit: GaugeSizeUnit.factor)*/

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
                          if (state is BeaconLoaded) ...[
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
                          ] else ...[
                            Positioned(
                                top: 125,
                                left: 130,
                                child: CircularProgressIndicator(
                                  color: Colors.green.shade700,
                                  backgroundColor: Colors.lightGreen.shade200,
                                )),
                          ],
                          //if (state is BeaconLoading || state is BeaconInitial) ...[CircularProgressIndicator()],
                        ]),
                      ),
                    ],
                  ),
                ),
                if (_isLoading) ...[
                  Text(
                      bondState == BluetoothBondState.none || bondState == BluetoothBondState.bonded
                          ? 'Starting...'
                          : 'Bonding...',
                      style: TextStyle()), // 👈 **Cambio**: Mensaje de carga
                ] else if (role == null) ...[
                  const Center(child: Text('Unauthorized...', style: TextStyle())),
                ] else if (['Admin', 'Member'].contains(role)) ...[
                  // Mostrar datos de beacon

                  if (state is BeaconLoaded) ...[
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
                        icon: _buildIcon(state.beaconData['state'])),
                  ]
                  /*IconButton(
                      onPressed: () async {
                        final t = await existsDeviceAdmin(supabase.auth.currentUser!.id, widget.device.platformName);
                        debugPrint('----- $t');
                      },
                      icon: Icon(Icons.get_app)),

                  //buildMtuTile(context),*/
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
            ),
          ),
        ),
      );
    });
    //});
  }
}
