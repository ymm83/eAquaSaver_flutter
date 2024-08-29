part of 'beacon_bloc.dart';

@immutable
abstract class BeaconEvent {}

class ListenBeacon extends BeaconEvent {
  final String? remoteId;
  ListenBeacon({this.remoteId});
}

class ClearBeacon extends BeaconEvent {}

class FakeData extends BeaconEvent {}

class RefreshData extends BeaconEvent {}

class StartScan extends BeaconEvent {}

class StopScan extends BeaconEvent {}
