import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

part 'ble_event.dart';
part 'ble_state.dart';

class BleBloc extends Bloc<BleEvent, BleState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  List<BluetoothDevice> _systemDevices = [];
  final List<ScanResult> _foundDevices = [];
  BluetoothDevice? _connectedDevice;

  BleBloc() : super(BleInitial()) {
    FlutterBluePlus.setLogLevel(LogLevel.verbose);

    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectFromDevice>(_onDisconnectFromDevice);
    on<DetailsOpen>(_onDetailsOpen);
    on<DetailsClose>(_onDetailsClose);
    on<UpdateConnectionState>(_onUpdateConnectionState);
    on<ClearFoundDevices>(_onClearFoundDevices);

    _loadSystemDevices();
  }

  List<BluetoothDevice> get systemDevices => List.unmodifiable(_systemDevices);
  List<ScanResult> get foundDevices => List.unmodifiable(_foundDevices);
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> _loadSystemDevices() async {
    try {
      final _systemDevices = await FlutterBluePlus.systemDevices;
      //_systemDevices = devices.where((d) => d.platformName?.startsWith('eASs') ?? false).toList();
    } catch (e, stack) {
      debugPrint('Error loading system devices: $e\n$stack');
      _systemDevices = [];
      add(StopScan());
    }
  }

  /* Future<void> _onStartScan(StartScan event, Emitter<BleState> emit) async {
    try {
      await _scanSubscription?.cancel();
      await _isScanningSubscription?.cancel();
      await _loadSystemDevices(); // Refresco de dispositivos emparejados

      emit(BleScanning());

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _updateFoundDevices(results);
        emit(BleScanResults(_foundDevices));
      });

      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning) emit(BleInitial());
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

    } catch (e, stack) {
      debugPrint('Scan error: $e\n$stack');
      emit(BleScanError('Error al escanear: ${e.toString()}'));
      emit(BleInitial());
    }
  }

  Future<void> _onStopScan(StopScan event, Emitter<BleState> emit) async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      await _isScanningSubscription?.cancel();
      emit(BleInitial());
    } catch (e, stack) {
      debugPrint('Stop scan error: $e\n$stack');
      emit(BleScanError('Error al detener escaneo: ${e.toString()}'));
    }
  }*/

  Future<void> _onStartScan(StartScan event, Emitter<BleState> emit) async {
    // 1. Cancelar cualquier operación previa
    await _cancelSubscriptions();

    // 2. Emitir estado inicial
    emit(BleScanning());

    // 3. Crear un controlador para el stream de resultados
    final resultsController = StreamController<List<ScanResult>>();
    _scanSubscription = resultsController.stream.listen((results) {
      if (!isClosed) {
        final filtered = results.where((r) => r.device.platformName.toString().startsWith('eASs', 0)).toList();
        emit(BleScanResults(filtered));
      }
    });

    // 4. Configurar el stream original
    final originalSubscription = FlutterBluePlus.scanResults.listen(
      (results) => resultsController.add(results),
      onError: (e) => resultsController.addError(e),
    );

    // 5. Configurar listener de estado de escaneo
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isClosed && !isScanning) {
        emit(BleInitial());
      }
    });

    try {
      // 6. Iniciar el escaneo
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      // 7. Esperar a que termine el escaneo
      await Future.delayed(const Duration(seconds: 15));
    } catch (e) {
      if (!isClosed) {
        emit(BleScanError('Error: ${e.toString()}'));
      }
    } finally {
      // 8. Limpieza garantizada
      await originalSubscription.cancel();
      await resultsController.close();
      if (!isClosed) {
        emit(BleInitial());
      }
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _scanSubscription?.cancel();
    await _isScanningSubscription?.cancel();
    _scanSubscription = null;
    _isScanningSubscription = null;
  }
  /*Future<void> _onStartScan(StartScan event, Emitter<BleState> emit) async {
    try {
      // 2. Configurar suscripciones ANTES de iniciar el escaneo

      await _scanSubscription?.cancel();
      await _isScanningSubscription?.cancel();

      // 1. Emitir estado inicial
      emit(BleScanning());

      // 3. Usar una variable local para mantener el estado del emisor
      var isHandlerActive = true;

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!isHandlerActive || isClosed) return;

        // Filtrar y procesar resultados
        final filteredResults = results.where((r) => r.device.platformName.toString().startsWith('eASs', 0)).toList();

        // Emitir nuevos resultados
        emit(BleScanResults(filteredResults));
      });

      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isHandlerActive || isClosed) return;
        if (!isScanning) emit(BleInitial());
      });

      // 4. Iniciar el escaneo
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );

      // 5. Manejar finalización
      Future(() async {
        await Future.delayed(const Duration(seconds: 15)); // Tiempo de escaneo
        if (isHandlerActive && !isClosed) {
          isHandlerActive = false;
          emit(BleInitial());
        }
      });
    } catch (e, stack) {
      if (!isClosed) {
        emit(BleScanError('Error al escanear: ${e.toString()}'));
        emit(BleInitial());
      }
      debugPrint('Scan error: $e\n$stack');
    } finally {
      // 8. Limpieza garantizada
      await _scanSubscription?.cancel();
      await resultsController.close();
      if (!isClosed) {
        emit(BleInitial());
      }
    }
  }*/

  Future<void> _onStopScan(StopScan event, Emitter<BleState> emit) async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      await _isScanningSubscription?.cancel();

      if (!isClosed) {
        emit(BleInitial());
      }
    } catch (e, stack) {
      if (!isClosed) {
        emit(BleScanError('Error al detener escaneo: ${e.toString()}'));
      }
      debugPrint('Stop scan error: $e\n$stack');
    }
  }

  // En tu método _onConnectToDevice
