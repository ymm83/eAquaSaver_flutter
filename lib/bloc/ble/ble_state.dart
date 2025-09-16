part of 'ble_bloc.dart';
abstract class BleState extends Equatable {
  const BleState();
  bool get showDetails => false;
  @override
  List<Object> get props => [];
}

class BleInitial extends BleState {}

class BleScanning extends BleState {}

class BleScanResults extends BleState {
  final List<BluetoothDevice> devices;

  const BleScanResults(this.devices);

  @override
  List<Object> get props => [devices];
}

// Estado para indicar que un dispositivo se está conectando
class BleConnecting extends BleState {
  final BluetoothDevice device;

  const BleConnecting(this.device);

  @override
  List<Object> get props => [device];
}

class BleConnected extends BleState {
  final BluetoothDevice device;

  const BleConnected(this.device);

  @override
  bool get showDetails => true;

  @override
  List<Object> get props => [device];
}

class BleConnectionFailed extends BleState {
  final String error;

  const BleConnectionFailed({required this.error});

  @override
  List<Object> get props => [error];
}

class BleDisconnected extends BleState {
  final BluetoothDevice device;

  const BleDisconnected(this.device);

  @override
  List<Object> get props => [device];

  @override
  bool get showDetails => false;
}

class BleDetailsOpen extends BleState {
  const BleDetailsOpen();

  @override
  bool get showDetails => true;
}

class BleDetailsClose extends BleState {
  @override
  bool get showDetails => false;
}

/*
part of 'ble_bloc.dart';

abstract class BleState extends Equatable {
  const BleState();
  bool get showDetails => false;
  @override
  List<Object> get props => [];
}

class BleInitial extends BleState {}

class BleScanning extends BleState {}

class BleScanResults extends BleState {
  final List<BluetoothDevice> devices;

  const BleScanResults(this.devices);

  @override
  List<Object> get props => [devices];
}

class BleConnected extends BleState {
  final BluetoothDevice device;

  const BleConnected(this.device, );

  @override
  bool get showDetails => true;

  @override
  List<Object> get props =>  [device];
}

class BleDisconnected extends BleState {
  @override
  bool get showDetails => false;
}

class BleDetailsOpen extends BleState {

  const BleDetailsOpen();

  @override
  bool get showDetails => true;
}

class BleDetailsClose extends BleState {
  @override
  bool get showDetails => false;
}

*/