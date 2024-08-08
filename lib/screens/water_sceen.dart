import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/water.dart';
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
  String _nomReseau = '...';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAddress();
  }

  Future<void> _fetchLocationAndAddress() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data != null) {
      final locationData = testCoord['h']; // for test
      setState(() {
        _locationData = locationData;
      });
      //final locationData = jsonDecode(data); // origen
      debugPrint('${locationData['latitude'].runtimeType}');
      final latitude = locationData['latitude'] ?? '0';

      final longitude = locationData['longitude'] ?? '0';

      final addressData = await getReverseLocation({'latitude': latitude, 'longitude': longitude});

      if (addressData['address']['country_code'] == 'fr') {
        String nomCommune;

        if (addressData['address'].containsKey('municipality')) {
          nomCommune = addressData['address']['municipality'];
          //console.log('tiene municipio: ', response.address.municipality);
        } else {
          nomCommune = addressData['address']['city'];

          //nom_commune = getPlaceByZipCode();
          //console.log('sin municipio');
        }

        setState(() {
          _address = nomCommune;
        });
        // France Commune Data
        final euaComune = await franceEuaCommune(nomCommune);
        setState(() {
          _nomReseau = euaComune['nom_reseau'];
        });
        debugPrint('${euaComune.toString()}');
        if (euaComune.containsKey('code_commune')) {
          rawApiResults(euaComune['code_commune']).then((result) {
            debugPrint('${result.toString()}');
            setState(() {
              _potableData = result;
            });
          });
        }
      } else {
        setState(() {
          _address = addressData['address']['country'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          if (state is LocationLoadSuccess) {
            return Center(child: Text('Water Screen ${state.position}'));
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
              Center(child: Text('Address: ${_address ?? 'Loading...'}')),
              if (_nomReseau != '...') Center(child: Text('RESEAU: $_nomReseau')),
              if (_potableData == null) const Center(child: Text('Loadding analizes data...')),
              if (_potableData == null)
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
      ),
    );
  }
}
