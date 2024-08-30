import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_login.dart';
import '../main.dart';
import 'dart:convert';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _loading = true;
  late Map userData;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final StreamSubscription<AuthState> authSubscription;

  Future<Map> _getOnlineProfile() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final userId = supabase.auth.currentUser!.id;
      userData = await supabaseEAS.from('user_profile').select().eq('id', userId).single();
      await _storage.write(key: 'myprofile', value: json.encode(userData));
      return userData;
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
      userData = {};
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  /// Called once a user id is received within `onAuthenticated()`
  Future<Map> _getLocalProfile() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final data = await _storage.read(key: 'myprofile');
      debugPrint('---- Reading Secure Storage');
      //data = jsonDecode(onValue!);
      userData = json.decode(data!);
      //userData['firstname'] = 'Loba';
      debugPrint('---- ${userData.toString()}');
      return userData;
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  Future<void> _signOut() async {
    setState(() {
      _loading = true;
    });
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      setState(() {
        _loading = true;
      });
    }
  }

  @override
  void initState() {
    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage())).then((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
      }
    });
    _getLocalProfile().then((localValue) {
      userData = localValue;
      if (userData.isEmpty) {
        // get online profile
        _getOnlineProfile().then((onlineValue) {
          userData = onlineValue;
          setState(() {
            _loading = false;
          });
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blue, width: 1.5), 
                      borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade100,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade300,
                      child: const Text('YM'),
                    ),
                    title: Text(userData.isNotEmpty ? '${userData['firstname']} ${userData['lastname']}' : ''),
                    subtitle: Text('${supabase.auth.currentUser!.email}'),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                    onPressed: _signOut, label: const Text('Sign Out'), icon: const Icon(Icons.exit_to_app_outlined)),
              ],
            ),
    );
  }
}
