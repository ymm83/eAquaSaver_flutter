import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/main_screen.dart';
import 'config/supabase.dart';
import 'provider/supabase_provider.dart';
import 'bloc/connectivity/connectivity_bloc.dart';
import 'bloc/beacon/beacon_bloc.dart';
import 'bloc/ble/ble_bloc.dart';
import 'bloc/location/location_bloc.dart';
import 'bloc/issue/issue_bloc.dart';

//final supabase = Supabase.instance.client;
//final supabaseEAS = Supabase.instance.client.schema('eaquasaver');
final FlutterBluePlus flutterBlue = FlutterBluePlus();
final connectivity = Connectivity();

Future<void> main() async {
  await SupabaseConfig.initializeSupabase();
  final supabase = SupabaseConfig.getClient();
  final supabaseEAS = SupabaseConfig.getEasClient();
  //final supabase = Supabase.instance.client;
  //runApp(const MyApp());
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BleBloc(flutterBlue)),
        BlocProvider(create: (context) => IssueBloc(supabase)),
        BlocProvider(create: (context) => LocationBloc()..add(LocationStarted())),
        BlocProvider(create: (context) => ConnectivityBloc(connectivity)),
        BlocProvider(create: (context) => BeaconBloc()),
      ],
      child: SupabaseProvider(
        client: supabase,
        eASclient: supabaseEAS,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eAquaSaver',
      
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.green,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: <String, WidgetBuilder>{
        '/splash': (_) => const SplashPage(),
        '/main': (_) => const BLEMainScreen(),
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountScreen(),
      },
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider extends InheritedWidget {
  final SupabaseClient supabaseClient;

  SupabaseProvider({
    Key? key,
    required this.supabaseClient,
    required Widget child,
  }) : super(key: key, child: child);

  static SupabaseProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SupabaseProvider>();
  }

  @override
  bool updateShouldNotify(SupabaseProvider oldWidget) {
    return supabaseClient != oldWidget.supabaseClient;
  }
}

*/