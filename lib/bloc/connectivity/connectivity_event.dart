part of 'connectivity_bloc.dart';

@immutable
abstract class ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isConnected;

  ConnectivityChanged({required this.isConnected});
}
