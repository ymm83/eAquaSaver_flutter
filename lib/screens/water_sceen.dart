import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/water.dart';
import '../bloc/location/location_bloc.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _address;
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAddress();
  }

  Future<void> _fetchLocationAndAddress() async {
    final data = await _storage.read(key: 'storageLocation');
    if (data != null) {
      final locationData = jsonDecode(data);
      final latitude = locationData['latitude'] ?? '0';
      final longitude = locationData['longitude'] ?? '0';
      setState(() {
        _locationData = locationData;
      });

      final addressData = await getReverseLocation({'latitude': latitude, 'longitude': longitude});
      setState(() {
        _address = addressData['address']['city_district'];
      });
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text('Stored Location: Lat: $latitude, Lon: $longitude')),
              Center(child: Text('Address: ${_address ?? 'Loading...'}')),
            ],
          );
        },
      ),
    );
  }
}
