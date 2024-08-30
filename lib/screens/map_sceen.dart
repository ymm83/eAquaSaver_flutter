import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart'; // Importa el paquete
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/tile_providers.dart';
import '../bloc/location/location_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static final MapController _mapController = MapController();

  static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  static const _dublin = LatLng(53.3498, -6.2603);

  List<DragMarker> _markers = [];

  bool hasInternet = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<ServiceStatus> _serviceStatusStream;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  LatLng _locationData = const LatLng(0, 0);

  // Variables para el diálogo
  int _selectedOption = 3;
  bool _isLocationAvailable = false; // Para verificar si hay ubicación almacenada
  late bool _isGpsEnabled; // Simulación del estado del GPS
  bool _dialogShown = false; // Controla si el diálogo ya ha sido mostrado
  Timer? _dialogTimer; // Timer para el diálogo

  @override
  void initState() {
    _fetchStorageLocation();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) => _updateGPSStatus(status));
    _updateGPSStatus;
    _gpsEnabled().then((gpsState) {
      _isGpsEnabled = gpsState;
    });
    BlocProvider.of<LocationBloc>(context).add(LocationStarted());
    // Inicializa los marcadores
    _markers = [
      DragMarker(
        point: _london,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.blue,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          debugPrint('_london marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _dublin,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.green,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          debugPrint('_dublin marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _paris,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.red,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          debugPrint('_paris marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _locationData,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: const Color.fromARGB(255, 4, 177, 47),
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          debugPrint('_locationData marker moved to: $newPosition');
        },
      ),
    ];
    super.initState();
  }

  @override
  void dispose() {
    _serviceStatusStream.cancel();
    _connectivitySubscription.cancel();
    _dialogTimer?.cancel(); // Cancela el timer si existe
    super.dispose();
  }

  Future<void> _fetchStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data != null) {
      final jsondata = jsonDecode(data);
      _locationData = LatLng(jsondata['latitude'], jsondata['longitude']);
      setState(() {
        _isLocationAvailable = true; // Hay ubicación almacenada
      });
    }
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
    setState(() {
      _connectionStatus = result;
    });
    debugPrint('Connectivity changed: $_connectionStatus');
  }

  void _updateGPSStatus(ServiceStatus status) {
    //final bool isEnabled = status == ServiceStatus.enabled;
    debugPrint('-------------status: $status');
    _isGpsEnabled = (status == ServiceStatus.enabled) ? true : false;
    setState(() {});
  }

  Future<bool> _gpsEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      return true;
    }
    //_isGpsEnabled = serviceEnabled;
    //setState(() {});
    return false;
  }

  // Método para mostrar el diálogo
  void _showLocationDialog() {
    if (_dialogShown) return; // Evita mostrar el diálogo si ya se mostró

    _dialogShown = true; // Marca el diálogo como mostrado

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Center(
                child: Text(
                  'Select Location Method',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: _selectedOption,
                        onChanged: _isLocationAvailable
                            ? (int? value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedOption = value!;
                                  });
                                }
                              }
                            : null,
                      ),
                      _isLocationAvailable
                          ? const Text('Use last position')
                          : const Text('Use last position', style: TextStyle(decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 2,
                        groupValue: _selectedOption,
                        onChanged: _isGpsEnabled
                            ? (int? value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedOption = value!;
                                  });
                                }
                              }
                            : null,
                      ),
                      _isGpsEnabled
                          ? const Text('Use automatic position')
                          : const Text('Use automatic position',
                              style: TextStyle(decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 3,
                        groupValue: _selectedOption,
                        onChanged: (int? value) {
                          if (mounted) {
                            setState(() {
                              _selectedOption = value!;
                            });
                          }
                        },
                      ),
                      const Text('Manual position'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _dialogShown = false; // Reinicia el estado del diálogo al cerrarlo
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    // Usar un Timer para mostrar el diálogo después de un retraso

    if (mounted) {
      _showLocationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Llama al diálogo después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationDialog();
    });

    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          LatLng initialPosition = _paris;

          if (state is LocationInitial) {
            return const Center(child: Text('Fetching Location'));
          } else if (state is LocationLoadSuccess) {
            initialPosition = LatLng(state.position.latitude, state.position.longitude);
            _locationData = initialPosition;
          } else if (state is LocationLoadFailure) {
            //return const Center(child: Text('Failed to fetch location'));
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.gps_fixed),
                      label: const Text(' Select method'),
                      onPressed: _showLocationDialog,
                    ),
                  ],
                ),
                Flexible(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialPosition,
                      initialZoom: 5,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      openStreetMapTileLayer,
                      DragMarkers(
                        markers: _markers,
                        alignment: Alignment.topCenter,
                      ),
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

















/*import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart'; // Importa el paquete
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
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

  static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  static const _dublin = LatLng(53.3498, -6.2603);

  List<DragMarker> _markers = [];

  bool hasInternet = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<ServiceStatus> _serviceStatusStream;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  LatLng _locationData = const LatLng(0, 0);

  // Variables para el diálogo
  int _selectedOption = 3;
  bool _isLocationAvailable = false; // Para verificar si hay ubicación almacenada
  bool _isGpsEnabled = false; // Simulación del estado del GPS
  bool _dialogShown = false; // Controla si el diálogo ya ha sido mostrado

  @override
  void initState() {
    super.initState();
    _fetchStorageLocation();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen(_updateGPSStatus);
    BlocProvider.of<LocationBloc>(context).add(LocationStarted());
    // Inicializa los marcadores
    _markers = [
      DragMarker(
        point: _london,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.blue,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          print('_london marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _dublin,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.green,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          print('_dublin marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _paris,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.red,
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          print('_paris marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _locationData,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Color.fromARGB(255, 4, 177, 47),
          size: isDragging ? 50 : 40,
        ),
        size: const Size(40, 40),
        onLongDragEnd: (details, newPosition) {
          print('_locationData marker moved to: $newPosition');
        },
      ),
    ];
  }

  @override
  void dispose() {
    _serviceStatusStream.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data != null) {
      final jsondata = jsonDecode(data);
      _locationData = LatLng(jsondata['latitude'], jsondata['longitude']);
      setState(() {
        _isLocationAvailable = true; // Hay ubicación almacenada
      });
    }
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
    setState(() {
      _connectionStatus = result;
    });
    debugPrint('Connectivity changed: $_connectionStatus');
  }

  Future<void> _updateGPSStatus(ServiceStatus status) async {
    final bool isEnabled = status == ServiceStatus.enabled;
    debugPrint('-------------status: $status');
    setState(() {
      _isGpsEnabled = isEnabled;
    });
  }

  // Método para mostrar el diálogo
  void _showLocationDialog() {
    if (_dialogShown) return; // Evita mostrar el diálogo si ya se mostró

    _dialogShown = true; // Marca el diálogo como mostrado

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Center(
                child: Text(
                  'Select Location Method',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: _selectedOption,
                        onChanged: _isLocationAvailable
                            ? (int? value) {
                                setState(() {
                                  _selectedOption = value!;
                                });
                              }
                            : null,
                      ),
                      _isLocationAvailable
                          ? const Text('Use last position')
                          : const Text('Use last position', style: TextStyle(decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 2,
                        groupValue: _selectedOption,
                        onChanged: _isGpsEnabled
                            ? (int? value) {
                                setState(() {
                                  _selectedOption = value!;
                                });
                              }
                            : null,
                      ),
                      _isGpsEnabled
                          ? const Text('Use automatic position')
                          : const Text('Use automatic position',
                              style: TextStyle(decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 3,
                        groupValue: _selectedOption,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                      const Text('Manual position'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _dialogShown = false; // Reinicia el estado del diálogo al cerrarlo
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Llama al diálogo después de que el widget esté construido
    Future.delayed(Duration(seconds: 2), () {
      _showLocationDialog();
    });
    /*WidgetsBinding.instance..addPostFrameCallback((_) {
       // Muestra el diálogo al entrar en la pantalla
    });*/

    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          LatLng initialPosition = _paris;

          if (state is LocationInitial) {
            return const Center(child: Text('Fetching Location'));
          } else if (state is LocationLoadSuccess) {
            initialPosition = LatLng(state.position.latitude, state.position.longitude);
            _locationData = initialPosition;
          } else if (state is LocationLoadFailure) {
            return const Center(child: Text('Failed to fetch location'));
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.gps_fixed),
                      label: Text(' Select method'),
                      onPressed: _showLocationDialog,
                    ),
                  ],
                ),
                Flexible(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialPosition,
                      initialZoom: 5,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      openStreetMapTileLayer,
                      DragMarkers(
                        markers: _markers,
                        alignment: Alignment.topCenter,
                      ),
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
*/






/*import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart'; // Importa el paquete
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  List<DragMarker> _markers = []; // Cambia a una lista de DragMarker

  bool hasInternet = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  LatLng _locationData = const LatLng(0, 0);

  @override
  void initState() {
    _fetchStorageLocation();
    BlocProvider.of<LocationBloc>(context).add(LocationStarted());
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Inicializa los marcadores
    _markers = [
      DragMarker(
        point: _london,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.blue,
          size: isDragging ? 50 : 40, // Cambia el tamaño si está siendo arrastrado
        ),
        size: const Size(40, 40), // Agrega el tamaño del marcador
        onLongDragEnd: (details, newPosition) {
          print('_london marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _dublin,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.green,
          size: isDragging ? 50 : 40, // Cambia el tamaño si está siendo arrastrado
        ),
        size: const Size(40, 40), // Agrega el tamaño del marcador
        onLongDragEnd: (details, newPosition) {
          print('_dublin marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _paris,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.red,
          size: isDragging ? 50 : 40, // Cambia el tamaño si está siendo arrastrado
        ),
        size: const Size(40, 40), // Agrega el tamaño del marcador
        onLongDragEnd: (details, newPosition) {
          print('_paris marker moved to: $newPosition');
        },
      ),
      DragMarker(
        point: _locationData,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Color.fromARGB(255, 4, 177, 47),
          size: isDragging ? 50 : 40, // Cambia el tamaño si está siendo arrastrado
        ),
        size: const Size(40, 40), // Agrega el tamaño del marcador
        onLongDragEnd: (details, newPosition) {
          print('_locationData marker moved to: $newPosition');
        },
      ),
    ];
    super.initState();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    //debugPrint('dataaaaaaaaaa: $data');
    if (data != null) {
      final jsondata = jsonDecode(data);
      _locationData = LatLng(jsondata['latitude'], jsondata['longitude']);
    }
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
    setState(() {
      _connectionStatus = result;
    });
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
            _locationData = initialPosition;
          } else if (state is LocationLoadFailure) {
            return const Center(child: Text('Failed to fetch location'));
          }

          /* if (state is LocationLoadSuccess) {
            setState(() {
              _locationData = initialPosition;
            });
          }*/

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
                    ),
                    children: [
                      openStreetMapTileLayer,

                      DragMarkers(
                        markers: _markers,
                        alignment: Alignment.topCenter,
                      ), // Agrega los marcadores directamente
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
*/




/*import 'dart:async';

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
  bool hasInternet = true;
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
*/