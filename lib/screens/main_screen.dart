import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/snackbar_helper.dart';
import 'bluetooth_off_screen.dart';
import 'water_tabs.dart';
import 'main_tabs.dart';
import 'user_tabs.dart';
import '../provider/supabase_provider.dart';

class BLEMainScreen extends StatefulWidget {
  const BLEMainScreen({super.key});

  @override
  State<BLEMainScreen> createState() => _BLEMainScreenState();
}

class _BLEMainScreenState extends State<BLEMainScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _locationStatus = false;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late StreamSubscription<ServiceStatus>? _serviceStatusStream;
  int _currentIndex = 0; // Índice para la barra de navegación inferior
  late final SupabaseClient supabase;

  @override
  void initState() {
    supabase = SupabaseProvider.getClient(context);
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setState(() {
        _locationStatus = (status == ServiceStatus.enabled) ? true : false;
      });
    });
    _initializeState();
    debugPrint('---- userid: ${supabase.auth.currentUser!.id}');
    supabase
        .channel('notification')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'eaquasaver',
          table: 'notification',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'userid',
            value: supabase.auth.currentUser!.id.toString(),
          ),
          callback: (payload) {
            final String notice = payload.newRecord['notice'];
            debugPrint('payload main: ${payload.newRecord['notice']}');
            showSnackBar('Realtime: $notice', theme: 'notify');
          },
        )
        .subscribe();

    supabase
        .channel('firmware')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'eaquasaver',
          table: 'firmware',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_type_id',
            value: 1,
          ),
          callback: (payload) {
            final String notice = payload.newRecord['version'];
            debugPrint('New firmware update: $notice');
            showSnackBar('New firmware update: $notice', theme: 'notify');
          },
        )
        .subscribe();

    super.initState();
  }

  Future<void> _initializeState() async {
    final initialAdapterState = await FlutterBluePlus.adapterState.first;
    setState(() {
      _adapterState = initialAdapterState;
    });

    final initialLocationStatus = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _locationStatus = initialLocationStatus;
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _serviceStatusStream?.cancel();
    supabase.channel('notification').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determina la pantalla a mostrar en la pestaña Main
    Widget mainScreen = (_adapterState == BluetoothAdapterState.on && _locationStatus == true)
        ? const MainTabs()
        : BluetoothOffScreen(adapterState: _adapterState);

    // Lista de widgets para cada pestaña
    final List<Widget> screens = [
      mainScreen,
      const WaterTabs(),
      const UserTabs(
        key: Key('userTabs'),
      ),
    ];

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
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
            actions: const [
              Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.notifications_active)),
            ]),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.blue.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
