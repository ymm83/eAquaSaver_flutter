import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String dbUrl = 'https://ierapckvmomyjujxrmss.supabase.co';
String dbKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllcmFwY2t2bW9teWp1anhybXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDE5NjY4OTYsImV4cCI6MjAxNzU0Mjg5Nn0.NTL1AJL27lZr9oLsBrvhRBz-V5rv3iN3VD2VnvaRAmQ';
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: dbUrl,
    anonKey: dbKey,
    authOptions: AuthOptions(
      storage: FlutterSecureStorage()
    ),
  );
}

SupabaseClient supabase = Supabase.instance.client;

SupabaseClient supabaseEAS = Supabase.instance.instance('eaquasaver');