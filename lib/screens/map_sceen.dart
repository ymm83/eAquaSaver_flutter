import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/tile_providers.dart';
import '../bloc/location/location_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static final MapController _mapController = MapController();
  double _rotation = 0;

  static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  static const _dublin = LatLng(53.3498, -6.2603);

  static const _markers = [
    Marker(
      width: 80,
      height: 80,
      point: _london,
      child: Icon(
        Icons.location_on,
        color: Colors.blue,
      ),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _dublin,
      child: Icon(
        Icons.location_on,
        color: Colors.green,
      ),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _paris,
      child: Icon(
        Icons.location_on,
        color: Colors.red,
      ),
    ),
  ];
  bool _hasInternet = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<LocationBloc>(context).add(LocationStarted());
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (_) {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() { _connectionStatus = result; });
    debugPrint('Connectivity changed: $_connectionStatus');
  }



  void _reloadMap() {
    setState(() {
      // Puedes agregar lógica adicional aquí si es necesario
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          LatLng initialPosition = _paris;

          if (state is LocationInitial) {
            return const Center(child: Text('Fetching Location'));
          } else if (state is LocationLoadSuccess) {
            initialPosition = LatLng(state.position.latitude, state.position.longitude);
            //_mapController.move(initialPosition, 15);
          } else if (state is LocationLoadFailure) {
            return const Center(child: Text('Failed to fetch location'));
          }

          List<Marker> markers = List.from(_markers);
          if (state is LocationLoadSuccess) {
            markers.add(
              Marker(
                width: 80,
                height: 80,
                point: initialPosition,
                child: const Icon(Icons.my_location, color: Colors.purple, size: 80),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      MaterialButton(
                        onPressed: () => _mapController.move(_london, 18),
                        child: const Text('London'),
                      ),
                      MaterialButton(
                        onPressed: () => _mapController.move(_paris, 5),
                        child: const Text('Paris'),
                      ),
                      MaterialButton(
                        onPressed: () => _mapController.move(_dublin, 5),
                        child: const Text('Dublin'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      MaterialButton(
                        onPressed: () {
                          final bounds = LatLngBounds.fromPoints([
                            _dublin,
                            _paris,
                            _london,
                          ]);

                          _mapController.fitCamera(
                            CameraFit.bounds(
                              bounds: bounds,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                          );
                        },
                        child: const Text('Fit Bounds'),
                      ),
                      Builder(builder: (context) {
                        return MaterialButton(
                          onPressed: () {
                            final bounds = _mapController.camera.visibleBounds;

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Map bounds: \n'
                                'E: ${bounds.east} \n'
                                'N: ${bounds.north} \n'
                                'W: ${bounds.west} \n'
                                'S: ${bounds.south}',
                              ),
                            ));
                          },
                          child: const Text('Get Bounds'),
                        );
                      }),
                      const Text('Rotation:'),
                      Expanded(
                        child: Slider(
                          value: _rotation,
                          min: 0,
                          max: 360,
                          onChanged: (degree) {
                            setState(() {
                              _rotation = degree;
                            });
                            _mapController.rotate(degree);
                          },
                        ),
                      )
                    ],
                  ),
                ),
                Flexible(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialPosition,
                      initialZoom: 5,
                      maxZoom: 18,
                      minZoom: 3,
                      //keepAlive:
                    ),
                    children: [
                      openStreetMapTileLayer,
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
