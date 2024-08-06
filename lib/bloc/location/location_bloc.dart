import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;
  late StreamSubscription<Position> _positionSubscription;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  LocationBloc() : super(LocationInitial()) {
    on<LocationStarted>(_onLocationStarted);
    on<LocationChanged>(_onLocationChanged);
  }

  void _onLocationStarted(LocationStarted event, Emitter<LocationState> emit) async {
    emit(LocationLoadInProgress());
    try {
      bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(LocationLoadFailure());
        return;
      }

      LocationPermission permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(LocationLoadFailure());
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(LocationLoadFailure());
        return;
      }

      _positionSubscription = _geolocator.getPositionStream().listen((Position position) {
        add(LocationChanged(position: position));
        _storage.write(key: 'storageLocation', value: jsonEncode(position));
      });
    } catch (_) {
      emit(LocationLoadFailure());
    }
  }

  void _onLocationChanged(LocationChanged event, Emitter<LocationState> emit) {
    emit(LocationLoadSuccess(position: event.position));
  }

  @override
  Future<void> close() {
    _positionSubscription.cancel();
    return super.close();
  }
}
