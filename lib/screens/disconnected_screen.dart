import 'package:flutter/material.dart';

class Disconnected extends StatefulWidget {
  const Disconnected({super.key});

  @override
  State<Disconnected> createState() => _DisconnectedState();
}

class _DisconnectedState extends State<Disconnected> {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Center(
          child: Text(
        'No internet connection',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red.shade500),
      )),
      Center(
          child: TextButton.icon(
              icon: const Icon(Icons.cloud_off_outlined), label: const Text('Offline'), onPressed: null))
    ]);
  }
}