/*Future<void> _onConnectToDevice(ConnectToDevice event, Emitter<BleState> emit) async {
  try {
    // Desconectar dispositivo anterior si existe
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    emit(BleConnecting(event.device));

    // Configurar listener para cambios de estado
    await _connectionSubscription?.cancel();
    _connectionSubscription = event.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _connectedDevice = event.device;
        add(UpdateConnectionState(state, event.device));
      } else if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        add(UpdateConnectionState(state, event.device));
      }
    });

    await event.device.connect(autoConnect: false);
  } catch (e, stack) {
    debugPrint('Connection error: $e\n$stack');
    emit(BleConnectionError('Error al conectar: ${e.toString()}'));
    emit(BleInitial());
  }
}*/

  Future<void> _onConnectToDevice(ConnectToDevice event, Emitter<BleState> emit) async {
    try {
      emit(BleConnecting(event.device));

      // Espera explícitamente por la conexión
      await event.device.connect(autoConnect: false);

      // Verifica el estado inmediatamente después de conectar
      if (event.device.connectionState == BluetoothConnectionState.connected) {
        _connectedDevice = event.device;
        emit(BleConnected(device: event.device));
      }

      // Configura listener para futuros cambios
      _connectionSubscription = event.device.connectionState.listen((state) {
        if (!isClosed) {
          if (state == BluetoothConnectionState.connected) {
            _connectedDevice = event.device;
            add(UpdateConnectionState(state, event.device));
          } else if (state == BluetoothConnectionState.disconnected) {
            _connectedDevice = null;
            add(UpdateConnectionState(state, event.device));
          }
        }
      });
    } catch (e) {
      if (!isClosed) {
        emit(BleConnectionError('Error de conexión: ${e.toString()}'));
      }
    }
  }

  Future<void> _onDisconnectFromDevice(DisconnectFromDevice event, Emitter<BleState> emit) async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        emit(BleDisconnected());
      }
    } catch (e, stack) {
      debugPrint('Disconnection error: $e\n$stack');
      emit(BleConnectionError('Error al desconectar: ${e.toString()}'));
    }
  }

  /*void _onUpdateConnectionState(UpdateConnectionState event, Emitter<BleState> emit) {
    if (event.state == BluetoothConnectionState.disconnected) {
      _connectedDevice = null;
      emit(BleDisconnected());
    } else if (event.state == BluetoothConnectionState.connected) {
      _connectedDevice = event.device;
      // Mantener estado de showDetails del estado anterior
      final showDetails = (state is BleConnected) 
          ? (state as BleConnected).showDetails 
          : false;
      emit(BleConnected(device: event.device, showDetails: showDetails));
    }
  }*/

  void _onUpdateConnectionState(UpdateConnectionState event, Emitter<BleState> emit) {
    if (isClosed) return;

    if (event.state == BluetoothConnectionState.disconnected) {
      _connectedDevice = null;
      emit(BleDisconnected());
    } else if (event.state == BluetoothConnectionState.connected) {
      _connectedDevice = event.device;
      emit(BleConnected(device: event.device));
    }
  }

  void _onDetailsOpen(DetailsOpen event, Emitter<BleState> emit) {
    if (state is BleConnected) {
      emit(BleConnected(
        device: (state as BleConnected).device,
        showDetails: true,
      ));
    }
  }

  void _onDetailsClose(DetailsClose event, Emitter<BleState> emit) {
    if (state is BleConnected) {
      emit(BleConnected(
        device: (state as BleConnected).device,
        showDetails: false,
      ));
    }
  }

  void _onClearFoundDevices(ClearFoundDevices event, Emitter<BleState> emit) {
    _foundDevices.clear();
    emit(BleScanResults(_foundDevices));
  }

  void _updateFoundDevices(List<ScanResult> results) {
    final systemIds = _systemDevices.map((d) => d.remoteId).toSet();

    final newDevices = results
        .where((r) => r.device.platformName?.startsWith('eASs') ?? false)
        .where((r) => !systemIds.contains(r.device.remoteId))
        .map((r) => r.device)
        .toSet();

    //_foundDevices
    //  ..clear()
    //  ..addAll(newDevices.toList());
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
