import 'package:supabase_flutter/supabase_flutter.dart';

// URL y claves de Supabase
const String dbUrl = 'https://ierapckvmomyjujxrmss.supabase.co';
const String dbKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllcmFwY2t2bW9teWp1anhybXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDE5NjY4OTYsImV4cCI6MjAxNzU0Mjg5Nn0.NTL1AJL27lZr9oLsBrvhRBz-V5rv3iN3VD2VnvaRAmQ';

// Instancia global de Supabase para el esquema 'public'
SupabaseClient? supabase;

// Instancia global de Supabase para el esquema 'eaquasaver'
SupabaseClient? supabaseEAS;

Future<void> initSupabase() async {
  // Inicializa la primera instancia de Supabase para el esquema 'public'
  supabase = SupabaseClient(
    dbUrl,
    dbKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
}

Future<void> initSupabaseEAS() async {
  // Inicializa la segunda instancia de Supabase para el esquema 'eaquasaver'
  supabaseEAS = SupabaseClient(
    dbUrl,
    dbKey,
    postgrestOptions: const PostgrestClientOptions(
      schema: 'eaquasaver',
    ),
  );
}
