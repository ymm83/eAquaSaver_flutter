import 'dart:async';

import 'package:eaquasaver_flutter_app/screens/water_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'bluetooth_off_screen.dart';
import 'account_screen.dart';
import 'scan_screen.dart';
import 'main_tabs.dart';
import 'user_tabs.dart';

class BLEMainScreen extends StatefulWidget {
  const BLEMainScreen({super.key});

  @override
  State<BLEMainScreen> createState() => _BLEMainScreenState();
}

class _BLEMainScreenState extends State<BLEMainScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  int _currentIndex = 0; // Índice para la barra de navegación inferior

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determina la pantalla a mostrar en la pestaña Main
    Widget mainScreen = _adapterState == BluetoothAdapterState.on ? const MainTabs() : BluetoothOffScreen(adapterState: _adapterState);

    // Lista de widgets para cada pestaña
    final List<Widget> screens = [
      mainScreen,
      const WaterTabs(),
      const UserTabs(),
    ];

    return MaterialApp(
      color: Colors.greenAccent,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/company_logo.png',
                fit: BoxFit.cover,
                height: 40,
              ),
              Image.asset('assets/app_title.png', fit: BoxFit.cover)
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.green[100],
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Main',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              label: 'Water',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              label: 'User',
            ),
          ],
        ),
      ),
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}
