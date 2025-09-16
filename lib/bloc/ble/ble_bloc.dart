import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

part 'ble_event.dart';
part 'ble_state.dart';

class BleBloc extends Bloc<BleEvent, BleState> {
  BleBloc() : super(BleInitial()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectFromDevice>(_onDisconnectFromDevice);
    on<DetailsOpen>(_onDetailsOpen);
    on<DetailsClose>(_onDetailsClose);
  }

  void _onStartScan(StartScan event, Emitter<BleState> emit) async {
    // Si ya estamos escaneando, no hacemos nada.
    if (state is BleScanning) {
      return;
    }

    // Emite el estado de escaneo para mostrar una interfaz de usuario de carga.
    emit(BleScanning());
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Escucha los resultados del escaneo para actualizar la lista de dispositivos.
    FlutterBluePlus.scanResults.listen((results) {
      List<BluetoothDevice> devices = results.map((r) => r.device).toList();
      emit(BleScanResults(devices));
    });
  }

  void _onStopScan(StopScan event, Emitter<BleState> emit) {
    FlutterBluePlus.stopScan();
    emit(BleInitial());
  }

  void _onConnectToDevice(ConnectToDevice event, Emitter<BleState> emit) async {
    try {
      // Emite el estado `BleConnecting` para el dispositivo específico.
      emit(BleConnecting(event.device));

      // Detiene cualquier escaneo en curso antes de intentar la conexión.
      await FlutterBluePlus.stopScan();

      // Intenta conectar al dispositivo.
      await event.device.connect();

      // Si la conexión es exitosa, emite el estado `BleConnected` para el dispositivo.
      emit(BleConnected(event.device));
    } catch (e) {
      // Si ocurre un error, emite un estado de error específico.
      emit(BleConnectionFailed(error: e.toString()));
    }
  }

  void _onDisconnectFromDevice(
      DisconnectFromDevice event, Emitter<BleState> emit) async {
    try {
      // Intenta desconectar el dispositivo especificado en el evento.
      await event.device.disconnect();
      // Emite el estado de desconectado después de la desconexión.
      emit(BleDisconnected(event.device));
    } catch (e) {
      // Maneja errores de desconexión.
      emit(BleConnectionFailed(error: "Error al desconectar: ${e.toString()}"));
    }
  }

  void _onDetailsOpen(DetailsOpen event, Emitter<BleState> emit) async {
    emit(BleDetailsOpen());
  }

  void _onDetailsClose(DetailsClose event, Emitter<BleState> emit) async {
    emit(BleDetailsClose());
  }
}


/*
class BleBloc extends Bloc<BleEvent, BleState> {
  late FlutterBluePlus flutterBlue;
  BluetoothDevice? connectedDevice;

  BleBloc(this.flutterBlue) : super(BleInitial()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectFromDevice>(_onDisconnectFromDevice);
    on<DetailsOpen>(_onDetailsOpen);
    on<DetailsClose>(_onDetailsClose);
  }

  void _onStartScan(StartScan event, Emitter<BleState> emit) async {
    emit(BleScanning());
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    FlutterBluePlus.scanResults.listen((results) {
      List<BluetoothDevice> devices = results.map((r) => r.device).toList();
      emit(BleScanResults(devices));
    });
  }

  void _onStopScan(StopScan event, Emitter<BleState> emit) {
    FlutterBluePlus.stopScan();
    emit(BleInitial());
  }

  void _onConnectToDevice(ConnectToDevice event, Emitter<BleState> emit) async {
    try {
      await FlutterBluePlus.stopScan();
      await event.device.connect();
      connectedDevice = event.device;
      emit(BleConnected(event.device));
    } catch (e) {
      emit(BleInitial());
    }
  }

  void _onDisconnectFromDevice(DisconnectFromDevice event, Emitter<BleState> emit) async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      emit(BleDisconnected());
    }
  }
}


void _onDetailsOpen(DetailsOpen event, Emitter<BleState> emit) async {
  emit(BleDetailsOpen());//event.role
}

void _onDetailsClose(DetailsClose event, Emitter<BleState> emit) async {
  emit(BleDetailsClose());
}
*/
