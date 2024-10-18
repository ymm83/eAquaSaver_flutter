import 'dart:convert';
import 'dart:typed_data';

import 'package:eaquasaver/bloc/connectivity/connectivity_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:ble_data_converter/ble_data_converter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../provider/supabase_provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../api/ble_characteristics_uuids.dart';
import '../utils/snackbar_helper.dart';

class DeviceSettings extends StatefulWidget {
  final BluetoothDevice? device;

  const DeviceSettings({super.key, this.device});

  @override
  DeviceSettingsState createState() => DeviceSettingsState();
}

class DeviceSettingsState extends State<DeviceSettings> {
  double minimalTemperature = 10;
  double targetTemperature = 30;
  late String firmwareVersion;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  late Map userData;

  @override
  void initState() {
    getFirmwareVersion();
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateMinimalValue(double newValue) {
    if (newValue < targetTemperature) {
      setState(() {
        minimalTemperature = newValue;
      });
    }
  }

  void _updateTargetValue(double newValue) {
    if (newValue > minimalTemperature) {
      setState(() {
        targetTemperature = newValue;
      });
    }
  }

  void _updateFirstPointer(double newValue) async {
    final userId = supabase.auth.currentUser!.id;
    if (newValue < targetTemperature) {
      setState(() {
        minimalTemperature = newValue;
      });
      await _handleMinimalTemperature(minimalTemperature);
      await _storage.write(key: userId, value: json.encode({'target_temperatureemperature': minimalTemperature}));
      await supabaseEAS
          .from('user_profile')
          .update({'minimal_temperatureemperature': minimalTemperature}).eq('id', userId);
    }
  }

  Future _handleMinimalTemperature(double temperature) async {
    int minimalTemperature = temperature.toInt() * 10;
    //debugPrint('minimalTemperature: ${minimalTemperature.toString()} ');
    final minimalBytes = BLEDataConverter.u16.intToBytes(minimalTemperature, endian: Endian.big);

    List<BluetoothService> services = await widget.device!.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == servEAquaSaverUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charMinimalTemperatureUuid) {
            await characteristic.write(minimalBytes);
            debugPrint('Minimal Temperature written to characteristic');
          }
        }
      }
    }

    //debugPrint('Start adjTemp ${temperature.toInt()}  $targetBytes');
  }

  void _updateSecondPointer(double newValue) {
    if (newValue > minimalTemperature) {
      setState(() {
        targetTemperature = newValue;
      });
    }
  }

  int bytesToVersion(List<int> bytes) {
    if (bytes.length == 4) {
      return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    } else if (bytes.length == 3) {
      return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | 0; // Asignar 0 a VERSION_TWEAK
    } else {
      throw Exception('La lista de bytes debe tener exactamente 3 o 4 elementos.');
    }
  }

  String versionToString(int version) {
    int major = (version >> 24) & 0xFF;
    int minor = (version >> 16) & 0xFF;
    int patch = (version >> 8) & 0xFF;
    int tweak = version & 0xFF;

    return '$major.$minor.$patch+$tweak';
  }

  Future<void> getFirmwareVersion() async {
    late List<int> firmwareVersionBytes;
    late int firmwareVersionInt;
    late String firmwareVersionString;
    List<BluetoothService> services = await widget.device!.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == servEAquaSaverUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charFirmwareVersionUuid) {
            firmwareVersionBytes = await characteristic.read();

            firmwareVersionInt = bytesToVersion(firmwareVersionBytes);
            firmwareVersionString = versionToString(firmwareVersionInt);
            setState(() {
              firmwareVersion = firmwareVersionString;
            });
            debugPrint('------- firmwareVersion: $firmwareVersionString}');
          }
        }
      }
    }

    //debugPrint('Start adjTemp ${temperature.toInt()}  $targetBytes');
  }

  Future updateFirmware() async {
    await NordicDfu().startDfu(
      widget.device!.remoteId.toString(),
      'assets/firmware/app.zip',
      fileInAsset: true,
      onProgressChanged: (
        deviceAddress,
        percent,
        speed,
        avgSpeed,
        currentPart,
        partsTotal,
      ) {
        debugPrint('deviceAddress: $deviceAddress, percent: $percent');
      },
    );
  }

  Future<Map> _getOnlineTemperature() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final userId = supabase.auth.currentUser!.id;
      userData = await supabaseEAS
          .from('user_profile')
          .select('minimal_temperature, target_temperature')
          .eq('id', userId)
          .single();
      if (userData['minimal_temperature'].runtimeType == Null) {
        userData.remove('minimal_temperature');
        userData = {'minimal_temperature': 20, ...userData};
      }

      if (userData['target_temperature'].runtimeType == Null) {
        userData.remove('target_temperature');
        userData = {'target_temperature': 30, ...userData};
      }

      debugPrint('----- userData online: ${userData.toString()}');
      //await _storage.delete(key: supabase.auth.currentUser!.id);
      await _storage.write(key: supabase.auth.currentUser!.id, value: json.encode(userData));
      //setState(() {});
      return userData;
    } on PostgrestException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
      userData = {};
      setState(() {});
    } catch (error) {
      /*if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
      }*/
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  /// Called once a user id is received within `onAuthenticated()`
  Future<Map> _getLocalTemperature() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final data = await _storage.read(key: supabase.auth.currentUser!.id);
      debugPrint('---- Reading Secure Storage');
      //data = jsonDecode(onValue!);

      userData = json.decode(data!) ?? {};
      //userData['firstname'] = 'Loba';
      debugPrint('---userData offline - ${userData.toString()}');
      return userData;
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  Future addTargetTemperature(int temperature) async {
    //supabaseEAS.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOnline) {
          return Column(
            children: [
              const Center(child: Text('Temperature entries:')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('minimal'),
                  SfLinearGauge(
                    minimum: 0, // Valor mínimo del gauge
                    maximum: 50, // Valor máximo del gauge
                    interval: 5, // Intervalo de los valores
                    axisTrackStyle: LinearAxisTrackStyle(
                      thickness: 5, // Ancho de la línea del eje
                      color: Colors.grey[300], // Color de la línea
                    ),
                    markerPointers: [
                      LinearShapePointer(
                        value: minimalTemperature,
                        /*onChangeStart: (double newValue) {
                          minimalTemperature = newValue;
                        },*/
                        onChanged: _updateMinimalValue,
                        /*onChangeEnd: (double newValue) {
                          minimalTemperature = newValue;
                        },*/
                        shapeType: LinearShapePointerType.invertedTriangle,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('target'),
                  SfLinearGauge(
                    minimum: 0, // Valor mínimo del gauge
                    maximum: 50, // Valor máximo del gauge
                    interval: 5, // Intervalo de los valores
                    axisTrackStyle: LinearAxisTrackStyle(
                      thickness: 5, // Ancho de la línea del eje
                      color: Colors.grey[300], // Color de la línea
                    ),
                    markerPointers: [
                      LinearShapePointer(
                        value: targetTemperature,
                        /*onChangeStart: (double newValue) {
                          targetTemperature = newValue;
                        },*/
                        onChanged: _updateTargetValue,
                        //onChangeEnd: _updateMinimalValue,
                        shapeType: LinearShapePointerType.invertedTriangle,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SfLinearGauge(
                    minimum: 0, // Valor mínimo del gauge
                    maximum: 50, // Valor máximo del gauge
                    interval: 5, // Intervalo de los valores
                    axisTrackStyle: LinearAxisTrackStyle(
                      thickness: 5, // Ancho de la línea del eje
                      color: Colors.grey[300], // Color de la línea
                    ),
                    ranges: <LinearGaugeRange>[
                      LinearGaugeRange(
                        startValue: 0,
                        endValue: 20,
                        color: Colors.blue[300],
                      ),
                      LinearGaugeRange(
                        startValue: 20,
                        endValue: 30,
                        color: Colors.yellow[300],
                      ),
                      LinearGaugeRange(
                        startValue: 30,
                        endValue: 50,
                        color: Colors.red[300],
                      ),
                    ],
                    markerPointers: [
                      LinearShapePointer(
                        value: minimalTemperature,
                        height: 30, // Altura del puntero
                        width: 30, // Ancho del puntero
                        shapeType: LinearShapePointerType.invertedTriangle,
                        color: Colors.blue[300], // Color del primer puntero
                        dragBehavior: LinearMarkerDragBehavior.constrained,
                        onChanged: _updateMinimalValue,
                      ),
                      LinearShapePointer(
                        value: targetTemperature,
                        height: 30, // Altura del puntero
                        width: 30, // Ancho del puntero
                        shapeType: LinearShapePointerType.invertedTriangle,
                        color: Colors.red[300], // Color del segundo puntero
                        dragBehavior: LinearMarkerDragBehavior.constrained,
                        onChanged: _updateTargetValue,
                      ),
                    ],
                    // Agregar marcadores de temperatura opcionales
                  )
                ],
              ),
              SizedBox(height: 20),
              // Mostrar los valores de los punteros
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Container(
                      color: Colors.blue[300], // Color de fondo para _firstPointer
                      padding: EdgeInsets.all(4), // Padding opcional
                      child: Text(
                        minimalTemperature.toStringAsFixed(1),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  Text('minimalTemperature: ', style: TextStyle(fontSize: 18)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Container(
                      color: Colors.red[300], // Color de fondo para _secondPointer
                      padding: EdgeInsets.all(4), // Padding opcional
                      child: Text(
                        targetTemperature.toStringAsFixed(1),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const Text('targetTemperature: ', style: TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(
                height: 80,
              ),
              Text('FIRMWARE'),
              Row(
                children: [Text('Current version: $firmwareVersion}')],
              ),
              Row(
                children: [Text('RemoteId: ${widget.device!.remoteId}')],
              ),
              Row(
                children: [
                  Center(
                    child: TextButton.icon(
                        icon: const Icon(Icons.system_update),
                        onPressed: () async {
                          await updateFirmware();
                        },
                        label: const Text('Update')),
                  )
                ],
              ),
            ],
          );
        } else if (state is ConnectivityOffline) {
          return const Text('Sin conexión!');
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
