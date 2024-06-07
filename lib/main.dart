import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://ierapckvmomyjujxrmss.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllcmFwY2t2bW9teWp1anhybXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDE5NjY4OTYsImV4cCI6MjAxNzU0Mjg5Nn0.NTL1AJL27lZr9oLsBrvhRBz-V5rv3iN3VD2VnvaRAmQ',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

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
