//import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Temperature {
  String source;
  num minimal;
  num target;

  Temperature({required this.minimal, required this.target, this.source = 'device'});

  factory Temperature.fromJson(Map<String, dynamic> json) {
    return Temperature(
      minimal: json['minimal_temperature'],
      target: json['target_temperature'],
      source: json['source'] ?? 'device',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimal_temperature': minimal,
      'target_temperature': target,
      'source': source,
    };
  }

  double celsiusToFahrenheit(num celsius) {
    return (celsius * 9 / 5) + 32;
  }

  double get minimalFahrenheit => celsiusToFahrenheit(minimal);
  double get targetFahrenheit => celsiusToFahrenheit(target);
}

class UserProfile {
  String id;
  String? firstname;
  String? lastname;
  String? avatarUrl;
  String? updatedAt;
  int? targetTemperature;
  int? minimalTemperature;
  String? language;

  UserProfile({
    required this.id,
    this.firstname,
    this.lastname,
    this.avatarUrl,
    this.updatedAt,
    this.targetTemperature,
    this.minimalTemperature,
    this.language,
  });

  // Método para convertir a un mapa (por ejemplo, para guardar en una base de datos)
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'firstname': firstname,
      'lastname': lastname,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt,
      'target_temperature': targetTemperature,
      'minimal_temperature': minimalTemperature,
      'language': language,
    };
  }

  // Método para crear un objeto UserProfile a partir de un mapa
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      avatarUrl: json['avatar_url'],
      updatedAt: json['updated_at'],
      targetTemperature: json['target_temperature'],
      minimalTemperature: json['minimal_temperature'],
      language: json['language'],
    );
  }
}

class UserDevice {
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final String role;
  final int? credits;
  final DateTime? arrivalDate;
  final DateTime? leaveDate;
  final double? targetTemperature;
  final double? minimalTemperature;

  UserDevice({
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.role,
    this.credits,
    this.arrivalDate,
    this.leaveDate,
    this.targetTemperature,
    this.minimalTemperature,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      userId: json['user_id'],
      deviceId: json['device_id'],
      createdAt: json['created_at'],
      role: json['role'],
      credits: json['credits'],
      arrivalDate: json['arrival_date'],
      leaveDate: json['leave_date'],
      targetTemperature: json['target_temperature'],
      minimalTemperature: json['minimal_temperature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'role': role,
      'credits': credits,
      'arrival_date': arrivalDate?.toIso8601String(),
      'leave_date': leaveDate?.toIso8601String(),
      'target_temperature': targetTemperature,
      'minimal_temperature': minimalTemperature,
    };
  }
}

class Device {
  final String id;
  final String? model;
  final String? version;
  final Map<String, dynamic>? allow;
  final String? customName;

  Device({
    required this.id,
    this.model,
    this.version,
    this.allow,
    this.customName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      model: json['model'],
      version: json['version'],
      allow: json['allow'],
      customName: json['custom_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'version': version,
      'allow': allow,
      'custom_name': customName,
    };
  }
}

class DeviceService {
  final SupabaseQuerySchema supabase;
  final String deviceId;
  final String userId;
  String? role;
  List<String> roles = ['Admin', 'Member', 'Credits', 'Recerved'];
  List<String> allowRole = [];
  Map<String, dynamic> allow = {};
  String fixedName;
  final storage = new FlutterSecureStorage();

  DeviceService(this.supabase, this.deviceId, this.userId)
      : fixedName = deviceId.replaceRange(3, 4, 's').substring(0, 16);

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
    final registred = await isRegistred(fixedName);

    if (registred == false) {
      await registerDevice();
    } else {
      //debugPrint('El dispositivo ya está registrado');
    }
  }

