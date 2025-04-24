import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
//import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'screens/bluetooth_off_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/account_screen.dart';
import 'screens/auth_login.dart';
import 'screens/main_screen.dart';
import 'config/supabase.dart';
import 'provider/supabase_provider.dart';
import 'provider/theme_provider.dart';
import 'bloc/connectivity/connectivity_bloc.dart';
import 'bloc/beacon/beacon_bloc.dart';
import 'bloc/ble/ble_bloc.dart';
import 'bloc/location/location_bloc.dart';
import 'utils/theme_colors.dart';
import 'bloc/issue/issue_bloc.dart';

//final supabase = Supabase.instance.client;
//final supabaseEAS = Supabase.instance.client.schema('eaquasaver');
final FlutterBluePlus flutterBlue = FlutterBluePlus();
final connectivity = Connectivity();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || anonKey == null) {
    throw Exception("Faltan variables de entorno para Supabase");
  }
  await SupabaseConfig.initializeSupabase();
  final supabase = SupabaseConfig.getClient();
  final supabaseEAS = SupabaseConfig.getEasClient();
  //final supabase = Supabase.instance.client;
  //runApp(const MyApp());
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => BleBloc(flutterBlue)),
          BlocProvider(create: (context) => IssueBloc(supabase)),
          BlocProvider(create: (context) => LocationBloc()..add(LocationStarted())),
          BlocProvider(create: (context) => ConnectivityBloc(connectivity)),
          BlocProvider(create: (context) => BeaconBloc()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: SupabaseProvider(
          client: supabase,
          eASclient: supabaseEAS,
          child: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      //title: 'app_title'.tr(),
      debugShowCheckedModeBanner: false,
      theme: lightAppTheme,
      darkTheme: darkAppTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/splash',
      routes: <String, WidgetBuilder>{
        '/splash': (context) => const SplashPage(),
        '/main': (context) => const BLEMainScreen(),
        '/login': (context) => const LoginPage(),
        '/account': (context) => const AccountScreen(),
        '/required': (context) => const BluetoothOffScreen(),
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