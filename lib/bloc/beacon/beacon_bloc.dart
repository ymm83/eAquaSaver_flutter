import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../protoc/eaquasaver_msg.pb.dart';

part 'beacon_state.dart';
part 'beacon_event.dart';

class BeaconBloc extends Bloc<BeaconEvent, BeaconState> {
  late StreamSubscription<List<ScanResult>> _beaconSubscription;
  late Map<String, dynamic> _beaconData = {};
  late Timer _scanTimer;
  late Timer _fakeTimer;

  BeaconBloc() : super(BeaconState()) {
    on<ListenBeacon>((event, emit) => emit(state.copyWith(remoteId: event.remoteId)));
    on<ClearBeacon>((event, emit) async {
      emit(state.copyWith(remoteId: ''));
      _scanTimer.cancel();
      _fakeTimer.cancel();
      _beaconSubscription.cancel();
    });
    on<RefreshData>(_onRefreshData);
    on<StartScan>(_onStartScan);
    on<StopScan>(_stopBeaconScanning);
    on<FakeData>(_onRandomFake);
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<BeaconState> emit) async {
    /* _scanTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _onStartScan(StartScan(), emit); // Asegúrate de pasar el evento correcto aquí
    });*/
  }

  Future<void> _startBeaconScanning(StartScan event, Emitter<BeaconState> emit) async {
    debugPrint('------------GENERANDO DATOS FAKE---------------');
    var beaconData = {
      'fake': true,
      'temperature': Random().nextInt(10) + 20,
      'hotTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)) + 25,
      'coldTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)),
      'currentHotUsed': Random().nextInt(30) + 20,
      'currentRecovered': Random().nextInt(19) + 1,
      'totalColdUsed': Random().nextInt(500) + 10000,
      'totalRecovered': Random().nextInt(500) + 10000,
      'totalHotUsed': Random().nextInt(500) + 10000,
    };
    if (!emit.isDone) {
      emit(BeaconLoaded(beaconData));
    }
  }

  Map<String, dynamic> fakeManufacturerData() {
    var beaconData = {
      'fake': true,
      'temperature': double.parse((Random().nextDouble() * 10).toStringAsPrecision(2)) + 15,
      'hotTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)) + 25,
      'coldTemperature': double.parse((Random().nextDouble() * 25).toStringAsPrecision(2)),
      'currentHotUsed': Random().nextInt(30) + 20,
      'currentRecovered': Random().nextInt(19) + 1,
      'totalColdUsed': Random().nextInt(500) + 10000,
      'totalRecovered': Random().nextInt(500) + 10000,
      'totalHotUsed': Random().nextInt(500) + 10000,
    };
    return beaconData;
  }

  Map<String, dynamic> _decodeManufacturerData(List<int> data, Emitter<BeaconState> emit) {
    if (data.isEmpty) {
      emit(BeaconError('Error: Los datos están vacíos.'));
      return {};
    }
    try {
      int size = data[0]; // Tamaño del mensaje
      var protobufData = data.sublist(1, size + 1); // decodedMessage
      eAquaSaverMessage decodedMessage = eAquaSaverMessage.fromBuffer(protobufData);
      _beaconData = {
        'temperature': decodedMessage.temperature,
        'hotTemperature': decodedMessage.hotTemperature / 10.0,
        'coldTemperature': decodedMessage.coldTemperature / 10.0,
        'currentHotUsed': decodedMessage.currentHotUsed,
        'currentRecovered': decodedMessage.currentRecovered,
        'totalColdUsed': decodedMessage.totalColdUsed,
        'totalRecovered': decodedMessage.totalRecovered,
        'totalHotUsed': decodedMessage.totalHotUsed,
      };
      return _beaconData;
    } catch (e) {
      emit(BeaconError('Error al decodificar los datos: $e'));
      return {};
    }
  }

  Future<void> _stopBeaconScanning(StopScan event, Emitter<BeaconState> emit) async {
    await FlutterBluePlus.stopScan();
    _beaconSubscription.cancel();
    _scanTimer.cancel();
    _beaconData.clear();
  }

  void _onRandomFake(event, Emitter<BeaconState> emit) {
    //_fakeTimer = Timer.periodic(Duration(seconds: 3), (timer) {
    emit(BeaconLoaded(fakeManufacturerData()));
    // debugPrint('----------- _onRandomFake : {data.toString()}');
    //});
  }

  Future<void> _onStartScan(StartScan event, Emitter<BeaconState> emit) async {
    final String remoteId = state.remoteId;
    _scanTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
      );
      debugPrint('----------- _onStartScan>remoteId:${remoteId}'); // q

      _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.advertisementData.advName == 'eAquaS Beacon') {
            debugPrint('----------- _onStartScan > onScanResults:${r.toString()}'); // q
            if (r.device.remoteId.toString().isNotEmpty) {
              if (r.advertisementData.manufacturerData.isNotEmpty) {
                for (var value in r.advertisementData.manufacturerData.values) {
                  final decodedData = _decodeManufacturerData(value, emit);
                  debugPrint('-------rrrrrrrrrrrrrrrr:${decodedData.toString()}');

                  if (!emit.isDone) {
                    emit(BeaconLoaded(decodedData));
                  }
                }
              } else {
                if (!emit.isDone) {
                  emit(BeaconError('No hay datos disponibles.'));
                }
              }
            }
          } else {
            continue;
          }
        }
      });
    });
  }

  // Future<void> _onStartScan(StartScan event, Emitter<BeaconState> emit) async {
  //   //emit(BeaconLoading());
  //   await FlutterBluePlus.startScan(
  //     //withNames: ['eAquaS Beacon'],
  //     //withRemoteIds:  [state.remoteId],
  //     timeout: const Duration(seconds: 3),
  //   );
  //   debugPrint('----------- _onStartScan  -  state.remoteId:${state.remoteId}');
  //   _beaconSubscription = FlutterBluePlus.onScanResults.listen((results) {
  //     ScanResult r = results.firstWhere((r) => r.advertisementData.advName == 'eAquaS Beacon');
  //     //for (ScanResult r in results) {
  //     debugPrint('----------- _onStartScan > onScanResults:${r.device.toString()}');
  //     if (r.advertisementData.manufacturerData.isNotEmpty) {
  //       r.advertisementData.manufacturerData.forEach((key, value) {
  //         if (emit.isDone) emit(BeaconLoaded(_decodeManufacturerData(value, emit)));
  //         debugPrint('-------rrrrrrrrrrrrrrrr:${_decodeManufacturerData(value, emit).toString()}');
  //         //return;
  //       });
  //     } else {
  //       emit(BeaconError('No hay datos de fabricante disponibles.'));
  //     }
  //     //}
  //   });
  // }

  Future<void> _onStopScan(StopScan event, Emitter<BeaconState> emit) async {
    //_stopBeaconScanning();
    if (!emit.isDone) {
      emit(BeaconState());
    } // Emitir estado inicial o cualquier otro estado relevante
  }
}
