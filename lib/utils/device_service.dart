//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  final SupabaseQuerySchema supabase;
  final String deviceId;
  final String userId;
  String? role;
  List<String> roles = ['Admin', 'Member', 'Credits', 'Recerved'];
  List<String> allowRole = [];
  Map<String, dynamic> allow = {};

  DeviceService(this.supabase, this.deviceId, this.userId);

  String fixedDeviceName(String name) {
    return name.replaceRange(3, 4, 's').substring(0, 16);
  }

  /// about device exists `realName`.
  Future<bool> isRegistred(String realName) async {
    final fixedName = fixedDeviceName(realName);
    try {
      final response = await supabase.from('device').select('id').eq('id', fixedName).count();
      return response.count == 0 ? false : true;
    } catch (error) {
      //debugPrint('Error fetching device ID: $error');
      return false;
    }
  }

  Future<void> insertDeviceIfNotExists() async {
    final fixedName = fixedDeviceName(deviceId);
    final registred = await isRegistred(fixedName);

    if (registred == false) {
      await registerDevice();
    } else {
      //debugPrint('El dispositivo ya está registrado');
    }
  }

  // * check user - device relation
  Future<bool> existsUser() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final response = await supabase
          .from('user_device')
          .select('user_id')
          .eq('device_id', fixedName)
          .eq('user_id', userId)
          .inFilter('role', roles)
          .select()
          .count();
      return (response.count == 1) ? true : false;
    } catch (error) {
      //debugPrint('eeee Error fetching device ID: $error');
      return false;
    }
  }

  /*Future<int> existsUserDevice({required String role}) async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final response = await supabase
          .from('user_device')
          .select('device_id')
          .eq('device_id', fixedName)
          .eq('role', role)
          //.eq('user_id', userId)
          .count();

      return response.count;
    } catch (error) {
      //debugPrint('eeee Error fetching device ID: $error');
      return 0;
    }
  }*/

  //* Register device with `realName`.
  Future<bool> registerDevice() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final data = {
        'id': fixedName,
        'model': 1,
        'allow': {'a': 1, 'm': 1, 'c': 0, 'r': 0}
      };
      final response = await supabase.from('device').insert(data).select('id').count();

      if (response.count > 0) {
        return true;
        //debugPrint('Dispositivo registrado con ID: ${response['id']}');
      } else {
        return false;
        //debugPrint('Error: No se obtuvo el ID del dispositivo registrado.');
      }
    } catch (error) {
      return false;
      //debugPrint('Error inserting device: $error');
    }
  }

  //* register user,device or update user role if hight role is available
  Future<void> registerUserDevice() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final bool registred = await existsUser();
      if (registred == false) {
        await registerUser();
      } else {
        // Todo update role with allow settings
        final userRole = await getUserRole();
        final deviceRole = await getAvailableDeviceRole();
        if (userRole != deviceRole[0]) {
          // index {0: 'Admin', 1: 'Member', 2: 'Credits', 3: 'Reserved'}
          int indexUserRole = roles.indexOf(userRole);
          int indexDeviceRole = roles.indexOf(deviceRole[0]);

          if (indexUserRole > indexDeviceRole && [1, 2].contains(indexUserRole)) {
            await supabase
                .from('user_device')
                .update({'role': deviceRole[0]})
                .eq('device_id', fixedName)
                .eq('user_id', userId)
                .single();
          }
        }
      }
    } catch (e) {
      //debugPrint('Add User device fail');
    }
  }

  //* get available roles from device.allow jsonb
  Future<List<String>> getAvailableDeviceRole() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final data = await supabase.from('device').select('allow').eq('id', fixedName).single();
      if (data['allow']['a'] == 1) {
        allowRole.add('Admin');
      }
      if (data['allow']['m'] == 1) {
        allowRole.add('Member');
      }
      if (data['allow']['c'] == 1) {
        allowRole.add('Credits');
      }
      if (data['allow']['r'] == 1) {
        allowRole.add('Recerved');
      }
      return allowRole;
    } catch (e) {
      return [];
    }
  }

  //* update allow settings in device.allow jsonb
  Future<void> updateAllowSettings({int? admin, int? member, int? credits, int? recerved}) async {
    final fixedName = fixedDeviceName(deviceId);
    Map<String, int> allowNew = {};
    try {
      if (admin != null) {
        allowNew = {...allow, 'a': admin};
      }
      if (member != null) {
        allowNew = {...allow, 'm': member};
      }
      if (credits != null) {
        allowNew = {...allow, 'c': credits};
      }
      if (recerved != null) {
        allowNew = {...allow, 'r': recerved};
      }
      debugPrint('------ allowNew: ${allowNew.toString()}');
      final response = await supabase.from('device').update({'allow': allowNew}).eq('id', fixedName).select();
      debugPrint('------ response updateAllowSettings: ${response.toString()}');

      allow = allowNew;
    } catch (e) {
      debugPrint('------ error: ${e.toString()}');
      //return {'a': 0, 'm': 1, 'c': 1, 'r': 1};
    }
  }

  // todo getUserRole
  Future<dynamic> getUserRole() async {
    final fixedName = fixedDeviceName(deviceId);
    debugPrint('----- role: ${fixedName.toString()}');

    try {
      final role =
          await supabase.from('user_device').select('role').eq('device_id', fixedName).eq('user_id', userId).single();

      debugPrint('----- role: ${role.toString()}');
      if (role.containsKey('role')) {
        return role['role'];
      }
      //debugPrint('----- allowConfig: ${allowConfig.toString()}');
      //if (allowConfig.count == 1)
      return null;
    } catch (e) {
      debugPrint('----- getUserRole Error: ${e.toString()}');
      return null;
    }
  }

  //* get device.allow settings
  Future<Map<String, dynamic>> getAllowSettings() async {
    final fixedName = fixedDeviceName(deviceId);

    try {
      Map<String, dynamic> response = await supabase.from('device').select('allow').eq('id', fixedName).single();
      debugPrint('----- allow response: ${response.toString()}');
      if (response.containsKey('allow')) {
        allow = response['allow'];
        return response['allow'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  //* register user with a specific role or the hight available role
  Future<bool> registerUser({String? role}) async {
    final fixedName = fixedDeviceName(deviceId);
    Map data = {};

    try {
      if (role == null) {
        await getAvailableDeviceRole(); //return allow config List role and set in allowRole the List
        if (allowRole.isNotEmpty) {
          data = {'device_id': fixedName, 'user_id': userId, 'role': allowRole[0]};
        }
      } else {
        if (roles.contains(role)) {
          data = {'device_id': fixedName, 'user_id': userId, 'role': role};
        }
      }
      if (data.isNotEmpty) {
        await supabase.from('user_device').insert(data).select('user_id').single();
        return true;
      }
      return false;
    } catch (e) {
      return false;
      //debugPrint('Add User device fail');
    }
  }
}

Widget _buildIconRole(String? role) {
  ///debugPrint('role: $role');
  IconData iconData;
  if (role == 'Admin') {
    iconData = Icons.admin_panel_settings;
  } else if (role == 'Member') {
    iconData = Icons.person;
  } else if (role == 'Credits') {
    iconData = Icons.credit_card;
  } else if (role == 'Recerved') {
    iconData = Icons.calendar_month;
  } else {
    iconData = Icons.lock_outline;
  }

  return role != null ? Icon(iconData) : const SizedBox.shrink();
}
