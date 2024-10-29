import 'dart:convert'; // Para jsonEncode y jsonDecode
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para almacenamiento local

class DeviceService {
  final SupabaseQuerySchema supabase;
  static const String DEVICE_KEY = 'cached_device';

  /// Propiedad local para almacenar el ID del dispositivo.
  int deviceId = 0;
  String? _userId;
  String? _deviceName;

  DeviceService(this.supabase);

  /// Inserta un dispositivo si no existe basado en su `realName`.
  Future<void> insertDeviceIfNotExists(String realName) async {
    final deviceId = await getDeviceId(realName);

    if (deviceId == 0) {
      await registerDevice(realName);
    } else {
      debugPrint('El dispositivo ya está registrado con ID: $deviceId');
      this.deviceId = deviceId; // Actualizamos el ID local
    }
  }

  /// Obtiene el ID del dispositivo basado en su `realName`.
  Future<int> getDeviceId(String realName) async {
    try {
      final response = await supabase
          .from('device')
          .select('id')
          .eq('real_name', realName)
          .maybeSingle(); // Usar `maybeSingle` para manejar cuando no se encuentra ningún registro

      if (response == null) {
        return 0;
      }

      final id = response['id'] as int;
      this.deviceId = id; // Actualizamos el ID local
      await setDeviceCache({'id': id, 'real_name': realName}); // Almacenamos en caché

      return id;
    } catch (error) {
      debugPrint('Error fetching device ID: $error');
      return 0;
    }
  }

  /// Registra un dispositivo con el `realName` proporcionado.
  Future<void> registerDevice(String realName) async {
    try {
      final response = await supabase.from('device').insert({'real_name': realName}).select('id').single();

      if (response['id'] != null) {
        final id = response['id'] as int;
        this.deviceId = id; // Actualizamos el ID local
        await setDeviceCache({'id': id, 'real_name': realName}); // Almacenamos en caché
        debugPrint('Dispositivo registrado con ID: $id');
      } else {
        debugPrint('Error: No se obtuvo el ID del dispositivo registrado.');
      }
    } catch (error) {
      debugPrint('Error inserting device: $error');
    }
  }

  /// Almacena datos del dispositivo en caché local usando SharedPreferences.
  Future<void> setDeviceCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DEVICE_KEY, jsonEncode(data));
    } catch (error) {
      debugPrint('Fn>setDeviceCached>error: $error');
    }
  }

  /// Obtiene los datos del dispositivo almacenados en caché local.
  Future<Map<String, dynamic>?> getDeviceCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(DEVICE_KEY);
      if (cachedData != null) {
        return jsonDecode(cachedData) as Map<String, dynamic>;
      }
      return null;
    } catch (error) {
      debugPrint('Fn>getDeviceCached>error: $error');
      return null;
    }
  }

  /// Carga el ID del dispositivo desde la caché.
  Future<void> loadDeviceFromCache() async {
    final cache = await getDeviceCache();
    if (cache != null && cache.containsKey('id')) {
      this.deviceId = cache['id'];
      debugPrint('Dispositivo cargado desde caché con ID: ${this.deviceId}');
    } else {
      debugPrint('No se encontró información del dispositivo en caché.');
    }
  }

  /// Registra la relación entre el usuario y el dispositivo basado en `userId` y `deviceRealName`.
  /*Future<void> registerUserDevice(String userId, String realName) async {
    _deviceId = await getDeviceId(realName);

    if (_deviceId != 0) {
      final response = await supabase.from('device').insert({'mac_address': macAddress}).select('id').single();

      if (response.error != null) {
        debugPrint('Error inserting device: ${response.error!.message}');
        return;
      }

      final deviceId = response.data['id'];
      this.deviceId = deviceId; // Actualizamos el ID local
      await supabase.from('user_device').insert({'user_id': userId, 'device_id': deviceId, 'role': 'Admin'});
    } else {
      this.deviceId = id; // Actualizamos el ID local
      await supabase.from('user_device').upsert({'user_id': userId, 'device_id': id});
    }
  }*/

  /// Obtiene la relación entre el usuario y el dispositivo.
  /*Future<String?> relationUserDevice(String userId, String realName) async {
    final id = await getDeviceId(realName);

    if (id == 0) {
      return 'new'; // No existe el dispositivo
    } else {
      try {
        final response =
            await supabase.from('user_device').select('role').match({'device_id': id, 'user_id': userId}).single();
        return response['role'];
      } catch (e) {
        return null;
      }

      if (response.error != null) {
        debugPrint('Error fetching user-device relation: ${response.error!.message}');
        return null;
      }

      return response['role'] ?? null;
    }
  }*/

  /// Actualiza el estado `allow` de un dispositivo.
  Future<bool?> updateAllowDevice(int id, bool config) async {
    final response = await supabase.from('device').update({'allow': config}).eq('id', id).select('allow').single();

    if (response.error != null) {
      debugPrint('Error updating device allow: ${response.error!.message}');
      return null;
    }

    return response.data != null ? response.data['allow'] : null;
  }

  /// Obtiene el estado `allow` de un dispositivo.
  Future<bool?> getAllowDevice(int id) async {
    final response = await supabase.from('device').select('allow').eq('id', id).single();

    if (response.error != null) {
      debugPrint('Error fetching device allow: ${response.error!.message}');
      return null;
    }

    return response.data != null ? response.data['allow'] : null;
  }
}
