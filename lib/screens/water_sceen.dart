//import 'dart:convert';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import '../api/water.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../widgets/water_analize.dart';
import 'disconnected_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _address;
  LatLng? _locationData;
  List<dynamic>? _potableData;
  Map _addressData = {};
  String _nomReseau = '...';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAddress();
  }

  /// Función auxiliar para quitar acentos de una cadena (ej: è -> e)
  String _removeDiacritics(String str) {
    const withDiacritics = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDiacritics = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

Future<void> _fetchLocationAndAddress() async {
  try {
    final String? data = await _storage.read(key: 'storageLocation');

    // Obtener Map (storage o test)
    final Map<String, dynamic> rawLocationData =
        data != null ? jsonDecode(data) : testCoord['b'];

    // 🔥 CONVERSIÓN CORRECTA Map → LatLng
    final double latitude =
        (rawLocationData['latitude'] ?? 0).toDouble();
    final double longitude =
        (rawLocationData['longitude'] ?? 0).toDouble();

    final LatLng location = LatLng(latitude, longitude);

    if (!mounted) return;

    setState(() {
      _locationData = location;
    });

    // Reverse geocoding
    final Map<String, dynamic> addressData =
        await getReverseLocation({
      'latitude': latitude,
      'longitude': longitude,
    });

    if (!mounted) return;

    setState(() {
      _addressData = addressData;
      _address = _getAddressString(addressData);
    });

    debugPrint('------ addressData: $addressData');
    debugPrint('------ address: $_address');

    // 🔥 BLINDAJE TOTAL AQUÍ 🔥
    final dynamic rawAddress = addressData['address'];

    if (rawAddress == null || rawAddress is! Map<String, dynamic>) {
      debugPrint('❌ addressData["address"] es null o inválido');
      return;
    }
    // Francia
    final Map<String, dynamic>? address = addressData['address'];

    if (address != null && address['country_code'] == 'fr') {
      final String? nomCommune =
          address['municipality'] ?? address['city'];

      if (nomCommune == null || nomCommune.isEmpty) {
        debugPrint('❌ No se pudo determinar la comuna');
        return;
      }
      
       String cleanCommune = _removeDiacritics(nomCommune);
        debugPrint('🔍 Buscando comuna: $cleanCommune');

        final Map<String, dynamic>? euaComune =
            await franceEuaCommune(cleanCommune);

        if (euaComune == null) {
          debugPrint('❌ franceEuaCommune devolvió null para $cleanCommune');
          return;
        }
        _nomReseau = euaComune['nom_reseau'];

        if (euaComune.containsKey('code_commune')) {
          final result =
              await rawApiResults(euaComune['code_commune']);

          if (!mounted) return;

          setState(() {
            _potableData = result;
          });
        }
      
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Error en _fetchLocationAndAddress: $e');
    debugPrint('$stackTrace');
  }
}



  /*Future<void> _fetchLocationAndAddress() async {
    final data = await _storage.read(key: 'storageLocation');
    final locationData = testCoord['b']; // for test
    if (data != null) {
      setState(() {
        _locationData = locationData;
      });
      // final locationData = jsonDecode(data); // origen
      final latitude = locationData['latitude'] ?? '0';
      final longitude = locationData['longitude'] ?? '0';

      final addressData = await getReverseLocation({'latitude': latitude, 'longitude': longitude});
      if (mounted) {
        setState(() {
          _addressData = addressData;
          _address = _getAddressString(addressData);
        });
      }
      debugPrint('------ addressData: $addressData');

      debugPrint('------ address: $_address');
      if (addressData['address']['country_code'] == 'fr') {
        final nomCommune = addressData['address']['municipality'] ?? addressData['address']['city'];
        final euaComune = await franceEuaCommune(nomCommune);
        //setState(() {
        _nomReseau = euaComune['nom_reseau'];
        //});

        if (euaComune.containsKey('code_commune')) {
          final result = await rawApiResults(euaComune['code_commune']);
          setState(() {
            _potableData = result;
          });
        }
      }
    } else {
      setState(() {
        _locationData = locationData;
      });
    }
  }*/

  String _getAddressString(Map addressData) {
    if (addressData['address']['country_code'] == 'fr') {
      return addressData['address']['municipality'] ?? addressData['address']['city'] ?? 'Unknown City';
    }
    return addressData['address']['country'] ?? 'Unknown Country';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, connectivityState) {
          if (connectivityState is ConnectivityOffline) {
            return const Disconnected();
          }

          return BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              /*if (locationState is LocationLoadSuccess) {
                return Center(child: Text('Water Screen ${locationState.position}'));
              }*/

              if (_locationData == null) {
                return const Center(child: CircularProgressIndicator());
              }

              //final latitude = _locationData['latitude'] ?? '0';
              //final longitude = _locationData['longitude'] ?? '0';

              return  Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:Theme.of(context).colorScheme.primaryContainer,
                      )
                    ),
                    child: Column(
                      children: [
                        //Center(child: Text('Stored Location: \nLat: $latitude, \nLon: $longitude')),
                        if (_address == null) const Center(child: Text('Address: Loading...')),
                        if (_address != null) Center(child: Text('Address: $_address')),
                        if (_nomReseau != '...') Center(child: Text('RESEAU: $_nomReseau')),
                        if (_potableData == null && _addressData['address']?['country_code'] == 'fr')
                          const Center(child: Text('Loading analizes data...')),
                        
                      ],
                    ),
                  ),
                  if (_potableData == null && _addressData['address']?['country_code'] == 'fr')
                    const Padding(
                        padding: EdgeInsets.all(20),
                        child: LinearProgressIndicator(
                          color: Colors.blue,
                          backgroundColor: Colors.redAccent,
                        )),
                  if (_potableData != null && _potableData!.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _potableData!.length,
                        itemBuilder: (context, index) {
                          final item = _potableData![index];
                          return Analize(item: item);
                        },
                      ),
                    ),
                  if (_potableData != null && _potableData!.isEmpty) const Center(child: Text('No data available')),
                ],
              
              );
            }
          );
        }
      )
    );
  }
}
