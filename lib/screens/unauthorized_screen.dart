/*import 'package:flutter/material.dart';

class Unauthorized extends StatefulWidget {
  const Unauthorized({super.key});

  @override
  State<Unauthorized> createState() => _UnauthorizedState();
}

class _UnauthorizedState extends State<Unauthorized> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  'Acceso Denegado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'No tienes autorización para ver esta área',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  label: const Text(
                    'Regresar',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ),
  }
}*/

import 'package:flutter/material.dart';

class Unauthorized extends StatefulWidget {
  const Unauthorized({super.key});

  @override
  State<Unauthorized> createState() => _UnauthorizedState();
}

class _UnauthorizedState extends State<Unauthorized> {
  @override
  Widget build(BuildContext context) {
    return  Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100,),
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                Text(
                  'Unauthorized',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Colors.red.shade500),
                ),
                TextButton.icon(
                    icon: const Icon(Icons.key_rounded), label: const Text('Restricted area!'), onPressed: null)
              ]),
        ),
      );
    
  }
}
