import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider extends InheritedWidget {
  final SupabaseClient supabaseClient;

  const SupabaseProvider({
    super.key,
    required this.supabaseClient,
    required super.child,
  });

  static SupabaseProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SupabaseProvider>();
  }

  @override
  bool updateShouldNotify(SupabaseProvider oldWidget) {
    return supabaseClient != oldWidget.supabaseClient;
  }
}
