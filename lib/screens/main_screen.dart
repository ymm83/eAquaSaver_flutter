import 'dart:async';

//import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
//import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:eaquasaver/provider/theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

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
            column: 'user_id',
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
          event: PostgresChangeEvent.all,
          schema: 'eaquasaver',
          table: 'firmware',
          /*filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_type_id',
            value: 1,
          ),*/
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determina la pantalla a mostrar en la pestaña Main
    Widget mainScreen = (_adapterState == BluetoothAdapterState.on && _locationStatus == true)
        ? const MainTabs()
        : BluetoothOffScreen(adapterState: _adapterState);

    var scaffoldKey = GlobalKey<ScaffoldState>();

    // Lista de widgets para cada pestaña
    final List<Widget> screens = [
      const WaterTabs(),
      mainScreen,
      const UserTabs(
        key: Key('userTabs'),
      ),
    ];

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      color: Colors.greenAccent,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
          //systemNavigationBarIconBrightness: Theme.of(context).brightness,
        ),
        child: Scaffold(
          key: scaffoldKey,
          drawer: Drawer(
            elevation: 5,
            child: ListView(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.zero, // Elimina el padding predeterminado
              children: [
                // Header del Drawer
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).appBarTheme.foregroundColor),
                          onPressed: () => scaffoldKey.currentState?.closeDrawer(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/company_logo.png',
                            fit: BoxFit.cover,
                            height: 80,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'app_title'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).appBarTheme.foregroundColor,
                              fontFamily: 'ZenDots',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      /* Text(
                        'Usuario: John Doe',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),*/
                    ],
                  ),
                ),

                // Opciones del Drawer
                ListTile(
                  leading: Icon(Icons.home_outlined, color: Colors.blue),
                  title: Text('Inicio'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    Navigator.pop(context); // Cierra el Drawer
                  },
                ),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined, color: Colors.blue),
                  title: Text('Agua'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    Navigator.pop(context); // Cierra el Drawer
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_2_outlined, color: Colors.blue),
                  title: Text('Perfil'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    Navigator.pop(context); // Cierra el Drawer
                  },
                ),

                // Divisor
                Divider(),

                // Opción de cerrar sesión
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar sesión'),
                  onTap: () {
                    // Acción para cerrar sesión
                    Navigator.pop(context); // Cierra el Drawer
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ],
            ),
          ),
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Stack(
            children: [
              // AppBar personalizado
              Container(
                height: 130,
                child: AppBar(
                  elevation: 0.0,
                  leading: IconButton(
                    icon: Icon(Icons.menu, color: Theme.of(context).appBarTheme.iconTheme?.color),
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/company_logo.png',
                        fit: BoxFit.cover,
                        height: 40,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'eAquaSaver',
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          fontFamily: 'ZenDots',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: InkWell(
                        child: Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ),
                        onTap: () => null,
                      ), // Ensure Scaffold is in context
                    ),
                  ],
                ),
              ),
              // Contenido principal debajo del AppBar
              Padding(
                padding: EdgeInsets.only(top: 85),
                child: Card(
                  child: screens[_currentIndex],
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  clipBehavior: Clip.antiAlias,
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            //margin: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.blue,
                  width: 0.4,
                ),
                /*bottom: BorderSide(
                  color: Colors.blue,
                  width: 2.0,
                ),
                left: BorderSide(
                  color: Colors.blue,
                  width: 2.0,
                ),
                right: BorderSide(
                  color: Colors.blue,
                  width: 2.0,
                ),*/
              ),
            ),
            child: WaterDropNavBar(
              bottomPadding: 0.0,
              iconSize: 33,
              inactiveIconColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              waterDropColor: Colors.blue,
              onItemSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedIndex: _currentIndex,
              barItems: [
                BarItem(
                  filledIcon: Icons.water_drop_rounded,
                  outlinedIcon: Icons.water_drop_outlined,
                ),
                BarItem(
                  filledIcon: Icons.home_rounded,
                  outlinedIcon: Icons.home_outlined,
                ),
                BarItem(
                  filledIcon: Icons.person_2_rounded,
                  outlinedIcon: Icons.person_2_outlined,
                )
              ],
            ),
          ),
          /*bottomNavigationBar: CurvedNavigationBar(
          iconPadding: 14,
          color: AppColors.appBar,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          buttonBackgroundColor: Colors.grey.shade600,
          items: [
            CurvedNavigationBarItem(
                child: Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white,
                ),
                label: 'Water',
                labelStyle: TextStyle(color: Colors.white)),
            CurvedNavigationBarItem(
                child: Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                ),
                label: 'Home',
                labelStyle: TextStyle(color: Colors.white)),
            CurvedNavigationBarItem(
                child: Icon(
                  Icons.person_2_outlined,
                  color: Colors.white,
                ),
                label: 'User',
                labelStyle: TextStyle(color: Colors.white)),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),*/
          /*bottomNavigationBar: BottomNavigationBar(
          //backgroundColor: Colors.blue.shade100,
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
              label: 'Home',
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
        ),*/
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
