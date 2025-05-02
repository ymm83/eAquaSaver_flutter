import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NoInternetConnection extends StatelessWidget {
  const NoInternetConnection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('services.no_internet'.tr()),
          const SizedBox(height: 8),
          const Icon(Icons.cloud_off_outlined, size: 40),
        ],
      ),
    );
  }
}
