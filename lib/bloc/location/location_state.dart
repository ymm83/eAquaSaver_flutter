part of 'location_bloc.dart';

@immutable
abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoadInProgress extends LocationState {}

class LocationLoadSuccess extends LocationState {
  final Position position;

  LocationLoadSuccess({required this.position});
}

class LocationLoadFailure extends LocationState {}
