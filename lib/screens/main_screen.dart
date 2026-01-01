import 'dart:async';

//import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
//import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:eaquasaver/provider/theme_provider.dart';
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
  int _previousIndex = 0;
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
      mainScreen,
      const WaterTabs(),
      const UserTabs(
        key: Key('userTabs'),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Theme.of(context).colorScheme.surface,
          //systemNavigationBarIconBrightness: Theme.of(context).brightness,
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  child: Stack(
                    children: [
                      // Botón cerrar
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => scaffoldKey.currentState?.closeDrawer(),
                        ),
                      ),

                      // Contenido principal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/company_logo.png',
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'eAquaSaver',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontFamily: 'ZenDots',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // Opciones del Drawer
                ListTile(
                  leading: Icon(Icons.home_outlined, color: Colors.blue),
                  title: Text('Inicio'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    //Navigator.pop(context); // Cierra el Drawer
                    scaffoldKey.currentState?.closeDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined, color: Colors.blue),
                  title: Text('Agua'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    //Navigator.pop(context); // Cierra el Drawer
                    scaffoldKey.currentState?.closeDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_2_outlined, color: Colors.blue),
                  title: Text('Perfil'),
                  onTap: () {
                    // Acción al seleccionar esta opción
                    //Navigator.pop(context); // Cierra el Drawer
                    scaffoldKey.currentState?.closeDrawer();
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
                    //Navigator.pop(context); // Cierra el Drawer
                    scaffoldKey.currentState?.closeDrawer();
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
          //backgroundColor: Theme.of(context).colorScheme.surface,
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
                    children: [
                      Image.asset(
                        'assets/company_logo.png',
                        fit: BoxFit.cover,
                        height: 40,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'eAquaSaver',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'ZenDots',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                  centerTitle: false,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: InkWell(
                        child: Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).colorScheme.onSurface,
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
              inactiveIconColor: Theme.of(context).colorScheme.surfaceTint,
              backgroundColor: Theme.of(context).colorScheme.surface,
              waterDropColor: const Color(0xFF2196F3),
              onItemSelected: (index) {
                setState(() {
                  _previousIndex = _currentIndex;
                  _currentIndex = index;
                });
                
              },
              selectedIndex: _currentIndex,
              previousIndex: _previousIndex,
              barItems: [
                BarItem(
                  filledIcon: Icons.home_rounded,
                  outlinedIcon: Icons.home_outlined,
                ),
                BarItem(
                  filledIcon: Icons.water_drop_rounded,
                  outlinedIcon: Icons.water_drop_outlined,
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
      );
      
  }
}


