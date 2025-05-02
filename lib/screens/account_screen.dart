import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/supabase_provider.dart';
import '../utils/snackbar_helper.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  var _loading = true;
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  late StreamSubscription authSubscription;

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabaseEAS.from('user_profile').select().eq('id', userId).single();
      _firstnameController.text = (data['firstname'] ?? '') as String;
      _lastnameController.text = (data['lastname'] ?? '') as String;
      await _storage.write(key: supabase.auth.currentUser!.id, value: json.encode(data));
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: Text('errors.unexpected'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    final firtsname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final userId = supabase.auth.currentUser!.id;
    final updates = {
      'firstname': firtsname,
      'lastname': lastname,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabaseEAS.from('user_profile').update(updates).eq('id', userId);
      if (mounted) {
        showSnackBar('success.profile_updated'.tr(), theme: 'success');
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('errors.unexpected'.tr(), theme: 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    _getProfile();
    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        //Navigator.of(context).pushReplacementNamed('/login');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                TextFormField(
                  controller: _firstnameController,
                  decoration: InputDecoration(labelText: 'user.form.first_name'.tr()),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _lastnameController,
                  decoration: InputDecoration(labelText: 'user.form.last_name'.tr()),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _updateProfile,
                  child: Text(_loading ? 'ui.btn.saving'.tr() : 'ui.btn.update'.tr()),
                ),
              ],
            ),
    );
  }
}
