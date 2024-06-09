import 'package:flutter/material.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/supabase_client.dart';

Future<void> main() async {
  await initSupabase();
  await initSupabaseEAS();
  runApp(const MyApp());
}

//inal supabPub = supabasePub;
//final supabEAS = supabaseEAS;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Flutter',
      theme: ThemeData.dark().copyWith(
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
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountScreen(),
        '/main': (_) => const BLEMainScreen()
      },
    );
  }
}
