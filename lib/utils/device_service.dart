//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  final SupabaseQuerySchema supabase;
  final String deviceId;
  final String userId;
  String? role;
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

  Future<int> existsUserDevice({required String role}) async {
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
  }

  /// determinar si existe la relacion `user_id`- `device_id`.
  Future<dynamic> roleDeviceUser() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final response =
          await supabase.from('user_device').select('role').eq('device_id', fixedName).eq('user_id', userId).count();

      return response.count == 0 ? null : response.data[0]['role'];
    } catch (error) {
      //debugPrint('Error fetching device ID: $error');
      return null;
    }
  }

  /// determinar si existe la relacion `user_id`- `device_id`.
  Future<int> existsUsersDevice() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final response = await supabase
          .from('user_device')
          .select('device_id')
          .eq('device_id', fixedName)
          .eq('user_id', userId)
          .inFilter('role', ['Admin', 'Member', 'Recerved', 'Credits']).count();

      return response.count;
    } catch (error) {
      //debugPrint('Error fetching device ID: $error');
      return 0;
    }
  }

  /// Registra un dispositivo con el `realName` proporcionado.
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

  Future<void> registerUserDevice() async {
    try {
      if (await existsUserDevice(role: 'Admin') == 0) {
        await registerUser(role: 'Admin');
      } else {
        // Todo allow device settings
        final role = await getAvailableDeviceRole();
        debugPrint('-------getAvailableDeviceRole=${role.toString()}');
        if (role[0].isNotEmpty) {
          await registerUser(role: role[0]);
        }
      }
    } catch (e) {
      //debugPrint('Add User device fail');
    }
  }

  Future<List<String>> getAvailableDeviceRole() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final data = await supabase.from('device').select('allow').eq('id', fixedName).single();
      if (data['allow']['a'] == 1) {
        allowRole?.add('Admin');
      }
      if (data['allow']['m'] == 1) {
        allowRole?.add('Member');
      }
      if (data['allow']['c'] == 1) {
        allowRole?.add('Credits');
      }
      if (data['allow']['r'] == 1) {
        allowRole?.add('Recerved');
      }
      return allowRole ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAllowUserDevice() async {
    final fixedName = fixedDeviceName(deviceId);
    try {
      final data = await supabase.from('device').select('allow').eq('id', fixedName).single();
      return data;
    } catch (e) {
      return {'a': 0, 'm': 1, 'c': 1, 'r': 1};
    }
  }

  Future<void> setAllowUser({int? admin, int? member, int? credits, int? recerved}) async {
    final fixedName = fixedDeviceName(deviceId);
    Map<String, int> allowNew = {};
    //Map<String, int> allowA = {};
    //Map<String, int> allowM = {};
    //Map<String, int> allowR = {};
    //Map<String, int> allowC = {};

    //allow = {...allowA, ...allowM, ...allowC, ...allowR};

    //debugPrint('allowSettings ${allow.toString()}');
    try {
      if (admin != null) {
        allowNew = {...allow, 'a': admin};
        //allow = {'a': admin};
      }
      if (member != null) {
        allowNew = {...allow, 'm': member};
        //allow = {'m': member};
      }
      if (credits != null) {
        allowNew = {...allow, 'c': credits};
        //allow = {'c': credits};
      }
      if (recerved != null) {
        allowNew = {...allow, 'r': recerved};
        //allow = {'r': recerved};
      }
      debugPrint('------ allowNew: ${allowNew.toString()}');
      final response = await supabase.from('device').update({'allow': allowNew}).eq('id', fixedName).select();
      debugPrint('------ response setAllowUser: ${response.toString()}');

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

  Future<void> getAllowUser() async {
    final fixedName = fixedDeviceName(deviceId);

    try {
      Map<String, dynamic> response = await supabase.from('device').select('allow').eq('id', fixedName).single();
      debugPrint('----- allow response: ${response.toString()}');
      if (response.containsKey('allow')) {
        allow = response['allow'];
      }
    } catch (e) {}
  }

  Future<bool> registerUser({String role = 'Member'}) async {
    final fixedName = fixedDeviceName(deviceId);
    Map data = {'device_id': fixedName, 'user_id': userId, 'role': role};
    try {
      await supabase.from('user_device').insert(data).select('user_id').single();
      return true;
    } catch (e) {
      return false;
      //debugPrint('Add User device fail');
    }
  }
}
