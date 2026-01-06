import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/tile_providers.dart';
import '../bloc/location/location_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static final MapController _mapController = MapController();
  static const LatLng _paris = LatLng(48.8566, 2.3522);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late StreamSubscription<ServiceStatus> _serviceStatusStream;

  LatLng _locationData = _paris;
  List<DragMarker> _markers = [];

  bool _isGpsEnabled = false;
  bool _isLocationAvailable = false;
  bool _dialogShown = false;
  bool _showButtons = false;

  int _selectedOption = 3;

  @override
  void initState() {
    super.initState();

    _initMarkers();
    _loadStorageLocation();

    _serviceStatusStream =
        Geolocator.getServiceStatusStream().listen(_updateGPSStatus);

    _checkGps();

    BlocProvider.of<LocationBloc>(context).add(LocationStarted());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dialogShown) {
        _showLocationDialog();
      }
    });
  }

  @override
  void dispose() {
    _serviceStatusStream.cancel();
    super.dispose();
  }

  // -------------------- INIT --------------------

  void _initMarkers() {
    _markers = [
      DragMarker(
        point: _locationData,
        size: const Size(40, 40),
        builder: (_, __, dragging) => Icon(
          Icons.location_on,
          color: Colors.red,
          size: dragging ? 60 : 40,
        ),
        onDragEnd: (_, latLng) {
          setState(() {
            _locationData = latLng;
            _showButtons = true;
            _rebuildGreenMarker();
          });
        },
      ),
    ];
  }

  void _rebuildGreenMarker() {
    _markers = [
      _markers.first,
      DragMarker(
        point: _locationData,
        size: const Size(40, 40),
        builder: (_, __, dragging) => Icon(
          Icons.location_on,
          color: Colors.green,
          size: dragging ? 55 : 40,
        ),
      ),
    ];
  }

  // -------------------- STORAGE --------------------

  Future<void> _loadStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data == null) return;

    try {
      final Map<String, dynamic> json = jsonDecode(data);
      final lat = (json['latitude'] as num?)?.toDouble();
      final lng = (json['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return;

      if (!mounted) return;

      setState(() {
        _locationData = LatLng(lat, lng);
        _isLocationAvailable = true;
        _rebuildGreenMarker();
      });
    } catch (e) {
      debugPrint('❌ Error al leer storage: $e');
    }
  }

  Future<void> _saveStorageLocation() async {
    final map = {
      'latitude': _locationData.latitude,
      'longitude': _locationData.longitude,
    };

    await _storage.write(
      key: 'storageLocation',
      value: jsonEncode(map),
    );

    debugPrint('✅ Ubicación guardada: $map');
  }

  // -------------------- GPS --------------------

  void _updateGPSStatus(ServiceStatus status) {
    setState(() {
      _isGpsEnabled = status == ServiceStatus.enabled;
    });
  }

  Future<void> _checkGps() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _isGpsEnabled = enabled;
    });
  }

  // -------------------- DIALOG --------------------

  void _showLocationDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

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
  }
    /*showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Center(child: Text('Select Location Method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              value: 1,
              groupValue: _selectedOption,
              onChanged: _isLocationAvailable
                  ? (v) => setState(() => _selectedOption = v!)
                  : null,
              title: const Text('Use last position'),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: _selectedOption,
              onChanged: _isGpsEnabled
                  ? (v) => setState(() => _selectedOption = v!)
                  : null,
              title: const Text('Use automatic position'),
            ),
            RadioListTile<int>(
              value: 3,
              groupValue: _selectedOption,
              onChanged: (v) => setState(() => _selectedOption = v!),
              title: const Text('Manual position'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogShown = false;
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }*/

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (_, state) {
          return Column(
            children: [
              TextButton.icon(
                onPressed: _showLocationDialog,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Select method'),
              ),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _locationData,
                        initialZoom: 5,
                      ),
                      children: [
                        openStreetMapTileLayer,
                        DragMarkers(markers: _markers),
                      ],
                    ),
                    AnimatedPositioned(
                      right: _showButtons ? 10 : -60,
                      bottom: size.height * 0.35,
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        iconSize: 40,
                        onPressed: () async {
                          await _saveStorageLocation();
                          setState(() => _showButtons = false);
                        },
                      ),
                    ),
                    AnimatedPositioned(
                      right: _showButtons ? 10 : -60,
                      bottom: (size.height * 0.35) - 45,
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        icon:
                            const Icon(Icons.cancel, color: Colors.red),
                        iconSize: 40,
                        onPressed: () =>
                            setState(() => _showButtons = false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart'; // Importa el paquete
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/tile_providers.dart';
import '../bloc/location/location_bloc.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static final MapController _mapController = MapController();

  //static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  //static const _dublin = LatLng(53.3498, -6.2603);

  List<DragMarker> _markers = [];

  bool hasInternet = true;

  late StreamSubscription<ServiceStatus> _serviceStatusStream;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  LatLng _locationData = const LatLng(0, 0);

  // Variables para el diálogo
  int _selectedOption = 3;
  bool _isLocationAvailable = false; // Para verificar si hay ubicación almacenada
  late bool _isGpsEnabled; // Simulación del estado del GPS
  bool _dialogShown = false; // Controla si el diálogo ya ha sido mostrado
  Timer? _dialogTimer; // Timer para el diálogo
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _fetchStorageLocation();
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) => _updateGPSStatus(status));
    _gpsEnabled().then((gpsState) {
      _isGpsEnabled = gpsState;
    });
    BlocProvider.of<LocationBloc>(context).add(LocationStarted());

    // Inicializa los marcadores
    _markers = [
      DragMarker(
        point: _paris,
        builder: (context, latLng, isDragging) => Icon(
          Icons.location_on,
          color: Colors.red,
          size: isDragging ? 60 : 40,
        ),
        size: const Size(40, 40),
        onDragStart: (details, latLng) => {
          setState(() {
            _showButtons = false;
          }),
          debugPrint('_paris stop drag marker moved to: $latLng'),
        },
        onDragEnd: (details, latLng) {
          double lat = latLng.latitude;
          double lng = latLng.longitude;

          BlocProvider.of<LocationBloc>(context).add(LocationChanged(latLng: LatLng(lat, lng)));
          _mapController.move(latLng, 5); //zoom adjust
          debugPrint('_paris start drag marker moved to: $latLng');
          setState(() {
            _showButtons = true;
          });
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

    // Mostrar el diálogo una vez al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dialogShown) {
        _showLocationDialog();
      }
    });
  }

  @override
  void dispose() {
    _serviceStatusStream.cancel();
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

  Future<void> _saveStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data != null) {
      final jsondata = jsonDecode(data);
      _locationData = LatLng(jsondata['latitude'], jsondata['longitude']);
      setState(() {
        _isLocationAvailable = true; // Hay ubicación almacenada
      });
    }
  }

  void _updateGPSStatus(ServiceStatus status) {
    debugPrint('-------------status: $status');
    _isGpsEnabled = (status == ServiceStatus.enabled) ? true : false;
    setState(() {});
  }

  Future<bool> _gpsEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled;
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
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          LatLng initialPosition = _paris;

          if (state is LocationInitial) {
            return const Center(child: Text('Fetching Location'));
          } else if (state is LocationLoadSuccess) {
            _locationData = initialPosition;
          } else if (state is LocationLoadFailure) {
            // Handle failure state if needed
          }

          return Padding(
            padding: const EdgeInsets.all(0),
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
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: initialPosition,
                          initialZoom: 5,
                        ),
                        children: [
                          openStreetMapTileLayer,
                          DragMarkers(
                            markers: _markers,
                            alignment: Alignment.topCenter,
                          ),
                        ],
                      ),
                      AnimatedPositioned(
                        bottom: size.height * 0.37,
                        //left: _showButtons ? 10 : 0,
                        right: _showButtons ? 10 : -50,
                        duration: const Duration(milliseconds: 300),
                        height: 40,
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          iconSize: 40,
                          onPressed: () {
                            debugPrint('Confirmed');
                            setState(() {
                              _showButtons = false; // Ocultar botones después de la acción
                            });
                          },
                        ),
                      ),
                      AnimatedPositioned(
                        bottom: (size.height * 0.37) - 40,
                        //left: _showButtons ? 10 : 0,
                        right: _showButtons ? 10 : -50,
                        duration: const Duration(milliseconds: 300),
                        height: 40,
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          iconSize: 40,
                          onPressed: () {
                            debugPrint('Canceled');
                            setState(() {
                              _showButtons = false; // Ocultar botones después de la acción
                            });
                          },
                        ),
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