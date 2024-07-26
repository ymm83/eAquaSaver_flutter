import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location/location_bloc.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<LocationBloc, LocationState>(builder: (context, state) {
      if (state is LocationLoadSuccess) {
        return Center(child: Text('Water Screen ${state.position}'));
      }
      return const Center(child: CircularProgressIndicator());
    }));
  }
}
