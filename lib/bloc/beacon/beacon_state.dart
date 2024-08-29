part of 'beacon_bloc.dart';

class BeaconState {
  final String remoteId;
  final Map<String, dynamic> data;

  BeaconState({
    this.remoteId = '0',
    this.data = const {},
  });

  BeaconState copyWith({
    String? remoteId,
    Map<String, dynamic>? data = const {},
  }) =>
      BeaconState(
        remoteId: remoteId ?? this.remoteId,
        data: data ?? this.data,
      );
}

class BeaconLoading extends BeaconState {
  BeaconLoading();
}

class BeaconInitial extends BeaconState {
  BeaconInitial();
}

class BeaconLoaded extends BeaconState {
  final Map<String, dynamic> beaconData;

  BeaconLoaded(this.beaconData);
}

class BeaconError extends BeaconState {
  final String message;

  BeaconError(this.message);
}
