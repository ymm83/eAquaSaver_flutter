import 'package:flutter/material.dart';
import 'home/home.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Universal BLE',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const UBLE(),
    ),
  );
}
