import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider extends StatelessWidget {
  final Widget child;
  final SupabaseClient client;
  final SupabaseQuerySchema eASclient;

  const SupabaseProvider({required this.client, required this.child, required this.eASclient, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: client),
        Provider<SupabaseQuerySchema>.value(value: eASclient),
      ],
      child: child,
    );
  }

  // SupabaseClient
  static SupabaseClient getClient(BuildContext context) {
    return Provider.of<SupabaseClient>(context, listen: false);
  }

  // SupabaseQuerySchema "eaquasaver"
  static SupabaseQuerySchema getEASClient(BuildContext context) {
    return Provider.of<SupabaseQuerySchema>(context, listen: false);
  }
}
