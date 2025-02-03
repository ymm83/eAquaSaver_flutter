part of 'location_bloc.dart';

@immutable
abstract class LocationEvent {}

class LocationStarted extends LocationEvent {}

class LocationChanged extends LocationEvent {
  final LatLng latLng;

  LocationChanged({required this.latLng});
}
