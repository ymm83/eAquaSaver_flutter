import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MySecureStorage extends LocalStorage {

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return storage.read(
        key: supabasePersistSessionKey,
        //iOptions: const IOSOptions( accountName: keychainService, groupId: keychainSharingGroup)
        );
  }

  @override
  Future<bool> hasAccessToken() async {
    return storage.containsKey(
        key: supabasePersistSessionKey,
        //iOptions: const IOSOptions(  accountName: keychainService, groupId: keychainSharingGroup)
        );
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    return storage.write(
        key: supabasePersistSessionKey,
        value: persistSessionString,
        //iOptions: const IOSOptions( accountName: keychainService, groupId: keychainSharingGroup)
        );
  }

  @override
  Future<void> removePersistedSession() async {
    return storage.delete(
        key: supabasePersistSessionKey,
        //iOptions: const IOSOptions( accountName: keychainService, groupId: keychainSharingGroup)
        );
  }
}