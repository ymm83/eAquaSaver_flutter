import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;

  ConnectivityBloc(this._connectivity) : super(ConnectivityInitial()) {
    _connectivity.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged(isConnected: result[0] != ConnectivityResult.none));
    });

    on<ConnectivityChanged>((event, emit) {
      if (event.isConnected) {
        emit(ConnectivityOnline());
      } else {
        emit(ConnectivityOffline());
      }
    });
  }
}
