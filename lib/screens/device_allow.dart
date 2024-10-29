import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../provider/supabase_provider.dart';
import '../utils/device_service.dart';
import 'disconnected_screen.dart';

class DeviceAllow extends StatefulWidget {
  final BluetoothDevice? device;
  const DeviceAllow({super.key, this.device});

  @override
  State<DeviceAllow> createState() => _DeviceAllowState();
}

class _DeviceAllowState extends State<DeviceAllow> {
  //Todo load allow value from supabase
  bool allowA = true;
  bool allowM = true;
  bool allowC = true;
  bool allowR = true;

  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  DeviceService? deviceService;
  String? userRole;

  @override
  void initState() {
    super.initState();
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    deviceService = DeviceService(supabaseEAS, widget.device!.platformName, supabase.auth.currentUser!.id);
    _initializeAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeAsync() async {
    final role = await deviceService?.getAvailableDeviceRole();
    debugPrint('-------getAvailableDeviceRole=${role.toString()}');
    await deviceService?.insertDeviceIfNotExists();
    if (await deviceService?.existsUserDevice(role: 'Admin') == 0) {
      await deviceService?.registerUserDevice();
    }
    await deviceService?.getAllowUser();
    userRole = await deviceService?.getUserRole();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(builder: (context, state) {
      if (state is ConnectivityOnline) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(5),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Enable Admins '),
                subtitle: Text('Allow new admins'),
                value: allowA,
                onChanged: (bool value) async {
                  setState(() {
                    allowA = value;
                  });
                  final val = allowA == true ? 1 : 0;
                  await deviceService?.setAllowUser(admin: val);
                },
                secondary: Icon(Icons.manage_accounts),
              ),
              SwitchListTile(
                title: Text('Enable Members '),
                subtitle: Text('Allow new members'),
                value: allowM,
                onChanged: (bool value) async {
                  setState(() {
                    allowM = value;
                  });
                  final val = allowM == true ? 1 : 0;
                  await deviceService?.setAllowUser(member: val); //
                },
                secondary: Icon(Icons.group),
              ),
              SwitchListTile(
                title: Text('Enable Credits '),
                subtitle: Text('Users paid to used'),
                value: allowC,
                onChanged: (bool value) async {
                  setState(() {
                    allowC = value;
                  });
                  final val = allowC == true ? 1 : 0;
                  await deviceService?.setAllowUser(credits: val);
                },
                secondary: Icon(Icons.credit_card),
              ),
              SwitchListTile(
                title: Text('Enable Recerved '),
                subtitle: Text('Allow recerved users'),
                value: allowR,
                onChanged: (bool value) async {
                  setState(() {
                    allowR = value;
                  });
                  final val = allowR == true ? 1 : 0;
                  await deviceService?.setAllowUser(recerved: val);
                },
                secondary: Icon(Icons.calendar_month),
              ),
            ],
          ),
        );
      } else if (state is ConnectivityOffline) {
        return const Disconnected();
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    });
  }
}
