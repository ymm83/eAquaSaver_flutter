import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/unauthorized_screen.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../provider/supabase_provider.dart';
import '../utils/device_service.dart';
import '../widgets/app_bar_loading_indicator.dart';
import '../widgets/custom_widgets.dart';
import 'disconnected_screen.dart';

class DeviceAllow extends StatefulWidget {
  final BluetoothDevice? device;
  //final String? role;
  const DeviceAllow({super.key, this.device}); //, this.role

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
  String? role;

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
    role = await deviceService!.getUserRole();
    //final allowRole = await deviceService?.getAvailableDeviceRole();
    debugPrint('-------role=${role.toString()}');
    final allow = await deviceService!.getAllowSettings();
    if (allow.isNotEmpty) {
      allowA = (allow['a'] == 1) ? true : false;
      allowM = (allow['m'] == 1) ? true : false;
      allowC = (allow['c'] == 1) ? true : false;
      allowR = (allow['r'] == 1) ? true : false;
    }
    //await deviceService?.insertDeviceIfNotExists();
    //await deviceService?.registerUserDevice();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(builder: (context, state) {
      return ScaffoldMessenger(
        child: Scaffold(
          appBar: AppBarLoadingIndicator(isLoading: role==null, height: 1.5,),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ignore: unnecessary_type_check
                if (state is ConnectivityOnline) ...[
                  if (role == 'Admin') ...[
                    buildRoleIcon(role),
                    const Text(
                      'Access control',
                      style: TextStyle(fontSize: 16),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Admins '),
                      subtitle: const Text('Allow new admins'),
                      value: allowA,
                      onChanged: (bool value) async {
                        setState(() {
                          allowA = value;
                        });
                        final val = allowA == true ? 1 : 0;
                        await deviceService?.updateAllowSettings(admin: val);
                      },
                      secondary: Icon(Icons.manage_accounts),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Members '),
                      subtitle: const Text('Allow new members'),
                      value: allowM,
                      onChanged: (bool value) async {
                        setState(() {
                          allowM = value;
                        });
                        final val = allowM == true ? 1 : 0;
                        await deviceService?.updateAllowSettings(member: val); //
                      },
                      secondary: const Icon(Icons.group),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Credits '),
                      subtitle: const Text('Users paid to used'),
                      value: allowC,
                      onChanged: (bool value) async {
                        setState(() {
                          allowC = value;
                        });
                        final val = allowC == true ? 1 : 0;
                        await deviceService?.updateAllowSettings(credits: val);
                      },
                      secondary: const Icon(Icons.credit_card),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Recerved '),
                      subtitle: const Text('Allow recerved users'),
                      value: allowR,
                      onChanged: (bool value) async {
                        setState(() {
                          allowR = value;
                        });
                        final val = allowR == true ? 1 : 0;
                        await deviceService?.updateAllowSettings(recerved: val);
                      },
                      secondary: const Icon(Icons.calendar_month),
                    ),
                  ] else if (['Member', 'Credits', 'Recerved'].contains(role)) ...[
                    const Unauthorized(),
                  ] else ...[
                    const SizedBox(height: 3,),
                    const Center(child: Text('Loading settings...')),
                  ],
                ] else if (state is ConnectivityOffline) ...[
                  const Disconnected(),
                ], // state condition
              ],
            ),
          ),
        ),
      );

      /*if (state is ConnectivityOnline) {
        return ;
      } else if (state is ConnectivityOffline) {
        return const Disconnected();
      } else {
        return const Center(child: CircularProgressIndicator());
      }*/
    });
  }
}
