part of 'ble_bloc.dart';
abstract class BleEvent extends Equatable {
  const BleEvent();

  @override
  List<Object> get props => [];
}

class StartScan extends BleEvent {}

class StopScan extends BleEvent {}

class ConnectToDevice extends BleEvent {
  final BluetoothDevice device;

  const ConnectToDevice(this.device);

  @override
  List<Object> get props => [device];
}

class DisconnectFromDevice extends BleEvent {
  const DisconnectFromDevice();
}

class DetailsOpen extends BleEvent {
  const DetailsOpen();
}

class DetailsClose extends BleEvent {
  const DetailsClose();
}