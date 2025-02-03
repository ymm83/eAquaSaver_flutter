part of 'location_bloc.dart';

@immutable
abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoadInProgress extends LocationState {}

class LocationLoadSuccess extends LocationState {
  final LatLng latLng;

  LocationLoadSuccess({required this.latLng});
}

class LocationLoadFailure extends LocationState {}
