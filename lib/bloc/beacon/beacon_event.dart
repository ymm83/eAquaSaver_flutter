part of 'beacon_bloc.dart';

@immutable
abstract class BeaconEvent {}

class ListenBeacon extends BeaconEvent {
  final Map<String, dynamic> beaconData;
  ListenBeacon({required this.beaconData});
}

class ClearBeacon extends BeaconEvent {}

class FakeData extends BeaconEvent {}

class RefreshData extends BeaconEvent {}

class StartScan extends BeaconEvent {}

class StopScan extends BeaconEvent {}
