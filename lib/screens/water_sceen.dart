import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../bloc/location/location_bloc.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> _getStorageLocation() async {
    final data = await _storage.read(key: 'storageLocation');
    return jsonDecode(data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          if (state is LocationLoadSuccess) {
            return Center(child: Text('Water Screen ${state.position}'));
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _getStorageLocation(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final data = snapshot.data!;
                final latitude = data['latitude'] ?? 'No latitude';
                final longitude = data['longitude'] ?? 'No longitude';
                return Center(child: Text('Stored Location: Lat: $latitude, Lon: $longitude'));
              } else {
                return Center(child: Text('No data available'));
              }
            },
          );
        },
      ),
    );
  }
}
