import 'dart:typed_data';

import 'package:eaquasaver/bloc/connectivity/connectivity_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:ble_data_converter/ble_data_converter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:path_provider/path_provider.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../provider/supabase_provider.dart';
import '../api/ble_characteristics_uuids.dart';
import '../utils/device_service.dart';
import '../utils/snackbar_helper.dart';
import 'disconnected_screen.dart';

class DeviceSettings extends StatefulWidget {
  final BluetoothDevice? device;
  //final String? role;
  const DeviceSettings({super.key, this.device}); //, this.role

  @override
  DeviceSettingsState createState() => DeviceSettingsState();
}

class DeviceSettingsState extends State<DeviceSettings> {
  String firmwareVersion = '';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  Map<String, dynamic> firmwareData = {};

  double _downloadProgress = 0.0;
  String _statusMessage = "Esperando...";
  bool firmwareDownloaded = false;
  bool firmwareDownloading = false;
  String firmwareFile = "";
  TaskStatus firmwareTask = TaskStatus.enqueued;
  int toggleValue = 1;
  DeviceService? deviceService;
  String? role;
  final TextEditingController _textController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  Device? device;
  final storage = const FlutterSecureStorage();

  num? minimalTemperature;
  num? targetTemperature;
  // default values of temperature
  num iniMinimalTemperature = 20;
  num iniTargetTemperature = 30;
  // device temperature
  num? _dMinimalTemperature;
  num? _dTargetTemperature;
  // profile temperature
  num? _pMinimalTemperature;
  num? _pTargetTemperature;

  @override
  void initState() {
    super.initState();
    minimalTemperature = iniMinimalTemperature;
    targetTemperature = iniTargetTemperature;
    getFirmwareVersion();
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    deviceService = DeviceService(supabaseEAS, widget.device!.platformName, supabase.auth.currentUser!.id);
    toggleValue = 1;
    _initializeAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeAsync() async {
    role = await deviceService?.getUserRole(cache: true);
    debugPrint(':::::::::::::::::::::::::::role: $role');
    if (role == 'Admin') {
      firmwareData = await _searchFirmwareUpdates();
    }
    await _initializeTemperatureAsync();

    device = await deviceService?.getDevice(cache: true);

    _textController.text = device!.customName ?? '';
    setState(() {});
  }

  Future<void> _initializeTemperatureAsync({int toggle = 1}) async {
    if (toggle == 1) {
      final deviceT = await deviceService!.getTemperature(source: 'device', cache: true);

      minimalTemperature = deviceT['minimal_temperature'] ?? iniMinimalTemperature;
      targetTemperature = deviceT['target_temperature'] ?? iniTargetTemperature;
      debugPrint('---->>>>> device temperature: ${deviceT.toString()}');
    }
    if (toggle == 2) {
      final profileT = await deviceService!.getTemperature(source: 'profile', cache: true);
      debugPrint('---->>>>> device temperature ***: ${profileT.toString()}');

      minimalTemperature = profileT['minimal_temperature'] ?? iniMinimalTemperature;
      targetTemperature = profileT['target_temperature'] ?? iniTargetTemperature;
      debugPrint('---->>>>> profile temperature: ${profileT.toString()}');
    }
    setState(() {});
  }

  Future<Map<String, dynamic>> _searchFirmwareUpdates() async {
    try {
      //firmwareVersion compare;
      final newVersionData = await supabaseEAS
          .from('firmware')
          .select('version, file_id, release_dt')
          .order('id', ascending: false)
          .limit(1)
          .single();

      return newVersionData;
      //debugPrint('firmware version data: ${newVersionData.toString()}');
    } catch (e) {
      setState(() {
        _statusMessage = 'errors.unexpected'.tr();
      });
      return {};
      //debugPrint('Excepción: $e');
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveText() async {
    _toggleEditing();
    setState(() {
      _isSaving = true;
    });
    try {
      final data = {
        'custom_name': _textController.text,
      };
      final response =
          await supabaseEAS.from('device').update(data).eq('id', deviceService!.fixedName).select('*').single();
      //debugPrint('Error inserting device: ${response.toString()}');
      if (response.containsKey('id')) {
        await deviceService?.setCache(key: 'device', data: response);
        //await deviceService?.setCache(key: 'custom_name', value: _textController.text);
        final cache_device = await deviceService?.getCache(key: 'device');
        if (cache_device != null) {
          Device device = Device.fromJson(cache_device);
          debugPrint('************** device class: ${device.customName} ****************');
        }
        debugPrint('************** cache_device: ${cache_device.toString()} ****************');

        //return true;
        //debugPrint('Dispositivo registrado con ID: ${response['id']}');
      } else {
        // return false;
        //debugPrint('Error: No se obtuvo el ID del dispositivo registrado.');
      }
    } catch (error) {
      //return false;
      debugPrint('Error inserting device: $error');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _downloadFirmware() async {
    try {
      final storage = supabase.storage.from('firmware_updates');
      final response = await storage.createSignedUrl(firmwareData['file_id'], 20);
      debugPrint('firmware file: $response');

      if (response.isEmpty) {
        setState(() {
          _statusMessage = 'errors.url_firmware'.tr();
        });
        return;
      }

      final firmwareUrl = response;

      // 3. Obtener el directorio de almacenamiento local (documentos)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/firmware/${firmwareData['file_id']}';

      final task = DownloadTask(
          url: firmwareUrl,
          filename: firmwareData['file_id'],
          directory: 'firmware',
          baseDirectory: BaseDirectory.applicationDocuments);

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) => {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = '${'ui.label.downloading'.tr()}... ${(progress * 100).toStringAsFixed(2)}%';
          })
        },
        onStatus: (status) => {
          setState(() {
            firmwareTask = status;
          }),
          debugPrint('Status: $status'),
        },
      );

      switch (result.status) {
        case TaskStatus.failed:
          debugPrint('Download failed');

        case TaskStatus.waitingToRetry:
          debugPrint('Download retry');

        case TaskStatus.complete:
          setState(() {
            firmwareDownloaded = true;
            firmwareFile = '${directory.path}/firmware/${result.task.filename}';
          });
          debugPrint('Success! $firmwareFile');

        case TaskStatus.canceled:
          debugPrint('Download was canceled');

        case TaskStatus.paused:
          debugPrint('Download was paused');

        default:
          debugPrint('Download not successful');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'errors.unexpected'.tr();
      });
      debugPrint('Excepción: $e');
    }
  }

