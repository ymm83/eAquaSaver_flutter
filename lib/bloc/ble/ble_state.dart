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
  //final String? role;

  const BleConnected(this.device, ); //{this.role}

  @override
  bool get showDetails => true;

  @override
  List<Object> get props =>  [device]; //role != null ? [device, role!] :
}

class BleDisconnected extends BleState {
  @override
  bool get showDetails => false;
}

class BleDetailsOpen extends BleState {
  //final String? role;

  const BleDetailsOpen(); //[this.role]

  @override
  bool get showDetails => true;

  //@override
  //List<Object> get props => role != null ? [role!] : [];
}

class BleDetailsClose extends BleState {
  @override
  bool get showDetails => false;
}
