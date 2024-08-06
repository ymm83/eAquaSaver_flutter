import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/main_screen.dart';
import 'config/supabase.dart';
import 'bloc/ble/ble_bloc.dart';
import 'bloc/location/location_bloc.dart';
import 'bloc/issue/issue_bloc.dart';
import 'api/secure_storage.dart';

final supabase = Supabase.instance.client;
final supabaseEAS = Supabase.instance.client.schema('eaquasaver');
final FlutterBluePlus flutterBlue = FlutterBluePlus();

Future<void> main() async {
  await Supabase.initialize(
    url: dbUrl,
    anonKey: dbAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
    storageOptions: const StorageClientOptions(
      retryAttempts: 5,
    ),
  );
  //runApp(const MyApp());
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BleBloc(flutterBlue)),
        BlocProvider(create: (context) => IssueBloc(supabase)),
        BlocProvider(create: (context) => LocationBloc()..add(LocationStarted())),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
