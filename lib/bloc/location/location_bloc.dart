import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;
  late StreamSubscription<Position> _positionSubscription;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LocationBloc() : super(LocationInitial()) {
    on<LocationStarted>(_onLocationStarted);
    on<LocationChanged>(_onLocationChanged);
  }

  void _onLocationStarted(LocationStarted event, Emitter<LocationState> emit) async {
    emit(LocationLoadInProgress());
    final cache = await _storage.readAll();
   // debugPrint('--- cache loction: $cache');
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
        add(LocationChanged(latLng: LatLng(position.latitude, position.longitude)));
        _storage.write(key: 'storageLocation', value: jsonEncode(LatLng(position.latitude, position.longitude)));
      });
    } catch (_) {
      emit(LocationLoadFailure());
    }
  }

  void _onLocationChanged(LocationChanged event, Emitter<LocationState> emit) {
    emit(LocationLoadSuccess(latLng: event.latLng));
  }

  @override
  Future<void> close() {
    _positionSubscription.cancel();
    return super.close();
  }
}
