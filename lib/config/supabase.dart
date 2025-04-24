import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/secure_storage.dart';

class SupabaseConfig {
  static Future<void> initializeSupabase() async {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!, 
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
      storageOptions: const StorageClientOptions(
        retryAttempts: 5,
      ),
    );
  }

  static SupabaseClient getClient() {
    return Supabase.instance.client;
  }

  static SupabaseQuerySchema getEasClient() {
    return Supabase.instance.client.schema('eaquasaver');
  }
}

