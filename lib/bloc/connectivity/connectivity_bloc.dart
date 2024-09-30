import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;

  ConnectivityBloc(this._connectivity) : super(ConnectivityInitial()) {
    // Verificar el estado de conectividad inicial
    _initializeConnectivity();

    // Escuchar cambios en la conectividad
    _connectivity.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged(isConnected: !result.contains(ConnectivityResult.none)));
    });

    on<ConnectivityChanged>((event, emit) {
      if (event.isConnected) {
        emit(ConnectivityOnline());
      } else {
        emit(ConnectivityOffline());
      }
    });
  }

  void _initializeConnectivity() async {
    // Obtener el estado de conectividad inicial
    final result = await _connectivity.checkConnectivity();
    bool isConnected = !result.contains(ConnectivityResult.none);

    // Debug: Mostrar el estado inicial
    debugPrint('Estado de conectividad inicial: ${isConnected ? "Conectado" : "Desconectado"}');

    add(ConnectivityChanged(isConnected: isConnected));
  }
}
