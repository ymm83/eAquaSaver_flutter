import 'package:flutter/material.dart';

class NoInternetConnection extends StatelessWidget {
  const NoInternetConnection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No internet connection'),
          SizedBox(height: 8),
          Icon(Icons.cloud_off_outlined, size: 40),
        ],
      ),
    );
  }
}
