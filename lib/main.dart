import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/main_screen.dart';
import 'config/supabase.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: dbUrl,
    anonKey: dbAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
final supabaseEAS = Supabase.instance.client.schema('eaquasaver');

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
      initialRoute: '/login',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/main': (_) => const BLEMainScreen(),
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountScreen(),
      },
      onGenerateRoute: (RouteSettings settings) {
        print('Ruta llamado ${settings.name}');
        /*if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }*/
      },
      onUnknownRoute: (settings) {
        print('onUnknownRouteonUnknownRouteonUnknownRouteonUnknownRouteonUnknownRoute');
        return MaterialPageRoute(builder: (context) => const BLEMainScreen());
      },
    );
  }
}
