// ble_event.dart
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
  final BluetoothDevice device;

  const DisconnectFromDevice(this.device);

  @override
  List<Object> get props => [device];
}

class DetailsOpen extends BleEvent {}

class DetailsClose extends BleEvent {}

class UpdateConnectionState extends BleEvent {
  final BluetoothConnectionState state;
  final BluetoothDevice device;

  const UpdateConnectionState(this.state, this.device);

  @override
  List<Object> get props => [state, device];
}

class ClearFoundDevices extends BleEvent {}

class DeviceConnected extends BleEvent {
  final BluetoothDevice device;
  const DeviceConnected(this.device);
  @override
  List<Object> get props => [device];
}

class DeviceDisconnected extends BleEvent {
  final BluetoothDevice device;
  const DeviceDisconnected(this.device);
  @override
  List<Object> get props => [device];
}