  Widget _buildTaskStatusIcon(BuildContext context, TaskStatus task) {
    late IconData icon;
    switch (task) {
      case TaskStatus.complete:
        icon = Icons.cloud_done;
      case TaskStatus.failed:
      case TaskStatus.canceled:
      case TaskStatus.notFound:
        icon = Icons.cloud_off;
      case TaskStatus.waitingToRetry:
        icon = Icons.restart_alt;
      case TaskStatus.running:
        icon = Icons.downloading;
      default:
        icon = Icons.cloud_download;
    }
    return Icon(icon);
  }

  void _updateMinimalValue(double newValue) {
    if (newValue < targetTemperature!) {
      setState(() {
        minimalTemperature = newValue.toInt();
      });
    }
  }

  void _updateTargetValue(double newValue) {
    if (newValue > minimalTemperature!) {
      setState(() {
        targetTemperature = newValue.toInt();
      });
    }
  }

  Future _handleMinimalTemperature(double temperature) async {
    int minimalTemperature = temperature.toInt() * 10;

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
  }

  void _updateFirstPointer(double newValue) async {
    //final userId = supabase.auth.currentUser!.id;
    if (newValue < targetTemperature!) {
      setState(() {
        minimalTemperature = newValue.toInt();
      });
      await _handleMinimalTemperature(newValue);
      //await _storage.write(key: userId, value: json.encode({'target_temperature': minimalTemperature}));
      //await supabaseEAS.from('user_profile').update({'minimal_temperature': minimalTemperature}).eq('id', userId);
    }
  }

