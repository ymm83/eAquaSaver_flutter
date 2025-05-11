// ble_state.dart
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
final List<ScanResult> results;

  const BleScanResults(this.results);

  @override
  List<Object> get props => [results];
}

class BleConnecting extends BleState {
  final BluetoothDevice device;

  const BleConnecting(this.device);

  @override
  List<Object> get props => [device];
}

class BleConnected extends BleState {
  final BluetoothDevice device;
  @override
  final bool showDetails;

  const BleConnected({
    required this.device,
    this.showDetails = false,
  });

  @override
  List<Object> get props => [device, showDetails];
}

class BleDisconnected extends BleState {}

class BleScanError extends BleState {
  final String message;

  const BleScanError(this.message);

  @override
  List<Object> get props => [message];
}

class BleConnectionError extends BleState {
  final String message;

  const BleConnectionError(this.message);

  @override
  List<Object> get props => [message];
}