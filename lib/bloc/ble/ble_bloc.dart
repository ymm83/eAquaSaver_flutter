import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

part 'ble_event.dart';
part 'ble_state.dart';

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