  void _updateSecondPointer(double newValue) {
    if (newValue > minimalTemperature!) {
      setState(() {
        targetTemperature = newValue.toInt();
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
      firmwareFile,
      fileInAsset: false,
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

  String fixedDeviceName(String name) {
    return name.replaceRange(3, 4, 's').substring(0, 16);
  }

  Future<void> addTemperature(int toggle, int? minimal, int? target) async {
    Map<String, dynamic> updates = {'minimal_temperature': minimal, 'target_temperature': target};
    debugPrint('---updated Map:${updates.toString()}');
    try {
      if (toggle == 0 || toggle == 1) {
        await deviceService!.updateUserDevice(data: updates);
      }
      if (toggle == 2) {
        await deviceService!.updateUserProfile(data: updates);
      }
      await _initializeTemperatureAsync(toggle: toggle);
      debugPrint('---toggle:$toggle--- temperature updated---');
    } catch (e) {
      //
    }
  }

  Widget _buildRoleIcon(String? role) {
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

    return role != null ? Icon(iconData) : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOnline) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                _buildRoleIcon(role),
                Text('$role'),
                //if (role == 'Admin') ...[
                Text(
                  'ui.label.custom_name'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                Row(
                  children: [
                    const Icon(Icons.settings_bluetooth, size: 24.0), // Ícono BLE
                    const SizedBox(width: 10), // Espaciado
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        readOnly: !_isEditing,
                        maxLength: 16,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                        icon: _isSaving == false
                            ? Icon(_isEditing ? Icons.save_as : Icons.edit)
                            : CircularProgressIndicator(
                                color: Colors.green.shade700,
                                backgroundColor: Colors.lightGreen.shade200,
                              ),
                        onPressed: () async {
                          _isEditing ? await _saveText() : _toggleEditing();
                        }),
                  ],
                ),
                // ],

                const SizedBox(height: 10),
                Divider(
                  thickness: 5,
                  height: 10,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  'ui.label.temperature'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                Card.outlined(
                  //color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text('device_temperature'.tr()),
                        ToggleSwitch(
                          activeFgColor: Colors.white,
                          inactiveBgColor: Colors.grey,
                          inactiveFgColor: Colors.white,
                          activeBgColors: [
                            const [Colors.red],
                            [Colors.purple.shade400],
                            [Colors.purple.shade800]
                          ],
                          initialLabelIndex: toggleValue,
                          cornerRadius: 20.0,
                          totalSwitches: 3,
                          minWidth: 50,
                          minHeight: 33,
                          labels: const ['', 'this', 'all'],
                          icons: const [Icons.delete_outline, null, null],
                          onToggle: (index) async {
                            if (index != null) {
                              setState(() {
                                toggleValue = index;
                              });
                              await _initializeTemperatureAsync(toggle: toggleValue);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 10),
                  child: Column(
                    children: [
                      if (toggleValue == 0) ...[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('device.delete_temperature'.tr(),
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                                style: const ButtonStyle(
                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 1, horizontal: 10)),
                                  minimumSize: WidgetStatePropertyAll(Size(0, 27)),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  iconSize: WidgetStatePropertyAll(18),
                                  side: WidgetStatePropertyAll(
                                    // Define el color y grosor del borde
                                    BorderSide(
                                        color: Colors.black54,
                                        width: 1), // Cambia `Colors.red` por el color que prefieras
                                  ), // Tamaño del ícono
                                ),
                                onPressed: () {
                                  setState(() {
                                    toggleValue = 1;
                                  }); // Ejecutar la acción al confirmar
                                },
                                label: Text(
                                  'ui.btn.cancel'.tr().toLowerCase(),
                                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(
                                  Icons.clear_outlined,
                                  color: Colors.black54,
                                )),
                            const SizedBox(
                              width: 15,
                            ),
                            OutlinedButton.icon(
                                style: const ButtonStyle(
                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 1, horizontal: 10)),
                                  minimumSize: WidgetStatePropertyAll(Size(0, 27)),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  iconSize: WidgetStatePropertyAll(18),
                                  side: WidgetStatePropertyAll(
                                    // Define el color y grosor del borde
                                    BorderSide(color: Colors.red, width: 1),
                                  ),
                                ),
                                onPressed: () async {
                                  await addTemperature(0, null, null);
                                  setState(() {
                                    toggleValue = 1;
                                  });
                                },
                                label: Text(
                                  'ui.btn.confirm'.tr().toLowerCase(),
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(
                                  Icons.check_outlined,
                                  color: Colors.red,
                                )),
                          ],
                        )
                      ],
                      if (toggleValue == 1) ...[
                        Center(
                          child: Text('device.save_temperature_this'.tr(), style: TextStyle(color: Colors.purple.shade400)),
                        ),
                      ],
                      if (toggleValue == 2) ...[
                        Center(
                          child:
                              Text('device.save_temperature_all'.tr(), style: TextStyle(color: Colors.purple.shade800)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (toggleValue != 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          child: RichText(
                            textAlign: TextAlign.right,
                            text: TextSpan(
                              text: "${'ui.label.minimal'.tr()}: ",
                              style: const TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: SizedBox(
                            width: 25,
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                  text: minimalTemperature.toString(),
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SfLinearGauge(
                            minimum: 0, // Valor mínimo del gauge
                            maximum: 50, // Valor máximo del gauge
                            interval: 5, // Intervalo de los valores
                            axisTrackStyle: LinearAxisTrackStyle(
                              thickness: 5, // Ancho de la línea del eje
                              color: Colors.grey[300], // Color de la línea
                            ),
                            markerPointers: [
                              LinearShapePointer(
                                value: minimalTemperature!.toDouble(),
                                onChanged: _updateMinimalValue,
                                onChangeEnd: (value) async {
                                  await addTemperature(toggleValue, value.toInt(), targetTemperature!.toInt());
                                },
                                shapeType: LinearShapePointerType.invertedTriangle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          child: RichText(
                            textAlign: TextAlign.right,
                            text: TextSpan(
                              text: "${'ui.label.target'.tr()}: ",
                              style: TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: SizedBox(
                              width: 25,
                              child: RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                    text: targetTemperature.toString(),
                                    style:
                                        const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            )),
                        Expanded(
                          child: SfLinearGauge(
                            minimum: 0, // Valor mínimo del gauge
                            maximum: 50, // Valor máximo del gauge
                            interval: 5, // Intervalo de los valores
                            axisTrackStyle: LinearAxisTrackStyle(
                              thickness: 5, // Ancho de la línea del eje
                              color: Colors.grey[300], // Color de la línea
                            ),
                            markerPointers: [
                              LinearShapePointer(
                                value: targetTemperature!.toDouble(),
                                onChanged: _updateTargetValue,
                                onChangeEnd: (value) async {
                                  await addTemperature(toggleValue, minimalTemperature!.toInt(), value.toInt());
                                },
                                shapeType: LinearShapePointerType.invertedTriangle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SizedBox(
                  height: 10,
                ),
                Divider(
                  thickness: 5,
                  height: 10,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  'ui.label.firmware'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [const SizedBox(width: 20), Text('Current version: $firmwareVersion')],
                ),
                Row(
                  children: [const SizedBox(width: 20), Text('RemoteId: ${widget.device!.remoteId}')],
                ),
                /*if (firmwareTask != TaskStatus.running || firmwareTask != TaskStatus.complete) ...[
                  Row(
                    children: [
                      Center(
                        child: TextButton.icon(
                            icon: const Icon(Icons.autorenew),
                            onPressed: () async {
                              await _searchFirmwareUpdates();
                            },
                            label: const Text('Get updates!')),
                      )
                    ],
                  ),
                ],*/
                if (firmwareData.isNotEmpty && firmwareData.containsKey('version'))
                  if (firmwareData['version'] != firmwareVersion)
                    Row(
                      children: [
                        Center(
                          child: TextButton.icon(
                            icon: _buildTaskStatusIcon(context, firmwareTask),
                            onPressed: () async {
                              if (firmwareTask == TaskStatus.complete || firmwareTask == TaskStatus.running) {
                                return;
                              } else {
                                await _downloadFirmware();
                              }
                            },
                            label: (firmwareTask == TaskStatus.running)
                                ? Text('Download progress: ${(_downloadProgress * 100).toStringAsFixed(2)}% ')
                                : (firmwareTask == TaskStatus.complete)
                                    ? Text('Firmware ready! (v${firmwareData['version']})')
                                    : Text('Download update (v${firmwareData['version']})'),
                          ),
                        ),
                      ],
                    ),
                if (firmwareTask == TaskStatus.complete) ...[
                  Row(
                    children: [
                      Center(
                        child: TextButton.icon(
                            icon: const Icon(Icons.system_update),
                            onPressed: () async {
                              await updateFirmware();
                            },
                            label: Text('Update eAquaSaver device!')),
                      )
                    ],
                  ),
                ],
              ],
            ),
          );
        } else if (state is ConnectivityOffline) {
          return const Disconnected();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
