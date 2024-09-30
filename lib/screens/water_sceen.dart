//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/water.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../widgets/water_analize.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _address;
  Map<String, dynamic>? _locationData;
  List<dynamic>? _potableData;
  Map _addressData = {};
  String _nomReseau = '...';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAddress();
  }

  Future<void> _fetchLocationAndAddress() async {
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
      setState(() {
        _addressData = addressData;
        _address = _getAddressString(addressData);
      });
      debugPrint('------ address:$_address');
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
  }

  String _getAddressString(Map addressData) {
    if (addressData['address']['country_code'] == 'fr') {
      return addressData['address']['municipality'] ?? addressData['address']['city'] ?? 'Unknown City';
    }
    return addressData['address']['country'] ?? 'Unknown Country';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, connectivityState) {
          if (connectivityState is ConnectivityOffline) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(child: Text('No internet connection')),
                Center(
                    child: TextButton.icon(
                        icon: const Icon(Icons.cloud_off_outlined), label: const Text('Offline'), onPressed: null))
              ],
            );
          }

          return BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              if (locationState is LocationLoadSuccess) {
                return Center(child: Text('Water Screen ${locationState.position}'));
              }

              if (_locationData == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final latitude = _locationData!['latitude'] ?? '0';
              final longitude = _locationData!['longitude'] ?? '0';

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text('Stored Location: \nLat: $latitude, \nLon: $longitude')),
                  if (_address == null) const Center(child: Text('Address: Loading...')),
                  if (_address != null) Center(child: Text('Address: $_address')),
                  if (_nomReseau != '...') Center(child: Text('RESEAU: $_nomReseau')),
                  if (_potableData == null && _addressData['address']?['country_code'] == 'fr')
                    const Center(child: Text('Loading analizes data...')),
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
            },
          );
        },
      ),
    );
  }
}
