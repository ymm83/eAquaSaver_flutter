import 'package:easy_localization/easy_localization.dart';
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
                  'device.unauthorized'.tr(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Colors.red.shade500),
                ),
                TextButton.icon(
                    icon: const Icon(Icons.key_rounded), label: Text('device.restricted'.tr()), onPressed: null)
              ]),
        ),
      );
    
  }
}
