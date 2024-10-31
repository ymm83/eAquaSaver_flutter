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
  //final String? role;
  const DetailsOpen();
  /*const DetailsOpen([this.role]);

  @override
  List<Object> get props => role != null ? [role!] : [];*/
}

class DetailsClose extends BleEvent {
  const DetailsClose();
}