  // * check user - device relation
  Future<bool> existsUser() async {
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

  //* Register device with `realName`.
  Future<bool> registerDevice() async {
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
          int indexUserRole = roles.indexOf(userRole!);
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

  //* Update supabase user_device -> update cache key: user_device
  Future<void> updateUserDevice({Map<String, dynamic>? data}) async {
    try {
      if (data != null) {
        final userData = await supabase
            .from('user_device')
            .update(data)
            .eq('device_id', fixedName)
            .eq('user_id', userId)
            .select()
            .single();
        if (userData.containsKey('device_id')) {
          await setCache(key: 'user_device', data: userData);
        }
      }
    } catch (e) {
      //debugPrint('Update user_device fail');
    }
  }

  //* Update supabase user_device -> update cache key: user_device
  //? add function for update minimal and target temperature in user_profile
  Future<void> updateUserProfile({Map<String, dynamic>? data}) async {
    try {
      if (data != null) {
        final userData = await supabase.from('user_profile').update(data).eq('id', userId).select('*').single();
        if (userData.containsKey('id')) {
          await setCache(key: 'user_profile', data: userData);
        }
      }
    } catch (e) {
      //debugPrint('Update user_profile fail');
    }
  }

  //* get available roles from device.allow jsonb
  Future<List<String>> getAvailableDeviceRole() async {
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
  Future<dynamic> getUserRole({bool cache = true}) async {
    //final roleKey = '$fixedName-user_device';
    debugPrint('------ getUserRole ------');
    if (cache == true) {
      Map<String, dynamic> roleData = await getCache(key: 'user_device');
      debugPrint('----- role from cache: ${roleData['role'].toString()}');

      return roleData['role'];
      // }
    }
    try {
      final response =
          await supabase.from('user_device').select('*').eq('device_id', fixedName).eq('user_id', userId).single();
      //debugPrint('----- role from supabase: ${response.toString()}');
      if (response.containsKey('role')) {
        final role = response['role'];
        await setCache(key: 'user_device', data: response);
        debugPrint('----- role from supabase: $role');
        return role;
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

  // get user_device all info from cache or supabase
  Future<Map<String, dynamic>> getUserDeviceInfo({bool cache = true}) async {
    try {
      if (cache == true) {
        final data = await getCache(key: 'user_device');
        //debugPrint('------ Fn>profileData-data: ${data.toString()}');

        if (data != null) {
          return data;
        }
      }
      Map<String, dynamic> response =
          await supabase.from('user_device').select('*').eq('device_id', fixedName).eq('user_id', userId).single();
      //debugPrint('------ Fn>profileData-response: ${response.toString()}');

      if (response.containsKey('device_id')) {
        if (cache == true) {
          await setCache(key: 'user_device', data: response);
        }
        return response;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // get user_device all info from cache or supabase
  Future<Map<String, dynamic>> getUserProfileInfo({bool cache = true}) async {
    try {
      if (cache == true) {
        final data = await getCache(key: 'user_profile');
        //debugPrint('------ Fn>getUserProfileInfo-data: ${data.toString()}');

        if (data != null) {
          return data;
        }
      }
      final response = await supabase.from('user_profile').select('*').eq('id', userId).single();
      //debugPrint('------ Fn>getUserProfileInfo-response: ${response.toString()}');

      if (response.containsKey('id')) {
        if (cache == true) {
          await setCache(key: 'user_profile', data: response);
        }
        return response;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<UserDevice?> getUserDevice({bool? cache}) async {
    try {
      if (cache == true) {
        final data = await getUserDeviceInfo(cache: true);
        return UserDevice.fromJson(data);
      }
      Map<String, dynamic> response =
          await supabase.from('user_device').select('*').eq('device_id', fixedName).eq('user_id', userId).single();
      //debugPrint('----- allow response: ${response.toString()}');
      if (response.containsKey('device_id')) {
        debugPrint('----- getUserDeviceInfo: ${getUserDeviceInfo.toString()}');

        return UserDevice.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

//Todo saveToCache
  Future<void> setCache({String? key, Map<String, dynamic>? data, dynamic value}) async {
    final custom_key = (key == null) ? fixedName : '$fixedName-$key';
    try {
      if (data != null) {
        await storage.write(key: custom_key, value: jsonEncode(data));
      }
      if (value != null) {
        await storage.write(key: custom_key, value: value);
      }
    } catch (error) {
      //debugPrint('class DeviceService>setCache>error: $error');
    }
  }

  //Todo loadFromCache
  Future<dynamic> getCache({String? key}) async {
    final customKey = key == null ? fixedName : '$fixedName-$key';
    try {
      final cachedData = await storage.read(key: customKey);
      if (cachedData != null) {
        try {
          final decodedData = jsonDecode(cachedData);
          //debugPrint('Tipo readCache decodificado: ${decodedData.runtimeType}');

          if (decodedData is Map<String, dynamic>) {
            return decodedData;
          } else if (decodedData is List) {
            return decodedData;
          } else if (decodedData is int || decodedData is double || decodedData is bool) {
            return decodedData;
          } else {
            return cachedData;
          }
        } catch (e) {
          //debugPrint('El valor ${cachedData.runtimeType} no es JSON válido: $e');
          return cachedData;
        }
      }
      return null; // Si `cachedData` es nulo, retornamos `null`
    } catch (error) {
      //debugPrint('Error en getCache: $error');
      return null;
    }
  }

  /*Future<dynamic> getCache({String? key}) async {
    final customKey = (key == null) ? fixedName : '$fixedName-$key';
    try {
      final cachedData = await storage.read(key: customKey);
      debugPrint('<<<<<<< Tipo readCache: ${cachedData.runtimeType} >>>>>>>');
      debugPrint('<<<<<<< Tipo $cachedData jsonDecode: ${jsonDecode(cachedData!).runtimeType} >>>>>>>');
      //if (cachedData != null) {
      final data = jsonDecode(cachedData);
      //if (data is Map<String, dynamic>) {
      // return data;
      //}
      //UserDevice userDevice = UserDevice.fromJson(data);
      // debugPrint('Fn>getCache>toString: ${cachedData.toString()}');
      // debugPrint('Fn>getCache>user_device.deviceId: ${userDevice.deviceId}');
      // debugPrint('Fn>getCache>jsonDecode: ${jsonDecode(cachedData)}');

      return data;
      //}
      // return null;
    } catch (error) {
      //debugPrint('class DeviceService>getCache>error: $error');
      return null;
    }
  }*/

  //* register user with a specific role or the hight available role
  Future<bool> registerUser({String? role}) async {
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

  //* get device all info from cache or supabase
  Future<Map<String, dynamic>> getDeviceInfo({bool? cache}) async {
    try {
      if (cache == true) {
        final data = await getCache(key: 'device');
        return data ?? {};
      }
      Map<String, dynamic> response = await supabase.from('device').select('*').eq('id', fixedName).single();
      if (response.containsKey('id')) {
        return response;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  //* get Device class instance
  Future<Device?> getDevice({bool? cache}) async {
    try {
      if (cache == true) {
        final data = await getDeviceInfo(cache: true);
        return Device.fromJson(data);
      }
      Map<String, dynamic> response = await supabase.from('device').select('*').eq('id', fixedName).single();
      if (response.containsKey('id')) {
        return Device.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // T E M P E R A T U R E
  //* get temperature info device preference in user settings
  //? source device - get temperature of user_device
  //? source profile - get temperature of user_profile
  Future<Map<String, dynamic>> getTemperature({String? source, bool cache = true}) async {
    try {
      String? data;

      if (source == null) {
        if (cache == true) {
          data = await storage.read(key: '$fixedName-user_device');
          data ??= await storage.read(key: '$fixedName-user_profile');
        }

        if (data != null) {
          Map<String, dynamic> decodeData = jsonDecode(data);
          if (decodeData.containsKey('target_temperature') && decodeData['target_temperature'] != null) {
            return {
              'target_temperature': decodeData['target_temperature'],
              'minimal_temperature': decodeData['minimal_temperature'],
            };
          }
        }

        var response =
            await supabase.from('user_device').select('*').eq('device_id', fixedName).eq('user_id', userId).single();

        if (response.containsKey('target_temperature') && response['target_temperature'] != null) {
          await setCache(key: 'user_device', data: response);
          return {
            'target_temperature': response['target_temperature'],
            'minimal_temperature': response['minimal_temperature'],
          };
        }

        response = await supabase.from('user_profile').select('*').eq('id', userId).single();

        if (response.containsKey('target_temperature') && response['target_temperature'] != null) {
          await setCache(key: 'user_profile', data: response);
          return {
            'target_temperature': response['target_temperature'],
            'minimal_temperature': response['minimal_temperature'],
          };
        }
      } else if (source == 'device') {
        if (cache == true) {
          data = await storage.read(key: '$fixedName-user_device');
        }

        if (data != null) {
          Map<String, dynamic> decodeData = jsonDecode(data);
          if (decodeData.containsKey('target_temperature') && decodeData['target_temperature'] != null) {
            return {
              'target_temperature': decodeData['target_temperature'],
              'minimal_temperature': decodeData['minimal_temperature'],
            };
          }
        }

        var response =
            await supabase.from('user_device').select('*').eq('device_id', fixedName).eq('user_id', userId).single();

        if (response.containsKey('target_temperature') && response['target_temperature'] != null) {
          if (cache) {
            await setCache(key: 'user_device', data: response);
          }
          return {
            'target_temperature': response['target_temperature'],
            'minimal_temperature': response['minimal_temperature'],
          };
        }
      } else if (source == 'profile') {
        if (cache) {
          data = await storage.read(key: '$fixedName-user_profile');
        }

        if (data != null) {
          Map<String, dynamic> decodeData = jsonDecode(data);
          if (decodeData.containsKey('target_temperature') && decodeData['target_temperature'] != null) {
            return {
              'target_temperature': decodeData['target_temperature'],
              'minimal_temperature': decodeData['minimal_temperature'],
            };
          }
        }

        var response = await supabase.from('user_profile').select('*').eq('id', userId).single();

        if (response.containsKey('target_temperature') && response['target_temperature'] != null) {
          if (cache) {
            await setCache(key: 'user_profile', data: response);
          }
          return {
            'target_temperature': response['target_temperature'],
            'minimal_temperature': response['minimal_temperature'],
          };
        }
      }
    } catch (e) {
      // debugPrint(e)
    }

    return {
      'target_temperature': null,
      'minimal_temperature': null,
    };
  }

  //* set temperature settings to device or profile
  //? source device - set temperature of user_device
  //? source profile - set temperature of user_profile
  Future<void> setTemperature({String? source, int? minimal, int? target, bool cache = true}) async {}
}
