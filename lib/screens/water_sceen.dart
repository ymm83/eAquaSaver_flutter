//import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/water.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../widgets/water_analysis.dart';
import 'disconnected_screen.dart';

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
  }

  String _getAddressString(Map addressData) {
    if (addressData['address']['country_code'] == 'fr') {
      return addressData['address']['municipality'] ?? addressData['address']['city'] ?? 'map.unknown_city'.tr();
    }
    return addressData['address']['country'] ?? 'map.unknown_ountry'.tr();
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

              final latitude = _locationData!['latitude'] ?? '0';
              final longitude = _locationData!['longitude'] ?? '0';

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text("${'water.stored_location'.tr()}: \nLat: $latitude, \nLon: $longitude")),
                  if (_address == null) Center(child: Text('water.loading_address'.tr())),
                  if (_address != null) Center(child: Text('${'water.address'.tr()} $_address')),
                  if (_nomReseau != '...') Center(child: Text('${'water.network'.tr()} $_nomReseau')),
                  if (_potableData == null && _addressData['address']?['country_code'] == 'fr')
                    Center(child: Text('water.loading_analysis'.tr())),
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
                          return Analysis(item: item);
                        },
                      ),
                    ),
                  if (_potableData != null && _potableData!.isEmpty) Center(child: Text('water.no_data'.tr())),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
