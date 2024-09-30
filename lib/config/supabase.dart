import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/secure_storage.dart';

const String dbUrl = 'https://ierapckvmomyjujxrmss.supabase.co';
const String dbAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllcmFwY2t2bW9teWp1anhybXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDE5NjY4OTYsImV4cCI6MjAxNzU0Mjg5Nn0.NTL1AJL27lZr9oLsBrvhRBz-V5rv3iN3VD2VnvaRAmQ';

class SupabaseConfig {
  static Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: dbUrl,
      anonKey: dbAnonKey,
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
