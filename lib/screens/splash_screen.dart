import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/supabase_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late SupabaseClient supabase;

  @override
  void initState() {
    supabase = SupabaseProvider.getClient(context);
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    //await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }

    //for testing in emulator
    //Navigator.of(context).pushReplacementNamed('/main');
    final session = supabase.auth.currentSession;
    if (session != null) {
      /*  Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context), // Hereda el tema actual
            child: const BLEMainScreen(),
          ),
        ),
      );*/

      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 243, 250),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: AssetImage('assets/company_logo.png'),
            fit: BoxFit.contain,
            width: 200,
            height: 150,
          ),
          SizedBox(height: 20),
          Center(
              child: Text(
            'eAquaSaver App',
            style: TextStyle(fontSize: 27, color: Color.fromARGB(255, 3, 50, 138), fontWeight: FontWeight.bold),
          )),
          SizedBox(height: 10),
          Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(
                color: Colors.blue,
                backgroundColor: Colors.redAccent,
              )),
          Center(child: SizedBox(height: 10)),
          Center(
              child: Text(
            'Loading...',
            style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 3, 50, 138)),
          )),
          Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text(
                'SantRoss Tech Company ®',
                style: TextStyle(color: Color.fromARGB(255, 7, 128, 11), fontSize: 15),
              ))
        ],
      ),
    );
  }
}
