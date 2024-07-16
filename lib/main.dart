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
import 'bloc/issue/issue_bloc.dart';

final supabase = Supabase.instance.client;
final supabaseEAS = Supabase.instance.client.schema('eaquasaver');
final FlutterBluePlus flutterBlue = FlutterBluePlus();

Future<void> main() async {
  await Supabase.initialize(
    url: dbUrl,
    anonKey: dbAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  //runApp(const MyApp());
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BleBloc(flutterBlue)),
        BlocProvider(create: (context) => IssueBloc(supabaseEAS, supabase.auth.currentUser!.id)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<BleBloc>(create: (context) => BleBloc(flutterBlue)),
        ],
        child: MaterialApp(
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
          initialRoute: '/login',
          routes: <String, WidgetBuilder>{
            '/': (_) => const SplashPage(),
            '/main': (_) => const BLEMainScreen(),
            '/login': (_) => const LoginPage(),
            '/account': (_) => const AccountScreen(),
          },
          onGenerateRoute: (RouteSettings settings) {
            print('Ruta llamado ${settings.name}');
            return null;
            /*if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }*/
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (context) => const BLEMainScreen());
          },
        ));
  }
}
